import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../theme/app_colors.dart';

/// Backend's `CHAT_LIMITS.CAPTION_MAX` — keep in sync.
const int _captionMax = 500;

/// Single sheet for both photo and video captions.
///
/// - Pass [imageBytes] for image previews (existing behavior).
/// - Pass [videoFilePath] (native) or [videoUrl] (web) for video previews.
///   The sheet builds a muted, looping inline player; tap toggles
///   play/pause; tap-and-hold the audio icon (top-right) toggles mute.
/// - [posterBytes] is an optional still frame used as a placeholder
///   while the video is loading.
///
/// Resolves to:
///   - the caption string (possibly empty) when the user taps Send
///   - `null` when the user cancels
Future<String?> showMediaCaptionSheet({
  required BuildContext context,
  Uint8List? imageBytes,
  String? videoFilePath,
  String? videoUrl,
  Uint8List? posterBytes,
}) {
  assert(
    imageBytes != null || videoFilePath != null || videoUrl != null,
    'Need an image, video file, or video URL to preview',
  );
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.85),
    isDismissible: true,
    enableDrag: true,
    builder: (_) => _MediaCaptionSheet(
      imageBytes: imageBytes,
      videoFilePath: videoFilePath,
      videoUrl: videoUrl,
      posterBytes: posterBytes,
    ),
  );
}

/// Backwards-compat alias — old callers can keep using the image-only API.
Future<String?> showImageCaptionSheet({
  required BuildContext context,
  required Uint8List imageBytes,
}) =>
    showMediaCaptionSheet(context: context, imageBytes: imageBytes);

class _MediaCaptionSheet extends StatefulWidget {
  final Uint8List? imageBytes;
  final String? videoFilePath;
  final String? videoUrl;
  final Uint8List? posterBytes;

  const _MediaCaptionSheet({
    this.imageBytes,
    this.videoFilePath,
    this.videoUrl,
    this.posterBytes,
  });

  bool get isVideo => videoFilePath != null || videoUrl != null;

  @override
  State<_MediaCaptionSheet> createState() => _MediaCaptionSheetState();
}

class _MediaCaptionSheetState extends State<_MediaCaptionSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  VideoPlayerController? _videoController;
  bool _videoReady = false;
  bool _videoFailed = false;
  bool _videoMuted = true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    if (widget.isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    final controller = widget.videoFilePath != null
        ? VideoPlayerController.file(File(widget.videoFilePath!))
        : VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl!));
    _videoController = controller;
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0); // muted by default — like WhatsApp
      await controller.play();
      setState(() => _videoReady = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _videoFailed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _send() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  void _toggleVideo() {
    final c = _videoController;
    if (c == null || !c.value.isInitialized) return;
    setState(() {
      if (c.value.isPlaying) {
        c.pause();
      } else {
        c.play();
      }
    });
  }

  void _toggleMute() {
    final c = _videoController;
    if (c == null) return;
    setState(() {
      _videoMuted = !_videoMuted;
      c.setVolume(_videoMuted ? 0 : 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final maxPreviewHeight = media.size.height * 0.55;
    final isVideo = widget.isVideo;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVideo ? 'Send video' : 'Send photo',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxPreviewHeight),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: isVideo ? _videoPreview() : _imagePreview(),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Caption + send row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        decoration: BoxDecoration(
                          color: AppColors.inputFill,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: false,
                          maxLines: null,
                          maxLength: _captionMax,
                          textCapitalization: TextCapitalization.sentences,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(_captionMax),
                          ],
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Add a caption (optional)',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppColors.textHint,
                            ),
                            border: InputBorder.none,
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _send,
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(bottom: 2),
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePreview() {
    return Image.memory(
      widget.imageBytes!,
      fit: BoxFit.cover,
      width: double.infinity,
    );
  }

  Widget _videoPreview() {
    final controller = _videoController;
    if (_videoFailed) {
      return Container(
        color: Colors.black,
        height: 240,
        child: const Center(
          child: Icon(Icons.broken_image_rounded,
              color: Colors.white54, size: 48),
        ),
      );
    }
    if (controller == null || !_videoReady) {
      // Show poster + spinner while the video initializes — no blank box.
      return Stack(
        alignment: Alignment.center,
        children: [
          if (widget.posterBytes != null)
            Image.memory(
              widget.posterBytes!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 320,
            )
          else
            const SizedBox(width: double.infinity, height: 320),
          const Positioned.fill(child: ColoredBox(color: Color(0x55000000))),
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      );
    }

    final aspect = controller.value.aspectRatio;
    final isPlaying = controller.value.isPlaying;

    return GestureDetector(
      onTap: _toggleVideo,
      child: AspectRatio(
        aspectRatio: aspect,
        child: Stack(
          children: [
            Positioned.fill(child: VideoPlayer(controller)),
            // Big center play button when paused.
            if (!isPlaying)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x33000000),
                  child: Center(
                    child: Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 56),
                  ),
                ),
              ),
            // Mute toggle in the top-right.
            Positioned(
              top: 10,
              right: 10,
              child: GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _videoMuted
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            // Live progress bar at the bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppColors.primary,
                  bufferedColor: Colors.white38,
                  backgroundColor: Colors.white12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
