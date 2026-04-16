import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import '../onboarding/steps/intent_step.dart';

class EditIntentScreen extends StatefulWidget {
  final Set<String> initialIntents;

  const EditIntentScreen({super.key, required this.initialIntents});

  @override
  State<EditIntentScreen> createState() => _EditIntentScreenState();
}

class _EditIntentScreenState extends State<EditIntentScreen> {
  late final Set<String> _intents;

  @override
  void initState() {
    super.initState();
    _intents = {...widget.initialIntents};
  }

  void _toggle(String key) {
    setState(() {
      if (_intents.contains(key)) {
        _intents.remove(key);
      } else {
        _intents.add(key);
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
          onPressed: () => Navigator.of(context).pop(_intents),
        ),
        centerTitle: true,
        title: Text(
          'Intent',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_intents),
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
      body: IntentStep(
        selectedIntents: _intents,
        onToggle: _toggle,
      ),
    );
  }
}
