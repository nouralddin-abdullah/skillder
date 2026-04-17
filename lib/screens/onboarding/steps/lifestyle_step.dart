import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class LifestyleStep extends StatelessWidget {
  final String? fuelSource;
  final String? focusSoundtrack;
  final String? rechargeMode;
  final ValueChanged<String> onFuelChanged;
  final ValueChanged<String> onFocusChanged;
  final ValueChanged<String> onRechargeChanged;

  const LifestyleStep({
    super.key,
    required this.fuelSource,
    required this.focusSoundtrack,
    required this.rechargeMode,
    required this.onFuelChanged,
    required this.onFocusChanged,
    required this.onRechargeChanged,
  });

  static const List<String> fuelOptions = [
    'Coffee',
    'Matcha',
    'Tea',
    'Energy Drinks',
    'Photosynthesizing',
  ];

  static const List<String> focusOptions = [
    'Lofi Beats',
    'Silence',
    'Heavy Metal',
    'Spotify Random',
  ];

  static const List<String> rechargeOptions = [
    'Cozy Gaming',
    'Gym',
    'Touching Grass',
    'Reading',
    'Sleeping',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          Center(
            child: Text(
              "Let's talk lifestyle\nhabits",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.2,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Do their habits match yours? You go first.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          _QuestionSection(
            icon: Icons.local_cafe_outlined,
            question: 'What fuels your day?',
            options: fuelOptions,
            selected: fuelSource,
            onSelected: onFuelChanged,
          ),
          const SizedBox(height: 28),
          _QuestionSection(
            icon: Icons.headphones_outlined,
            question: 'What do you listen to while focusing?',
            options: focusOptions,
            selected: focusSoundtrack,
            onSelected: onFocusChanged,
          ),
          const SizedBox(height: 28),
          _QuestionSection(
            icon: Icons.battery_charging_full_rounded,
            question: 'How do you recharge?',
            options: rechargeOptions,
            selected: rechargeMode,
            onSelected: onRechargeChanged,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _QuestionSection extends StatelessWidget {
  final IconData icon;
  final String question;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _QuestionSection({
    required this.icon,
    required this.question,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, thickness: 0.5, color: Color(0xFFE5E5EA)),
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textPrimary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                question,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((opt) {
            final isSelected = opt == selected;
            return GestureDetector(
              onTap: () => onSelected(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : const Color(0xFFE5E5EA),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  opt,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
