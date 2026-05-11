import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../theme/app_colors.dart';
import 'video_editor_route.dart';

/// Backend's `CHAT_LIMITS.CAPTION_MAX` — keep in sync.
const int _captionMax = 500;

/// Backend's `CHAT_LIMITS.VIDEO_DURATION_MAX_SECONDS`. The preview enforces
/// it client-side so the user gets immediate feedback (and a chance to trim
/// via the editor) instead of an upload error after the fact.
const int _defaultMaxVideoDurationSeconds = 600;

/// Result returned by [MediaPreviewScreen]. Null if the user cancelled.
class MediaPreviewResult {
  /// What the user typed in the caption field (already trimmed).
  final String caption;

  /// When non-null, the user opened the image editor and saved changes —
  /// these bytes are the edited image (JPEG-encoded by `pro_image_editor`).
  /// Caller should upload these instead of the original.
  final Uint8List? editedImageBytes;

  /// When non-null, the user opened the video editor and saved changes —
  /// this path is the rendered video file (mp4) on disk.
  /// Caller should upload this file instead of the original.
  final String? editedVideoPath;

  /// Probed video metadata + thumbnail. Populated for video previews —
  /// sourced from the [VideoPlayerController] that the preview screen
  /// already needs to init for playback, so the caller doesn't have to
  /// re-probe (which would double the controller-init cost).
  final int? videoWidth;
  final int? videoHeight;
  final int? videoDurationSeconds;
  final Uint8List? videoThumbnailBytes;

  const MediaPreviewResult({
    required this.caption,
    this.editedImageBytes,
    this.editedVideoPath,
    this.videoWidth,
    this.videoHeight,
    this.videoDurationSeconds,
    this.videoThumbnailBytes,
  });

  bool get wasEdited =>
      editedImageBytes != null || editedVideoPath != null;
}

/// Push the full-screen preview as a route — returns the result on send,
/// or null when the user backs out.
Future<MediaPreviewResult?> showMediaPreview({
  required BuildContext context,
  Uint8List? imageBytes,
  String? videoFilePath,
  String? videoUrl,
  int maxVideoDurationSeconds = _defaultMaxVideoDurationSeconds,
}) {
  assert(
    imageBytes != null || videoFilePath != null || videoUrl != null,
    'Need an image, video file, or video URL to preview',
  );
  return Navigator.of(context).push<MediaPreviewResult>(
    PageRouteBuilder(
      opaque: true,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, anim, _) => FadeTransition(
        opacity: anim,
        child: MediaPreviewScreen(
          imageBytes: imageBytes,
          videoFilePath: videoFilePath,
          videoUrl: videoUrl,
          maxVideoDurationSeconds: maxVideoDurationSeconds,
        ),
      ),
    ),
  );
}

