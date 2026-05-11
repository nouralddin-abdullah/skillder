import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageByteFormat;

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:pro_video_editor/pro_video_editor.dart' as pve;
import 'package:video_player/video_player.dart';

/// Opens the full video editor on top of the current route. On done, the
/// edited video is rendered to a temp `.mp4` and the file path is
/// returned. On cancel returns `null`.
///
/// Trim, crop, rotate, paint, text, emoji, and sticker overlays are
/// supported. Audio replacement and filters are intentionally disabled
/// for chat use.
Future<String?> openVideoEditor(
  BuildContext context, {
  required String videoPath,
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => _VideoEditorRoute(videoPath: videoPath),
    ),
  );
}

class _VideoEditorRoute extends StatefulWidget {
  final String videoPath;
  const _VideoEditorRoute({required this.videoPath});

  @override
  State<_VideoEditorRoute> createState() => _VideoEditorRouteState();
}

class _VideoEditorRouteState extends State<_VideoEditorRoute> {
  final _editorKey = GlobalKey<ProImageEditorState>();
  final _taskId = DateTime.now().microsecondsSinceEpoch.toString();

  late final pve.EditorVideo _video;
  pve.VideoMetadata? _metadata;
  late VideoPlayerController _videoController;
  ProVideoController? _proVideoController;
  List<ImageProvider>? _thumbnails;

  /// Path of the most recent render. Returned to the caller on close.
  String? _outputPath;

  bool _initFailed = false;

  /// Active trim window. The player auto-seeks back to [start] when its
  /// position crosses [end] so the trimmed segment loops in preview.
  TrimDurationSpan? _durationSpan;

  /// Re-entrancy guard for [_seekToPosition] — `setLooping(false)` plus
  /// `addListener` can fire multiple times while a seek is in flight.
  bool _isSeeking = false;
  TrimDurationSpan? _pendingSeek;

  static const int _thumbnailCount = 7;

