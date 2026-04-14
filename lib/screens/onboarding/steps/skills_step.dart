import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/skill_category.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/onboarding/category_section.dart';
import '../../../widgets/onboarding/selected_skills_bar.dart';

class SkillsStep extends StatefulWidget {
  final String title;
  final String subtitle;
  final Set<String> selectedSkills;
  final int maxSkills;
  final ValueChanged<String> onSkillToggle;

  const SkillsStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selectedSkills,
    required this.maxSkills,
    required this.onSkillToggle,
  });

  @override
  State<SkillsStep> createState() => _SkillsStepState();
}

class _SkillsStepState extends State<SkillsStep> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header area (non-scrollable)
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Column(
            children: [
              // Title row with counter
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: 26),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.selectedSkills.isEmpty
                          ? AppColors.inputFill
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '${widget.selectedSkills.length} of ${widget.maxSkills}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.selectedSkills.isEmpty
                            ? AppColors.textSecondary
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Search bar
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search skills...',
                  fillColor: AppColors.inputFill,
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 12),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                      size: 22,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: AppColors.textHint, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),

        // Selected skills bar
        SelectedSkillsBar(
          selectedSkills: widget.selectedSkills,
          maxSkills: widget.maxSkills,
          onRemove: widget.onSkillToggle,
        ),

        // Scrollable categories
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 100),
            itemCount: skillCategories.length,
            itemBuilder: (context, index) {
              return CategorySection(
                category: skillCategories[index],
                selectedSkills: widget.selectedSkills,
                onSkillToggle: (skill) {
                  // Enforce max limit
                  if (!widget.selectedSkills.contains(skill) &&
                      widget.selectedSkills.length >= widget.maxSkills) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'You can select up to ${widget.maxSkills} skills',
                        ),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  widget.onSkillToggle(skill);
                },
                searchQuery: _searchQuery,
              );
            },
          ),
        ),
      ],
    );
  }
}
