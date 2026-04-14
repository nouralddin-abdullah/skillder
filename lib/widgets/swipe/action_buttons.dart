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
          size: 58,
          color: const Color(0xFFFF4458),
          icon: Icons.close_rounded,
          iconSize: 30,
        ),
        const SizedBox(width: 24),

        // Super Pitch (star)
        _ActionButton(
          onTap: onSuperPitch,
          size: 44,
          color: const Color(0xFF3B9FFF),
          icon: Icons.star_rounded,
          iconSize: 22,
        ),
        const SizedBox(width: 24),

        // Like (heart)
        _ActionButton(
          onTap: onLike,
          size: 58,
          color: const Color(0xFF2DDB6E),
          icon: Icons.favorite_rounded,
          iconSize: 30,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  final Color color;
  final IconData icon;
  final double iconSize;

  const _ActionButton({
    required this.onTap,
    required this.size,
    required this.color,
    required this.icon,
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
          color: Colors.transparent,
          border: Border.all(
            color: color.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}
