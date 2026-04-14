import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class IdentityStep extends StatelessWidget {
  final VoidCallback onPickImage;
  final Uint8List? imageBytes;
  final TextEditingController headlineController;

  const IdentityStep({
    super.key,
    required this.onPickImage,
    required this.imageBytes,
    required this.headlineController,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          Text(
            "Let's set up\nyour profile",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add a photo and tell people what you do',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 48),

          // Profile picture upload
          GestureDetector(
            onTap: onPickImage,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                shape: BoxShape.circle,
                border: Border.all(
                  color: hasImage ? AppColors.primary : AppColors.inputBorder,
                  width: hasImage ? 3 : 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: hasImage
                  ? ClipOval(
                      child: Image.memory(
                        imageBytes!,
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Add Photo',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 48),

          // Job title field
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Your headline',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: headlineController,
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'e.g. Senior Flutter Developer',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  Icons.work_outline_rounded,
                  color: AppColors.textHint,
                  size: 20,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This is what people will see under your name',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
