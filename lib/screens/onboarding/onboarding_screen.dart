import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import '../../widgets/onboarding/onboarding_progress.dart';
import 'steps/identity_step.dart';
import 'steps/intent_step.dart';
import 'steps/skills_step.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Identity
  final TextEditingController _headlineController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _profileImageBytes;

  // Step 2: Give skills
  final Set<String> _giveSkills = {};
  static const int _maxGiveSkills = 10;

  // Step 3: Get skills
  final Set<String> _getSkills = {};
  static const int _maxGetSkills = 10;

  // Step 4: Intent
  final Set<String> _selectedIntents = {};

  @override
  void dispose() {
    _pageController.dispose();
    _headlineController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      // Onboarding complete
      print('Onboarding complete!');
      print('Headline: ${_headlineController.text}');
      print('Give skills: $_giveSkills');
      print('Get skills: $_getSkills');
      print('Intents: $_selectedIntents');

      // Show completion dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('🎉'),
          content: Text(
            "You're all set! Your profile is ready.",
            style: GoogleFonts.inter(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Got it',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  bool get _canProceed {
    switch (_currentStep) {
      case 0:
        return _headlineController.text.trim().isNotEmpty;
      case 1:
        return _giveSkills.isNotEmpty;
      case 2:
        return _getSkills.isNotEmpty;
      case 3:
        return _selectedIntents.isNotEmpty;
      default:
        return false;
    }
  }

  String get _buttonLabel {
    if (_currentStep == 3) return 'Finish';
    return 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back button, progress, and skip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Row(
                children: [
                  // Back button
                  AnimatedOpacity(
                    opacity: _currentStep > 0 ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: _currentStep > 0 ? _previousStep : null,
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.textPrimary,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.inputFill,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(40, 40),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Progress bar
                  Expanded(
                    child: OnboardingProgress(
                      currentStep: _currentStep,
                      totalSteps: 4,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Skip button
                  TextButton(
                    onPressed: _nextStep,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(40, 40),
                    ),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) =>
                    setState(() => _currentStep = index),
                children: [
                  // Step 1: Identity
                  IdentityStep(
                    onPickImage: () async {
                      final XFile? picked = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 800,
                        imageQuality: 85,
                      );
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setState(() => _profileImageBytes = bytes);
                      }
                    },
                    imageBytes: _profileImageBytes,
                    headlineController: _headlineController,
                  ),

                  // Step 2: Give
                  SkillsStep(
                    title: 'Your Give',
                    subtitle: 'Skills you can teach others',
                    selectedSkills: _giveSkills,
                    maxSkills: _maxGiveSkills,
                    onSkillToggle: (skill) {
                      setState(() {
                        if (_giveSkills.contains(skill)) {
                          _giveSkills.remove(skill);
                        } else {
                          _giveSkills.add(skill);
                        }
                      });
                    },
                  ),

                  // Step 3: Get
                  SkillsStep(
                    title: 'Your Get',
                    subtitle: 'Skills you want to learn',
                    selectedSkills: _getSkills,
                    maxSkills: _maxGetSkills,
                    onSkillToggle: (skill) {
                      setState(() {
                        if (_getSkills.contains(skill)) {
                          _getSkills.remove(skill);
                        } else {
                          _getSkills.add(skill);
                        }
                      });
                    },
                  ),

                  // Step 4: Intent
                  IntentStep(
                    selectedIntents: _selectedIntents,
                    onToggle: (intent) {
                      setState(() {
                        if (_selectedIntents.contains(intent)) {
                          _selectedIntents.remove(intent);
                        } else {
                          _selectedIntents.add(intent);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),

            // Bottom CTA button
            Container(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ListenableBuilder(
                listenable: _headlineController,
                builder: (context, _) {
                  final enabled = _canProceed;
                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        gradient: enabled
                            ? AppColors.primaryGradient
                            : const LinearGradient(
                                colors: [
                                  Color(0xFFE0E0E0),
                                  Color(0xFFE0E0E0),
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: enabled
                            ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: ElevatedButton(
                        onPressed: enabled ? _nextStep : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          _buttonLabel,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: enabled
                                ? Colors.white
                                : AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
