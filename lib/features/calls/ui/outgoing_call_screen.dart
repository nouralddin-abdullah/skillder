import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../controllers/active_call_controller.dart';
import '../models/call_models.dart';
import '_call_avatar.dart';

/// Shown to the caller after they tap a call icon — while we're either
/// still POSTing /api/calls (`dialing`) or waiting for the callee to
/// accept (`outgoing`).
class OutgoingCallScreen extends StatelessWidget {
  final ActiveCallController controller;
  const OutgoingCallScreen({super.key, required this.controller});

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
            // SizedBox.expand pins the gradient to the full viewport. A
            // bare Container with a gradient decoration sizes itself to
            // its child when parent constraints aren't tight, so the
            // gradient ends up only as wide as the widest Text inside
            // and Scaffold's white background shows through on the right.
            body: SizedBox.expand(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppColors.backgroundGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Column(
                      // Column defaults to start — without this everything
                      // hangs left of center.
                      crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        session.kind == CallKind.video
                            ? 'Video calling…'
                            : 'Calling…',
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
                        'End-to-end encrypted',
                        style: GoogleFonts.inter(
                          color: AppColors.textHint,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => controller.cancel(),
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
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
