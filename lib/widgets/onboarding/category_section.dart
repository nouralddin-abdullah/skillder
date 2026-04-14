import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/skill_category.dart';
import '../../theme/app_colors.dart';
import 'skill_chip.dart';

class CategorySection extends StatefulWidget {
  final SkillCategory category;
  final Set<String> selectedSkills;
  final ValueChanged<String> onSkillToggle;
  final String? searchQuery;

  const CategorySection({
    super.key,
    required this.category,
    required this.selectedSkills,
    required this.onSkillToggle,
    this.searchQuery,
  });

  @override
  State<CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<CategorySection> {
  bool _expanded = false;
  static const int _collapsedCount = 6;

  @override
  Widget build(BuildContext context) {
    List<String> filteredSkills = widget.category.skills;
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      filteredSkills = widget.category.skills
          .where((s) =>
              s.toLowerCase().contains(widget.searchQuery!.toLowerCase()))
          .toList();
    }

    if (filteredSkills.isEmpty) return const SizedBox.shrink();

    final bool hasMore = filteredSkills.length > _collapsedCount;
    final List<String> visibleSkills =
        _expanded ? filteredSkills : filteredSkills.take(_collapsedCount).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              '${widget.category.emoji}  ${widget.category.name}',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Chips
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 10,
              children: visibleSkills.map((skill) {
                return SkillChip(
                  label: skill,
                  isSelected: widget.selectedSkills.contains(skill),
                  onTap: () => widget.onSkillToggle(skill),
                );
              }).toList(),
            ),
          ),

          // Show more / less
          if (hasMore && (widget.searchQuery == null || widget.searchQuery!.isEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _expanded ? 'Show less' : 'Show more',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
