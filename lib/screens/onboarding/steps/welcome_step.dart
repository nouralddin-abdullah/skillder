import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 48),
          // App icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to Skillder.',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please follow these House Rules.',
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 36),
          _RuleItem(
            title: 'Be yourself.',
            description:
                'Make sure your photos, skills, and bio are true to who you are.',
          ),
          const SizedBox(height: 24),
          _RuleItem(
            title: 'Stay safe.',
            description:
                "Don't be too quick to give out personal information.",
          ),
          const SizedBox(height: 24),
          _RuleItem(
            title: 'Play it cool.',
            description:
                'Respect others and treat them as you would like to be treated.',
          ),
          const SizedBox(height: 24),
          _RuleItem(
            title: 'Be proactive.',
            description: 'Always report bad behavior.',
          ),
        ],
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final String title;
  final String description;

  const _RuleItem({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
