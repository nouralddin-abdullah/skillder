import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_exception.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/onboarding/onboarding_progress.dart';
import '../home/home_shell.dart';
import 'steps/basics_step.dart';
import 'steps/identity_step.dart';
import 'steps/intent_step.dart';
import 'steps/lifestyle_step.dart';
import 'steps/skills_step.dart';
import 'steps/welcome_step.dart';

class OnboardingScreen extends StatefulWidget {
  /// Step index to start on (0–6). Used when resuming a partial onboarding.
  final int startStep;

  /// Optional profile from `GET /users/me` used to pre-fill fields when
  /// resuming, so the user can see their existing answers.
  final Map<String, dynamic>? initialProfile;

  const OnboardingScreen({
    super.key,
    this.startStep = 0,
    this.initialProfile,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _totalSteps = 7; // 0-6

  late final PageController _pageController;
  late int _currentStep;

  // Step 0: Identity
  final TextEditingController _headlineController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  Uint8List? _profileImageBytes;

  // Step 1: Give skills
  final Set<String> _giveSkills = {};
  static const int _maxGiveSkills = 10;

  // Step 2: Get skills
  final Set<String> _getSkills = {};
  static const int _maxGetSkills = 10;

  // Step 3: Intent
  final Set<String> _selectedIntents = {};

  // Step 4: Basics (skippable)
  String? _education;
  String? _careerStage;
  String? _domain;
  String? _workStyle;

  // Step 5: Lifestyle (skippable)
  String? _fuelSource;
  String? _focusSoundtrack;
  String? _rechargeMode;

  // Step 6: Welcome (no skip, no progress bar)

  bool _saving = false;
  bool _pickingImage = false;
  bool _photoUploaded = false;
  String? _pendingPhotoPath;
  Uint8List? _pendingPhotoBytes;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.startStep.clamp(0, _totalSteps - 1);
    _pageController = PageController(initialPage: _currentStep);

    final p = widget.initialProfile;
    if (p != null) {
      final headline = p['headline'];
      if (headline is String) _headlineController.text = headline;

      final give = p['giveSkills'];
      if (give is List) _giveSkills.addAll(give.cast<String>());

      final get = p['getSkills'];
      if (get is List) _getSkills.addAll(get.cast<String>());

      final intents = p['intents'];
      if (intents is List) _selectedIntents.addAll(intents.cast<String>());

      _education = p['education'] as String?;
      _careerStage = p['careerStage'] as String?;
      _domain = p['domain'] as String?;
      _workStyle = p['workStyle'] as String?;
      _fuelSource = p['fuelSource'] as String?;
      _focusSoundtrack = p['focusSoundtrack'] as String?;
      _rechargeMode = p['rechargeMode'] as String?;

      // If photo already exists on the server, mark as uploaded so we don't
      // re-upload anything during step-0 if the user just hits Continue.
      final photos = p['photos'];
      if (photos is List && photos.isNotEmpty) _photoUploaded = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _headlineController.dispose();
    super.dispose();
  }

  /// Build the PATCH body for the current step.
  Map<String, dynamic>? _payloadForCurrentStep() {
    switch (_currentStep) {
      case 0:
        return {'headline': _headlineController.text.trim()};
      case 1:
        return {'giveSkills': _giveSkills.toList()};
      case 2:
        return {'getSkills': _getSkills.toList()};
      case 3:
        return {'intents': _selectedIntents.toList()};
      case 4:
        return {
          if (_education != null) 'education': _education,
          if (_careerStage != null) 'careerStage': _careerStage,
          if (_domain != null) 'domain': _domain,
          if (_workStyle != null) 'workStyle': _workStyle,
        };
      case 5:
        return {
          if (_fuelSource != null) 'fuelSource': _fuelSource,
          if (_focusSoundtrack != null) 'focusSoundtrack': _focusSoundtrack,
          if (_rechargeMode != null) 'rechargeMode': _rechargeMode,
        };
      case 6:
        return {
          'acceptedHouseRules': true,
          'onboardingComplete': true,
        };
    }
    return null;
  }

  Future<void> _nextStep() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });

