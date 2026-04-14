import 'package:flutter/material.dart';

class SwipeActionButtons extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onSuperPitch;
  final VoidCallback onLike;

  const SwipeActionButtons({
    super.key,
    required this.onPass,
    required this.onSuperPitch,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pass (X)
        _ActionButton(
          onTap: onPass,
          size: 60,
          bgColor: const Color(0xFFFF4458),
          icon: Icons.close_rounded,
          iconColor: Colors.white,
          iconSize: 32,
        ),
        const SizedBox(width: 18),

        // Super Pitch (star)
        _ActionButton(
          onTap: onSuperPitch,
          size: 46,
          bgColor: const Color(0xFF3B9FFF),
          icon: Icons.star_rounded,
          iconColor: Colors.white,
          iconSize: 24,
        ),
        const SizedBox(width: 18),

        // Like (heart)
        _ActionButton(
          onTap: onLike,
          size: 60,
          bgColor: const Color(0xFF2DDB6E),
          icon: Icons.favorite_rounded,
          iconColor: Colors.white,
          iconSize: 32,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  final Color bgColor;
  final IconData icon;
  final Color iconColor;
  final double iconSize;

  const _ActionButton({
    required this.onTap,
    required this.size,
    required this.bgColor,
    required this.icon,
    required this.iconColor,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: bgColor.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
