import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class BasicsStep extends StatelessWidget {
  final String? education;
  final String? careerStage;
  final String? domain;
  final String? workStyle;
  final ValueChanged<String> onEducationChanged;
  final ValueChanged<String> onCareerStageChanged;
  final ValueChanged<String> onDomainChanged;
  final ValueChanged<String> onWorkStyleChanged;

  const BasicsStep({
    super.key,
    required this.education,
    required this.careerStage,
    required this.domain,
    required this.workStyle,
    required this.onEducationChanged,
    required this.onCareerStageChanged,
    required this.onDomainChanged,
    required this.onWorkStyleChanged,
  });

  static const List<String> educationOptions = [
    'High School',
    'In College',
    'Bachelors',
    'In Grad School',
    'Masters',
    'PhD',
    'Trade School',
  ];

  static const List<String> careerOptions = [
    'Student',
    'Intern',
    'Junior',
    'Mid-level',
    'Senior',
    'Lead',
    'Manager',
    'Founder',
  ];

  static const List<String> domainOptions = [
    'Technology',
    'Finance',
    'HR',
    'Marketing',
    'Design',
    'Healthcare',
    'Education',
    'Legal',
    'Sales',
    'Operations',
  ];

  static const List<String> workStyleOptions = ['Remote', 'Office', 'Hybrid'];

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
              "What else makes\nyou—you?",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    height: 1.2,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              "Don't hold back. Authenticity attracts authenticity.",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          _QuestionSection(
            icon: Icons.school_outlined,
            question: 'What is your education level?',
            options: educationOptions,
            selected: education,
            onSelected: onEducationChanged,
          ),
          const SizedBox(height: 28),
          _QuestionSection(
            icon: Icons.work_outline_rounded,
            question: 'What stage are you at in your career?',
            options: careerOptions,
            selected: careerStage,
            onSelected: onCareerStageChanged,
          ),
          const SizedBox(height: 28),
          _QuestionSection(
            icon: Icons.business_center_outlined,
            question: 'Which domain do you work in?',
            options: domainOptions,
            selected: domain,
            onSelected: onDomainChanged,
          ),
          const SizedBox(height: 28),
          _QuestionSection(
            icon: Icons.laptop_mac_outlined,
            question: 'How do you prefer to work?',
            options: workStyleOptions,
            selected: workStyle,
            onSelected: onWorkStyleChanged,
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