class MediaPreviewScreen extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? videoFilePath;
  final String? videoUrl;
  final int maxVideoDurationSeconds;

  const MediaPreviewScreen({
    super.key,
    this.imageBytes,
    this.videoFilePath,
    this.videoUrl,
    this.maxVideoDurationSeconds = _defaultMaxVideoDurationSeconds,
  });

  bool get isVideo => videoFilePath != null || videoUrl != null;

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  final TextEditingController _caption = TextEditingController();
  final FocusNode _captionFocus = FocusNode();

  /// Live image bytes — starts as the original; replaced when the user
  /// returns from the image editor.
  Uint8List? _imageBytes;

  /// Live video path — starts as the original; replaced when the user
  /// returns from the video editor with a re-rendered file.
  String? _activeVideoPath;
  String? _editedVideoPath;

  // ── Video state ──
  VideoPlayerController? _video;
  bool _videoReady = false;
  bool _videoFailed = false;

  /// True once the parallel thumbnail-generation future has resolved
  /// (success OR failure). Send is gated on this so we never enqueue a
  /// video with empty thumbnail bytes — which the upload pipeline rejects
  /// downstream and surfaces as a "failed to send".
  bool _thumbnailResolved = false;

  /// Probed metadata, populated when the controller finishes initializing.
  int? _videoWidth;
  int? _videoHeight;
  int? _videoDurationSeconds;
  Uint8List? _videoThumbnailBytes;

  /// True when the controller reports a duration exceeding
  /// [widget.maxVideoDurationSeconds]. Disables Send and shows a banner —
  /// the user can trim via the edit button to clear it.
  bool _videoTooLong = false;
  int? _actualDurationSeconds;

  @override
  void initState() {
    super.initState();
    _imageBytes = widget.imageBytes;
    _activeVideoPath = widget.videoFilePath;
    _caption.addListener(() => setState(() {}));
    if (widget.isVideo) _initVideo();
  }

  @override
  void dispose() {
    _caption.dispose();
    _captionFocus.dispose();
    _video?.dispose();
    super.dispose();
  }

  Future<void> _initVideo() async {
    final activePath = _activeVideoPath;
    final controller = activePath != null
        ? VideoPlayerController.file(File(activePath))
        : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
    _video = controller;

    // Generate the still-frame thumbnail in parallel with controller init —
    // both touch the same file but are independent operations, so running
    // them sequentially (as the caller used to) just doubles the wall time.
    final thumbFuture = activePath != null
        ? _generateThumbnail(activePath)
        : Future<Uint8List?>.value(null);

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final size = controller.value.size;
      final duration = controller.value.duration;
      final actualSeconds = duration.inSeconds;
      final tooLong = actualSeconds > widget.maxVideoDurationSeconds;

      controller.addListener(_onVideoTick);
      await controller.setLooping(true);
      // Play with audio. The earlier mute-toggle UI was removed, so this
      // is the only way to hear sound before sending.
      await controller.setVolume(1);
      if (!tooLong) await controller.play();

      setState(() {
        _videoReady = true;
        _videoWidth = size.width.round();
        _videoHeight = size.height.round();
        _videoDurationSeconds =
            actualSeconds.clamp(1, widget.maxVideoDurationSeconds);
        _actualDurationSeconds = actualSeconds;
        _videoTooLong = tooLong;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _videoFailed = true);
    }

    final thumb = await thumbFuture;
    if (!mounted) return;
    setState(() {
      if (thumb != null) _videoThumbnailBytes = thumb;
      _thumbnailResolved = true;
    });
  }

  Future<Uint8List?> _generateThumbnail(String path) async {
    if (kIsWeb) return null;
    try {
      return await VideoThumbnail.thumbnailData(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 75,
      );
    } catch (_) {
      return null;
    }
  }

  void _onVideoTick() {
    // Rebuild on play/pause and every position tick so the progress bar
    // and play-overlay icon stay in sync.
    if (mounted) setState(() {});
  }

  bool get _canSend {
    if (widget.isVideo) {
      // Need probed metadata + a resolved thumbnail before sending.
      // Server requires width/height/duration; thumbnail upload rejects
      // empty bytes, which would otherwise surface as "failed to send"
      // when the user races past a still-running thumbnail generation.
      return _videoReady &&
          _thumbnailResolved &&
          !_videoTooLong &&
          !_videoFailed;
    }
    return true;
  }

  void _send() {
    if (!_canSend) return;
    Navigator.of(context).pop(
      MediaPreviewResult(
        caption: _caption.text.trim(),
        editedImageBytes:
            (widget.isVideo || _imageBytes == widget.imageBytes)
                ? null
                : _imageBytes,
        editedVideoPath: _editedVideoPath,
        videoWidth: _videoWidth,
        videoHeight: _videoHeight,
        videoDurationSeconds: _videoDurationSeconds,
        videoThumbnailBytes: _videoThumbnailBytes,
      ),
    );
  }

  void _cancel() => Navigator.of(context).pop();

  Future<void> _openEditor() async {
    if (widget.isVideo) {
      await _openVideoEditor();
    } else {
      await _openImageEditor();
    }
  }

  Future<void> _openImageEditor() async {
    final src = _imageBytes;
    if (src == null) return;
    final navigator = Navigator.of(context);

    final edited = await navigator.push<Uint8List>(
      MaterialPageRoute<Uint8List>(
        builder: (editorContext) => ProImageEditor.memory(
          src,
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (bytes) async {
              Navigator.of(editorContext).pop(bytes);
            },
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (edited != null) {
      setState(() => _imageBytes = edited);
    }
  }

  /// Opens `pro_video_editor` with the active video file. On render
  /// success, swaps the preview's `VideoPlayerController` to the new
  /// edited file so the user sees the result before sending.
  Future<void> _openVideoEditor() async {
    final activePath = _activeVideoPath;
    if (activePath == null) return; // web fallback not supported

    // Capture the editor opener's BuildContext-bound work BEFORE awaiting
    // anything so the analyzer's "BuildContext across async gap" check
    // is satisfied.
    final editorFuture = openVideoEditor(context, videoPath: activePath);

    // Pause + tear down the preview's player so the editor's own
    // controller can take over without conflicting on the file handle.
    final wasPlaying = _video?.value.isPlaying ?? false;
    await _video?.pause();

    final newPath = await editorFuture;
    if (!mounted) return;

    if (newPath == null || newPath == activePath) {
      // User cancelled or no changes — resume original player.
      if (wasPlaying) await _video?.play();
      return;
    }

    // Swap to the edited file. Re-init re-probes metadata + regenerates
    // the thumbnail, so a too-long video that was just trimmed clears the
    // banner automatically. _thumbnailResolved flips back to false so
    // Send is disabled until the new thumbnail is ready (otherwise the
    // user could send with empty thumbnail bytes and hit "failed to send"
    // downstream).
    final oldVideo = _video;
    setState(() {
      _videoReady = false;
      _videoFailed = false;
      _videoTooLong = false;
      _videoThumbnailBytes = null;
      _thumbnailResolved = false;
      _video = null;
      _activeVideoPath = newPath;
      _editedVideoPath = newPath;
    });
    await oldVideo?.dispose();
    await _initVideo();
  }

  void _toggleVideo() {
    final c = _video;
    if (c == null || !c.value.isInitialized) return;
    if (c.value.isPlaying) {
      c.pause();
    } else {
      c.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ── Media (fills the whole screen behind the controls) ──
            Positioned.fill(child: _buildMedia()),

            // ── Top bar ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  child: Row(
                    children: [
                      _circleIconButton(
                        Icons.close_rounded,
                        onTap: _cancel,
                      ),
                      const Spacer(),
                      // Edit affordance: image editor for photos, video
                      // editor (trim/crop/text/paint) for videos. Hidden
                      // for the web video case since pro_video_editor
                      // needs a local file path.
                      if (!widget.isVideo || _activeVideoPath != null)
                        _circleIconButton(
                          Icons.edit_outlined,
                          onTap: _openEditor,
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom: caption input + send button ──
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_videoTooLong) _buildTooLongBanner(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(child: _buildCaptionField()),
                          const SizedBox(width: 10),
                          _buildSendButton(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Pieces ──────────────────────────────────

  Widget _buildMedia() {
    if (widget.isVideo) return _buildVideo();
    if (_imageBytes != null) {
      return InteractiveViewer(
        minScale: 1.0,
        maxScale: 5.0,
        child: Center(
          child: Image.memory(
            _imageBytes!,
            fit: BoxFit.contain,
            // Force a rebuild when bytes change (after editor returns).
            gaplessPlayback: true,
          ),
        ),
      );
    }
    return const ColoredBox(color: Colors.black);
  }

  Widget _buildVideo() {
    if (_videoFailed) {
      return const Center(
        child: Icon(Icons.broken_image_rounded,
            color: Colors.white54, size: 60),
      );
    }
    final controller = _video;
    if (controller == null || !_videoReady) {
      // Poster (once thumbnail is ready) + spinner while initializing —
      // feels instant since the route opened without waiting on anything.
      return Stack(
        alignment: Alignment.center,
        children: [
          if (_videoThumbnailBytes != null)
            Positioned.fill(
              child: Image.memory(
                _videoThumbnailBytes!,
                fit: BoxFit.contain,
              ),
            ),
          const Positioned.fill(
              child: ColoredBox(color: Color(0x55000000))),
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      );
    }
    final isPlaying = controller.value.isPlaying;
    return GestureDetector(
      onTap: _toggleVideo,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          ),
          // Centered play button when paused.
          if (!isPlaying)
            const Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x66000000),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 48),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTooLongBanner() {
    final actual = _actualDurationSeconds ?? 0;
    final maxSec = widget.maxVideoDurationSeconds;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Video is ${actual}s — max ${maxSec}s. Trim with the edit button to send.',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton(IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildCaptionField() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 120),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextField(
        controller: _caption,
        focusNode: _captionFocus,
        maxLines: null,
        maxLength: _captionMax,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: [
          LengthLimitingTextInputFormatter(_captionMax),
        ],
        cursorColor: Colors.white,
        style: GoogleFonts.inter(fontSize: 15, color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Add a caption…',
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.white60,
          ),
          // Opt out of the global InputDecorationTheme defaults — that
          // theme sets `filled: true` with the light-gray app fill
          // color, which would paint a white box over our dark
          // translucent pill and make white-on-white text invisible.
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          counterText: '',
          isCollapsed: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        ),
      ),
    );
  }

  /// True while we're still preparing the video for send (controller
  /// initializing, thumbnail generating). Distinct from a hard "can't send"
  /// state like _videoFailed/_videoTooLong — those keep the static disabled
  /// button so the user understands something's wrong, while in-flight
  /// preparation shows a spinner so it reads as "almost ready".
  bool get _isPreparingVideo {
    if (!widget.isVideo) return false;
    if (_videoFailed || _videoTooLong) return false;
    return !_canSend;
  }

  Widget _buildSendButton() {
    if (_isPreparingVideo) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    }

    final enabled = _canSend;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? _send : null,
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.send_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
