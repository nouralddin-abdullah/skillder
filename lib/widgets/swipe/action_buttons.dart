import 'package:flutter/material.dart';

class SwipeActionButtons extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onSuperPitch;
  final VoidCallback onLike;

  /// 0..1 — how much the user is dragging toward each direction.
  /// Used to animate the matching button into its "active" gradient state.
  final double passProgress;
  final double superProgress;
  final double likeProgress;

  const SwipeActionButtons({
    super.key,
    required this.onPass,
    required this.onSuperPitch,
    required this.onLike,
    this.passProgress = 0,
    this.superProgress = 0,
    this.likeProgress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ActionButton(
          onTap: onPass,
          size: 60,
          icon: Icons.close_rounded,
          iconColor: const Color(0xFFFF3B7D),
          iconSize: 32,
          activeGradient: const LinearGradient(
            colors: [Color(0xFFFF3B7D), Color(0xFFBE3BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          progress: passProgress,
        ),
        const SizedBox(width: 18),

        _ActionButton(
          onTap: onSuperPitch,
          size: 46,
          icon: Icons.star_rounded,
          iconColor: const Color(0xFF3BAFFF),
          iconSize: 24,
          activeGradient: const LinearGradient(
            colors: [Color(0xFF3BAFFF), Color(0xFF1D6BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          progress: superProgress,
        ),
        const SizedBox(width: 18),

        _ActionButton(
          onTap: onLike,
          size: 60,
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFF5BE26B),
          iconSize: 32,
          activeGradient: const LinearGradient(
            colors: [Color(0xFFBEE25B), Color(0xFF2DDB6E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          progress: likeProgress,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  final IconData icon;
  final Color iconColor;
  final double iconSize;
  final LinearGradient activeGradient;
  final double progress; // 0..1

  const _ActionButton({
    required this.onTap,
    required this.size,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
    required this.activeGradient,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);

    // Idle look: dark charcoal fill + soft outline, colored icon.
    // Active look: gradient fill, white icon.
    final idleColor = const Color(0xFF1E1E1E);
    final borderColor = Colors.white.withValues(alpha: 0.08);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: t < 1 ? idleColor : null,
          gradient: t > 0 ? activeGradient : null,
          border: Border.all(color: borderColor, width: 1),
          boxShadow: t > 0.1
              ? [
                  BoxShadow(
                    color: activeGradient.colors.last
                        .withValues(alpha: 0.35 * t),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          // Snap to white as soon as any drag toward this button begins.
          color: t > 0.02 ? Colors.white : iconColor,
          size: iconSize,
        ),
      ),
    );
  }
}
