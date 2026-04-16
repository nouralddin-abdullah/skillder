import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/profile_prompts.dart';
import '../../theme/app_colors.dart';

class SelectPromptScreen extends StatelessWidget {
  final Set<String> usedPrompts;

  const SelectPromptScreen({super.key, this.usedPrompts = const {}});

  @override
  Widget build(BuildContext context) {
    final available =
        profilePrompts.where((p) => !usedPrompts.contains(p)).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Select a prompt',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [SizedBox(width: 56)],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: available.length,
        separatorBuilder: (_, _) => const Divider(
          height: 1,
          thickness: 0.5,
          color: Color(0xFFE5E5EA),
          indent: 20,
          endIndent: 20,
        ),
        itemBuilder: (_, i) {
          final prompt = available[i];
          return InkWell(
            onTap: () => Navigator.of(context).pop(prompt),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                prompt,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
