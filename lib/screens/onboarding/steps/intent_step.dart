import 'package:flutter/material.dart';

import '../../../widgets/onboarding/intent_card.dart';

class IntentStep extends StatelessWidget {
  final Set<String> selectedIntents;
  final ValueChanged<String> onToggle;

  const IntentStep({
    super.key,
    required this.selectedIntents,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 32),

          Text(
            "What are you\nlooking for?",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                ),
          ),
          const SizedBox(height: 40),

          IntentCard(
            emoji: '🔄',
            title: 'Skill Swap',
            description:
                'Trade skills with someone — you teach yours, they teach theirs.',
            isSelected: selectedIntents.contains('swap'),
            onTap: () => onToggle('swap'),
          ),
          const SizedBox(height: 16),

          IntentCard(
            emoji: '🤝',
            title: 'Co-Learning',
            description:
                'Find a partner to learn something new together, side by side.',
            isSelected: selectedIntents.contains('colearn'),
            onTap: () => onToggle('colearn'),
          ),
          const SizedBox(height: 16),

          IntentCard(
            emoji: '🎓',
            title: 'Mentorship',
            description:
                'Get guidance from someone experienced or mentor others.',
            isSelected: selectedIntents.contains('mentor'),
            onTap: () => onToggle('mentor'),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
