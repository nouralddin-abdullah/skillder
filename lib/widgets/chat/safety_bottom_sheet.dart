import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class SafetyBottomSheet extends StatelessWidget {
  const SafetyBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Safety Toolkit',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Report
          _SafetyItem(
            icon: Icons.flag_rounded,
            iconColor: AppColors.primary,
            title: 'REPORT',
            description:
                "Report someone you're no longer matched with, or illegal content.",
            onTap: () {
              Navigator.pop(context);
              print('Report tapped');
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: AppColors.divider, height: 1),
          ),

          // Update Safety Settings
          _SafetyItem(
            icon: Icons.settings_rounded,
            iconColor: AppColors.textSecondary,
            title: 'UPDATE SAFETY SETTINGS',
            description:
                'Turn on features designed to help you feel safer throughout your Skillder experience.',
            onTap: () {
              Navigator.pop(context);
              print('Safety settings tapped');
            },
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: AppColors.divider, height: 1),
          ),

          // Access Safety Center
          _SafetyItem(
            icon: Icons.shield_rounded,
            iconColor: const Color(0xFF6C5CE7),
            title: 'ACCESS SAFETY CENTER',
            description:
                'Your well-being matters. Find safety resources and tools here.',
            onTap: () {
              Navigator.pop(context);
              print('Safety center tapped');
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _SafetyItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _SafetyItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
