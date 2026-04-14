import 'package:flutter/material.dart';

import 'screens/home/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const SkillderApp());
}

class SkillderApp extends StatelessWidget {
  const SkillderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skillder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeShell(),
    );
  }
}
