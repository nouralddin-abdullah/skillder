import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../controllers/active_call_controller.dart';
import '../models/call_models.dart';
import '../models/call_session.dart';
import '../services/call_permissions.dart';
import '_call_avatar.dart';

/// In-app fallback shown when the FCM-driven native callkit UI is bypassed
/// (app is open in foreground). Native UI handles cold-start ringing.
class IncomingCallScreen extends StatelessWidget {
  final ActiveCallController controller;
  const IncomingCallScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final session = controller.session;
          if (session == null) return const SizedBox.shrink();
          return Scaffold(
            backgroundColor: AppColors.surface,
            // See OutgoingCallScreen — SizedBox.expand pins the gradient
            // to the full viewport so the Scaffold's white background
            // doesn't leak through on the right.
            body: SizedBox.expand(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppColors.backgroundGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        session.kind == CallKind.video
                            ? 'Incoming video call'
                            : 'Incoming call',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      CallAvatar(
                        photoUrl: session.peerPhotoUrl,
                        size: 160,
                        light: true,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        session.peerName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '🔒 End-to-end encrypted',
                        style: GoogleFonts.inter(
                          color: AppColors.textHint,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _RoundActionButton(
                            icon: Icons.call_end_rounded,
                            label: 'Decline',
                            color: AppColors.error,
                            enabled: session.phase == LocalCallPhase.incoming,
                            onTap: () => controller.reject(),
                          ),
                          _RoundActionButton(
                            icon: Icons.call_rounded,
                            label: session.phase == LocalCallPhase.accepting
                                ? 'Connecting…'
                                : 'Accept',
                            color: const Color(0xFF22C55E),
                            enabled: session.phase == LocalCallPhase.incoming,
                            loading: session.phase == LocalCallPhase.accepting,
                            onTap: () async {
                              try {
                                await controller.accept();
                              } on CallPermissionDeniedException catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(e.userMessage),
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                                await controller.reject();
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool enabled;
  final bool loading;
  const _RoundActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = enabled ? color : color.withValues(alpha: 0.4);
    return Column(
      children: [
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            width: 72,
            height: 72,
            decoration:
                BoxDecoration(color: effectiveColor, shape: BoxShape.circle),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(22),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