    try {
      // Step 0: also upload photo if user picked one and it isn't uploaded yet.
      if (_currentStep == 0 &&
          !_photoUploaded &&
          (_pendingPhotoPath != null || _pendingPhotoBytes != null)) {
        await UserService.uploadPhoto(
          filePath: _pendingPhotoPath,
          bytes: _pendingPhotoBytes,
        );
        _photoUploaded = true;
      }

      final payload = _payloadForCurrentStep();
      if (payload != null && payload.isNotEmpty) {
        await UserService.patchMe(payload);
      }
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _saveError = e.message;
      });
      return;
    } catch (_) {
      setState(() {
        _saving = false;
        _saveError = 'Network error. Please try again.';
      });
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (route) => false,
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

  // Steps 0-3 are mandatory, 4-5 skippable, 6 is welcome
  bool get _isSkippable => _currentStep == 4 || _currentStep == 5;
  bool get _isWelcome => _currentStep == 6;

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
      case 4: // Basics — skippable, always can proceed
        return true;
      case 5: // Lifestyle — skippable, always can proceed
        return true;
      case 6: // Welcome — always can proceed
        return true;
      default:
        return false;
    }
  }

  String get _buttonLabel {
    if (_isWelcome) return 'I agree';
    if (_currentStep == 4 || _currentStep == 5) {
      // Count how many answered
      int answered = 0;
      int total = 0;
      if (_currentStep == 4) {
        total = 4;
        if (_education != null) answered++;
        if (_careerStage != null) answered++;
        if (_domain != null) answered++;
        if (_workStyle != null) answered++;
      } else {
        total = 3;
        if (_fuelSource != null) answered++;
        if (_focusSoundtrack != null) answered++;
        if (_rechargeMode != null) answered++;
      }
      return 'Next $answered/$total';
    }
    return 'Continue';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar — hidden on welcome step
            if (!_isWelcome)
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
                        totalSteps: _totalSteps,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Skip button — only on skippable steps
                    if (_isSkippable)
                      TextButton(
                        onPressed: _saving ? null : _nextStep,
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
                      )
                    else
                      const SizedBox(width: 40),
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
                  // Step 0: Identity
                  IdentityStep(
                    onPickImage: () async {
                      if (_pickingImage) return;
                      setState(() => _pickingImage = true);
                      try {
                        final XFile? picked = await _imagePicker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 800,
                          maxHeight: 800,
                          imageQuality: 85,
                        );
                        if (picked != null) {
                          final bytes = await picked.readAsBytes();
                          if (!mounted) return;
                          setState(() {
                            _profileImageBytes = bytes;
                            _pendingPhotoPath = kIsWeb ? null : picked.path;
                            _pendingPhotoBytes = kIsWeb ? bytes : null;
                            _photoUploaded = false;
                          });
                        }
                      } finally {
                        if (mounted) setState(() => _pickingImage = false);
                      }
                    },
                    isPickingImage: _pickingImage,
                    imageBytes: _profileImageBytes,
                    headlineController: _headlineController,
                  ),

                  // Step 1: Give
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

                  // Step 2: Get
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

                  // Step 3: Intent
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

                  // Step 4: Basics (skippable)
                  BasicsStep(
                    education: _education,
                    careerStage: _careerStage,
                    domain: _domain,
                    workStyle: _workStyle,
                    onEducationChanged: (v) =>
                        setState(() => _education = v),
                    onCareerStageChanged: (v) =>
                        setState(() => _careerStage = v),
                    onDomainChanged: (v) =>
                        setState(() => _domain = v),
                    onWorkStyleChanged: (v) =>
                        setState(() => _workStyle = v),
                  ),

                  // Step 5: Lifestyle (skippable)
                  LifestyleStep(
                    fuelSource: _fuelSource,
                    focusSoundtrack: _focusSoundtrack,
                    rechargeMode: _rechargeMode,
                    onFuelChanged: (v) =>
                        setState(() => _fuelSource = v),
                    onFocusChanged: (v) =>
                        setState(() => _focusSoundtrack = v),
                    onRechargeChanged: (v) =>
                        setState(() => _rechargeMode = v),
                  ),

                  // Step 6: Welcome / House Rules
                  const WelcomeStep(),
                ],
              ),
            ),

            // Bottom CTA button
            Container(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
              decoration: _isWelcome
                  ? null
                  : BoxDecoration(
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
                  final enabled = _canProceed && !_saving;

                  Widget buttonChild() {
                    if (_saving) {
                      return const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      );
                    }
                    return Text(
                      _buttonLabel,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: enabled || _isWelcome
                            ? Colors.white
                            : AppColors.textHint,
                      ),
                    );
                  }

                  Widget button;
                  if (_isWelcome) {
                    button = SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: buttonChild(),
                      ),
                    );
                  } else {
                    button = SizedBox(
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
                          child: buttonChild(),
                        ),
                      ),
                    );
                  }

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_saveError != null) ...[
                        Text(
                          _saveError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      button,
                    ],
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