  @override
  void initState() {
    super.initState();
    _video = pve.EditorVideo.file(File(widget.videoPath));
    _bootstrap();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      // Probe metadata (resolution, duration, file size).
      final metadata = await pve.ProVideoEditor.instance.getMetadata(_video);

      // Boot up the underlying VideoPlayer.
      _videoController =
          VideoPlayerController.file(File(widget.videoPath));
      await _videoController.initialize();
      await _videoController.setLooping(false);
      // Editor starts UNMUTED so the user hears the video by default.
      // The mute toggle is now a real output-affecting edit (it sets
      // `enableAudio: false` on the rendered file), so starting muted
      // would silently strip audio from sent videos.
      await _videoController.setVolume(1);

      // Set up the ProVideoController that bridges to the image editor.
      _proVideoController = ProVideoController(
        videoPlayer: VideoPlayer(_videoController),
        initialResolution: metadata.resolution,
        videoDuration: metadata.duration,
        fileSize: metadata.fileSize,
      );

      // Sync video position back into the trim/clips UI.
      _videoController.addListener(_onVideoTick);

      if (!mounted) {
        await _videoController.dispose();
        return;
      }
      setState(() => _metadata = metadata);

      // Generate thumbnails for the trim strip in the background.
      unawaited(_generateThumbnails());
    } catch (_) {
      if (!mounted) return;
      setState(() => _initFailed = true);
    }
  }

  void _onVideoTick() {
    final controller = _proVideoController;
    if (controller == null) return;
    final position = _videoController.value.position;
    controller.setPlayTime(position);

    // Loop back to the trim start when the player crosses the trim end
    // (or the video end when no trim is set). Without this the editor's
    // play button would play once and stop dead at the end.
    final span = _durationSpan;
    final totalDuration = _metadata?.duration ?? Duration.zero;
    if (span != null && position >= span.end) {
      _seekToPosition(span);
    } else if (span == null &&
        totalDuration > Duration.zero &&
        position >= totalDuration) {
      _seekToPosition(
        TrimDurationSpan(start: Duration.zero, end: totalDuration),
      );
    }
  }

  Future<void> _seekToPosition(TrimDurationSpan span) async {
    _durationSpan = span;
    if (_isSeeking) {
      _pendingSeek = span;
      return;
    }
    _isSeeking = true;

    _proVideoController?.pause();
    _proVideoController?.setPlayTime(span.start);
    await _videoController.pause();
    await _videoController.seekTo(span.start);

    _isSeeking = false;
    final next = _pendingSeek;
    if (next != null) {
      _pendingSeek = null;
      await _seekToPosition(next);
    }
  }

  Future<void> _generateThumbnails() async {
    final metadata = _metadata;
    if (metadata == null) return;
    final width = MediaQuery.of(context).size.width /
        _thumbnailCount *
        MediaQuery.of(context).devicePixelRatio;
    final segmentMs = metadata.duration.inMilliseconds / _thumbnailCount;

    try {
      final list = await pve.ProVideoEditor.instance.getThumbnails(
        pve.ThumbnailConfigs(
          video: _video,
          outputSize: Size.square(width),
          boxFit: pve.ThumbnailBoxFit.cover,
          timestamps: List.generate(_thumbnailCount, (i) {
            final mid = (i + 0.5) * segmentMs;
            return Duration(milliseconds: mid.round());
          }),
          outputFormat: pve.ThumbnailFormat.jpeg,
        ),
      );
      final thumbnails = list.map(MemoryImage.new).toList();
      if (!mounted) return;
      setState(() => _thumbnails = thumbnails);
      _proVideoController?.thumbnails = thumbnails;
    } catch (_) {
      // Thumbnails are nice-to-have; the trim strip just shows a
      // placeholder bar without them.
    }
  }

  // ─────────────────────────── Render ──────────────────────────────────

  Future<void> _renderVideo(CompleteParameters parameters) async {
    final dir = await getTemporaryDirectory();
    final outPath = p.join(dir.path, 'edited_video_$_taskId.mp4');

    final exportModel = pve.VideoRenderData(
      id: _taskId,
      videoSegments: [pve.VideoSegment(video: _video)],
      outputFormat: pve.VideoOutputFormat.mp4,
      enableAudio: _proVideoController?.isAudioEnabled ?? true,
      imageLayers: parameters.layers.isNotEmpty
          ? [
              pve.ImageLayer(
                image: pve.EditorLayerImage.memory(parameters.image),
              ),
            ]
          : null,
      blur: parameters.blur,
      colorFilters: parameters.colorFilters
          .map((m) => pve.ColorFilter(matrix: m))
          .toList(),
      startTime: parameters.startTime,
      endTime: parameters.endTime,
      transform: parameters.isTransformed
          ? pve.ExportTransform(
              width: parameters.cropWidth,
              height: parameters.cropHeight,
              rotateTurns: parameters.rotateTurns,
              x: parameters.cropX,
              y: parameters.cropY,
              flipX: parameters.flipX,
              flipY: parameters.flipY,
            )
          : null,
    );

    try {
      _outputPath = await pve.ProVideoEditor.instance
          .renderVideoToFile(outPath, exportModel);
    } on pve.RenderCanceledException {
      _outputPath = null;
    }
  }

  void _handleCloseEditor(EditorMode mode) {
    if (mode != EditorMode.main) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, _outputPath);
  }

  // ─────────────────────────── UI ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_initFailed) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        body: const Center(
          child: Text(
            'Could not load video for editing',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    if (_proVideoController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return ProImageEditor.video(
      _proVideoController!,
      key: _editorKey,
      callbacks: ProImageEditorCallbacks(
        onCompleteWithParameters: _renderVideo,
        onCloseEditor: _handleCloseEditor,
        // Bridge the editor's play/pause/mute/trim UI back to the
        // underlying VideoPlayerController. Without these, the editor's
        // play button just flips an internal flag but never actually
        // tells the player to start.
        videoEditorCallbacks: VideoEditorCallbacks(
          onPlay: () => _videoController.play(),
          onPause: () => _videoController.pause(),
          onMuteToggle: (isMuted) =>
              _videoController.setVolume(isMuted ? 0.0 : 1.0),
          onTrimSpanUpdate: (_) {
            // While the user is dragging the trim handles, pause so the
            // playhead doesn't fight the scrubber.
            if (_videoController.value.isPlaying) {
              _proVideoController?.pause();
            }
          },
          onTrimSpanEnd: _seekToPosition,
        ),
      ),
      configs: ProImageEditorConfigs(
        // Tools that make sense for a chat video — skip audio replacement
        // (no track library) and filters (per product call).
        mainEditor: const MainEditorConfigs(
          tools: [
            SubEditorMode.videoClips,
            SubEditorMode.paint,
            SubEditorMode.text,
            SubEditorMode.cropRotate,
            SubEditorMode.emoji,
            SubEditorMode.sticker,
          ],
        ),
        paintEditor: const PaintEditorConfigs(
          tools: [
            PaintMode.freeStyle,
            PaintMode.arrow,
            PaintMode.line,
            PaintMode.rect,
            PaintMode.circle,
            PaintMode.dashLine,
            PaintMode.eraser,
          ],
        ),
        clipsEditor: ClipsEditorConfigs(
          clips: [
            VideoClip(
              id: 'main',
              title: 'Video',
              duration: _metadata?.duration ?? Duration.zero,
              clip: EditorVideoClip.autoSource(file: File(widget.videoPath)),
              thumbnails: _thumbnails,
            ),
          ],
        ),
        videoEditor: const VideoEditorConfigs(
          // Start unmuted — the mute toggle is now a real edit that
          // strips audio from the rendered output, so a muted default
          // would surprise users into sending silent videos.
          initialMuted: false,
          initialPlay: false,
          isAudioSupported: true,
          minTrimDuration: Duration(seconds: 1),
        ),
        imageGeneration: const ImageGenerationConfigs(
          captureImageByteFormat: ImageByteFormat.rawStraightRgba,
        ),
      ),
    );
  }
}
