import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Circular avatar shown in call screens. Falls back to a person silhouette
/// when no photo is available. Supports both light and dark backgrounds
/// via the [light] flag — the placeholder fill and icon contrast adjust
/// to stay legible on either.
class CallAvatar extends StatelessWidget {
  final String? photoUrl;
  final double size;
  final bool light;

  const CallAvatar({
    super.key,
    required this.photoUrl,
    this.size = 80,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final placeholderBg = light
        ? AppColors.inputFill
        : Colors.white.withValues(alpha: 0.15);
    final placeholderIcon = light ? AppColors.textHint : Colors.white70;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: placeholderBg,
        image: hasPhoto
            ? DecorationImage(
                image: NetworkImage(photoUrl!),
                fit: BoxFit.cover,
              )
            : null,
        border: light
            ? Border.all(color: AppColors.divider, width: 2)
            : null,
      ),
      child: hasPhoto
          ? null
          : Icon(
              Icons.person_rounded,
              size: size * 0.5,
              color: placeholderIcon,
            ),
    );
  }
}
