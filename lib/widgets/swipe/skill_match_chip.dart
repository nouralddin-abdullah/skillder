import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class SkillMatchChip extends StatelessWidget {
  final String label;
  final bool isMatch;

  /// Defaults to `true` (over the dark swipe card image). Set to `false` when
  /// rendering on a light surface (e.g. the expanded profile cards).
  final bool onDark;

  const SkillMatchChip({
    super.key,
    required this.label,
    this.isMatch = false,
    this.onDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = onDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFFD1D1D6);
    final textColor = isMatch
        ? Colors.white
        : (onDark ? Colors.white : AppColors.textPrimary);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: isMatch ? AppColors.primaryGradient : null,
        color: isMatch ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        border: isMatch ? null : Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
