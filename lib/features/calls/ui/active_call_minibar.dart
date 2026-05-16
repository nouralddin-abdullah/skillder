import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../controllers/active_call_controller.dart';
import '../models/call_models.dart';
import '../models/call_session.dart';

/// Sticky top bar shown above whatever screen the user navigated to while
/// a call is active. Tap re-maximises to the full call screen.
///
/// Uses the app's primary gradient so it reads as a Skillder ongoing-call
/// affordance — distinct from any underlying app bar but tonally on-brand.
class ActiveCallMinibar extends StatefulWidget {
  final ActiveCallController controller;
  const ActiveCallMinibar({super.key, required this.controller});

  @override
  State<ActiveCallMinibar> createState() => _ActiveCallMinibarState();
}

class _ActiveCallMinibarState extends State<ActiveCallMinibar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final session = widget.controller.session;
        if (session == null) return const SizedBox.shrink();
        final tracks = widget.controller.localTracks;
        final reconnecting = session.phase == LocalCallPhase.reconnecting;

        return Material(
          color: Colors.transparent,
          child: SafeArea(
            bottom: false,
            child: GestureDetector(
              onTap: () => widget.controller.setMaximised(true),
              child: Container(
                margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  gradient: reconnecting
                      ? null
                      : AppColors.primaryGradient,
                  color: reconnecting
                      ? const Color(0xFFFEE9A4)
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.controller.toggleMic,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tracks.micEnabled
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          color: reconnecting
                              ? const Color(0xFF92400E)
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.call_rounded,
                            size: 14,
                            color: reconnecting
                                ? const Color(0xFF92400E)
                                : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${session.peerName} · ${_status(session)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: reconnecting
                                    ? const Color(0xFF92400E)
                                    : Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => widget.controller
                          .hangup(reason: CallEndReason.normal),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.call_end_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _status(CallSession session) {
    if (session.phase == LocalCallPhase.reconnecting) return 'Reconnecting…';
    final answered = session.answeredAt;
    if (answered == null) return 'Calling';
    final secs = DateTime.now().toUtc().difference(answered).inSeconds;
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
