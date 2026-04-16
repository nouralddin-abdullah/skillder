import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../onboarding/steps/skills_step.dart';

class EditSkillsScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final Set<String> initialSkills;
  final int maxSkills;

  const EditSkillsScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.initialSkills,
    this.maxSkills = 10,
  });

  @override
  State<EditSkillsScreen> createState() => _EditSkillsScreenState();
}

class _EditSkillsScreenState extends State<EditSkillsScreen> {
  late final Set<String> _skills;

  @override
  void initState() {
    super.initState();
    _skills = {...widget.initialSkills};
  }

  void _toggle(String skill) {
    setState(() {
      if (_skills.contains(skill)) {
        _skills.remove(skill);
      } else {
        _skills.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(_skills.toList()),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_skills.toList()),
            child: Text(
              'Done',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SkillsStep(
        title: widget.title,
        subtitle: widget.subtitle,
        selectedSkills: _skills,
        maxSkills: widget.maxSkills,
        onSkillToggle: _toggle,
      ),
    );
  }
}
