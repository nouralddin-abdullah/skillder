import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/chat_models.dart';
import '../../theme/app_colors.dart';

/// Full-screen image viewer with pinch-to-zoom + swipe-down-to-dismiss.
/// Used by the chat detail when the user taps an image bubble.
///
/// Supports either a server URL ([MessageEntity.mediaUrl]) or — while a
/// send is still uploading — local bytes ([MessageEntity.localImageBytes]).
class ImageViewer extends StatefulWidget {
  final MessageEntity message;
  const ImageViewer({super.key, required this.message});

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late final AnimationController _resetController;
  Animation<Matrix4>? _resetAnimation;

  /// Drag-to-dismiss state. As the user pulls down on the image at 1x
  /// zoom, [_dragOffset] grows and [_dismissProgress] fades the backdrop.
  double _dragOffset = 0;

  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        if (_resetAnimation != null) {
          _controller.value = _resetAnimation!.value;
        }
      });
    _controller.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTransformChanged);
    _resetController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _controller.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _isZoomed) setState(() => _isZoomed = zoomed);
  }

  void _resetZoom() {
    _resetAnimation = Matrix4Tween(
      begin: _controller.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _resetController,
      curve: Curves.easeOut,
    ));
    _resetController
      ..reset()
      ..forward();
  }

  void _onVerticalDragUpdate(DragUpdateDetails d) {
    if (_isZoomed) return;
    setState(() => _dragOffset += d.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails d) {
    if (_dragOffset.abs() > 120 ||
        d.primaryVelocity != null && d.primaryVelocity!.abs() > 800) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.message;
    final size = MediaQuery.of(context).size;
    final dismissProgress =
        (_dragOffset.abs() / 240).clamp(0.0, 1.0);
    final backdropOpacity = 1 - dismissProgress * 0.8;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: backdropOpacity),
      body: Stack(
        children: [
          // ── Image ──
          Positioned.fill(
            child: GestureDetector(
              onTap: _isZoomed ? _resetZoom : null,
              onDoubleTap: _isZoomed
                  ? _resetZoom
                  : () {
                      _resetAnimation = Matrix4Tween(
                        begin: _controller.value,
                        end: Matrix4.identity()
                          ..scaleByDouble(2.5, 2.5, 1, 1),
                      ).animate(CurvedAnimation(
                        parent: _resetController,
                        curve: Curves.easeOut,
                      ));
                      _resetController
                        ..reset()
                        ..forward();
                    },
              onVerticalDragUpdate: _onVerticalDragUpdate,
              onVerticalDragEnd: _onVerticalDragEnd,
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, _dragOffset),
                  child: InteractiveViewer(
                    transformationController: _controller,
                    minScale: 1.0,
                    maxScale: 5.0,
                    child: SizedBox(
                      width: size.width,
                      height: size.height,
                      child: _buildImage(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Top bar ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
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
          ),

          // ── Caption (if any) ──
          if ((media.mediaCaption?.trim() ?? '').isNotEmpty)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Text(
                  media.mediaCaption!.trim(),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.white,
                    height: 1.35,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    final bytes = widget.message.localImageBytes;
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.contain);
    }
    final url = widget.message.mediaUrl;
    if (url == null) {
      return const Center(
        child: Icon(Icons.broken_image_rounded,
            color: Colors.white54, size: 60),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final value = progress.expectedTotalBytes != null
            ? progress.cumulativeBytesLoaded /
                progress.expectedTotalBytes!
            : null;
        return Center(
          child: SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              value: value,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
              backgroundColor: Colors.white24,
            ),
          ),
        );
      },
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.broken_image_rounded,
            color: Colors.white54, size: 60),
      ),
    );
  }
}
