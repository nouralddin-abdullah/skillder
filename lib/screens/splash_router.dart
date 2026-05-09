import 'package:flutter/material.dart';

import '../services/api_exception.dart';
import '../services/auth_storage.dart';
import '../services/onboarding_resume.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import 'auth/login_screen.dart';
import 'home/home_shell.dart';
import 'onboarding/onboarding_screen.dart';

/// First screen on app start. Decides where to send the user based on whether
/// a token is saved and how far into onboarding they are.
class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _route());
  }

  Future<void> _route() async {
    final token = await AuthStorage.getToken();
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      _replace(const LoginScreen());
      return;
    }

    try {
      final me = await UserService.getMe();
      if (!mounted) return;
      _routeForProfile(me);
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        await AuthStorage.clear();
      }
      if (!mounted) return;
      _replace(const LoginScreen());
    } catch (_) {
      if (!mounted) return;
      _replace(const LoginScreen());
    }
  }

  void _routeForProfile(Map<String, dynamic> me) {
    final done = me['onboardingComplete'] == true;
    if (done) {
      _replace(const HomeShell());
    } else {
      final step = onboardingResumeStep(me);
      _replace(OnboardingScreen(startStep: step, initialProfile: me));
    }
  }

  void _replace(Widget page) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}
