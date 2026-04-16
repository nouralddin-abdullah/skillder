import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import 'select_prompt_screen.dart';

class AnswerPromptScreen extends StatefulWidget {
  final String prompt;
  final String? initialAnswer;
  final Set<String> usedPrompts;

  const AnswerPromptScreen({
    super.key,
    required this.prompt,
    this.initialAnswer,
    this.usedPrompts = const {},
  });

  @override
  State<AnswerPromptScreen> createState() => _AnswerPromptScreenState();
}

class _AnswerPromptScreenState extends State<AnswerPromptScreen> {
  static const int _maxChars = 150;

  late final TextEditingController _controller;
  late String _currentPrompt;

  @override
  void initState() {
    super.initState();
    _currentPrompt = widget.prompt;
    _controller = TextEditingController(text: widget.initialAnswer ?? '');
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _changePrompt() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SelectPromptScreen(usedPrompts: widget.usedPrompts),
      ),
    );
    if (result != null) setState(() => _currentPrompt = result);
  }

  void _save() {
    if (_controller.text.trim().isEmpty) return;
    Navigator.of(context).pop(
      (prompt: _currentPrompt, answer: _controller.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _controller.text.trim().isNotEmpty;
    final count = _controller.text.characters.length;

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
          'Answer prompt',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check_rounded,
              color: canSave ? AppColors.primary : AppColors.textHint,
            ),
            onPressed: canSave ? _save : null,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: _changePrompt,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE5E5EA),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _currentPrompt,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Stack(
                    children: [
                      TextField(
                        controller: _controller,
                        maxLength: _maxChars,
                        maxLines: 5,
                        minLines: 3,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(_maxChars),
                        ],
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          isCollapsed: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      if (_controller.text.isEmpty)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: IgnorePointer(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.textHint,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Write something fun...',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 6),
                Text.rich(
                  TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      TextSpan(
                        text: '$count',
                        style: TextStyle(
                          color: count < 10
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                      const TextSpan(text: '/'),
                      TextSpan(text: '$_maxChars'),
                    ],
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }
}
