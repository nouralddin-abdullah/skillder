import 'package:flutter/material.dart';

import '../../services/api_exception.dart';
import '../../services/auth_service.dart';
import '../../services/google_auth_service.dart';
import '../../services/onboarding_resume.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/divider_with_text.dart';
import '../../widgets/auth/primary_button.dart';
import '../../widgets/auth/social_button.dart';
import '../home/home_shell.dart';
import '../onboarding/onboarding_screen.dart';
import 'forgot_password_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService.login(email: email, password: password);
      await _routeAfterAuth();
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.fieldErrors?.isNotEmpty == true
          ? e.fieldErrors!.first.message
          : e.message;
      setState(() => _error = msg);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onGoogleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final idToken = await GoogleAuthService.signInAndGetIdToken();
      if (idToken == null) {
        // User cancelled the picker.
        if (mounted) setState(() => _loading = false);
        return;
      }
      final isNewUser =
          await AuthService.loginWithGoogle(idToken: idToken);
      await _routeAfterAuth(requireName: isNewUser);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _routeAfterAuth({bool requireName = false}) async {
    final me = await UserService.getMe();
    if (!mounted) return;
    final done = me['onboardingComplete'] == true;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => done
            ? const HomeShell()
            : OnboardingScreen(
                startStep: onboardingResumeStep(me),
                initialProfile: me,
                requireName: requireName,
              ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),

                    // Logo / Brand
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text(
                      'skillder',
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontSize: 36,
                                letterSpacing: -1,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Swipe. Match. Learn.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 48),

                    // Email field
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email address',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      prefixIcon: Icons.lock_outline_rounded,
                      isPassword: true,
                    ),
                    const SizedBox(height: 12),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot password?',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Login button
                    PrimaryButton(
                      text: _loading ? 'Logging in...' : 'Log In',
                      onPressed: _loading ? null : _onLogin,
                    ),
                    const SizedBox(height: 28),

                    // Divider
                    const DividerWithText(text: 'or continue with'),
                    const SizedBox(height: 28),

                    // Google button
                    SocialButton(
                      text: 'Continue with Google',
                      iconPath: 'assets/icons/google.png',
                      onPressed: _loading ? null : _onGoogleLogin,
                    ),
                    const SizedBox(height: 40),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
