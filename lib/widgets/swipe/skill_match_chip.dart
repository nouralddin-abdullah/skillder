import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class SkillMatchChip extends StatelessWidget {
  final String label;
  final bool isMatch;

  const SkillMatchChip({
    super.key,
    required this.label,
    this.isMatch = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: isMatch ? AppColors.primaryGradient : null,
        color: isMatch ? null : Colors.transparent,
        borderRadius: BorderRadius.circular(100),
        border: isMatch
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
