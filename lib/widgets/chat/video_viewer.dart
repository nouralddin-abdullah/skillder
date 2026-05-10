import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../models/chat_models.dart';
import '../../theme/app_colors.dart';

/// Full-screen video player with WhatsApp/Telegram-style controls. Plays
/// the video at [MessageEntity.mediaUrl] (server URL — local-only sends
/// without an uploaded mediaUrl render a placeholder).
class VideoViewer extends StatefulWidget {
  final MessageEntity message;
  const VideoViewer({super.key, required this.message});

  @override
  State<VideoViewer> createState() => _VideoViewerState();
}

class _VideoViewerState extends State<VideoViewer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _initFailed = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final url = widget.message.mediaUrl;
    if (url == null) {
      setState(() => _initFailed = true);
      return;
    }
    final video = VideoPlayerController.networkUrl(Uri.parse(url));
    _videoController = video;
    try {
      await video.initialize();
    } catch (_) {
      if (!mounted) return;
      setState(() => _initFailed = true);
      return;
    }
    if (!mounted) {
      await video.dispose();
      return;
    }
    final aspect = (widget.message.mediaWidth != null &&
            widget.message.mediaHeight != null &&
            widget.message.mediaHeight! > 0)
        ? widget.message.mediaWidth! / widget.message.mediaHeight!
        : video.value.aspectRatio;

    setState(() {
      _chewieController = ChewieController(
        videoPlayerController: video,
        autoPlay: true,
        looping: false,
        allowFullScreen: false, // we ARE full-screen
        allowMuting: true,
        showControls: true,
        aspectRatio: aspect,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        placeholder: const ColoredBox(color: Colors.black),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(child: _buildBody()),
            // Top bar — close button on the left.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
            // Caption (if any) at the bottom — same gradient overlay as
            // the image viewer for visual consistency.
            if ((widget.message.mediaCaption?.trim() ?? '').isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                      20,
                      40,
                      20,
                      MediaQuery.of(context).padding.bottom + 56,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                    child: Text(
                      widget.message.mediaCaption!.trim(),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_initFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white54, size: 60),
            const SizedBox(height: 12),
            Text(
              'Could not load video',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      );
    }
    final controller = _chewieController;
    if (controller == null) {
      return const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.primary),
            backgroundColor: Colors.white24,
          ),
        ),
      );
    }
    return Center(child: Chewie(controller: controller));
  }
}
