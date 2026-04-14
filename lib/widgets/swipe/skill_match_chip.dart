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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: isMatch ? AppColors.primaryGradient : null,
        color: isMatch ? null : const Color(0xFF3A3A3C),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}
