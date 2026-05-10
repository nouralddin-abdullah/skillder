import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/chat_outbox_service.dart';
import '../../services/chat_socket_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat/safety_tips_dialog.dart';
import 'chat_screen.dart';
import 'explore_screen.dart';
import 'profile_screen.dart';
import 'swipe_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Drain any messages queued offline in a previous session — independent
    // of which tab the user lands on first.
    unawaited(_bootChatStack());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_resumeRealtime());
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_pauseRealtime());
      case AppLifecycleState.inactive:
        // Brief transitions (e.g. incoming call overlay) — leave the socket
        // alone, it'll auto-recover.
        break;
    }
  }

  Future<void> _bootChatStack() async {
    try {
      final outbox = await ChatOutboxServiceHolder.instance();
      await outbox.drain();
      final socket = await ChatSocketServiceHolder.instance();
      await socket.connect();
    } catch (_) {
      // Best-effort. The chat tab will retry on its own.
    }
  }

  Future<void> _resumeRealtime() async {
    try {
      final socket = await ChatSocketServiceHolder.instance();
      await socket.connect();
      // Drain any sends queued while we were paused.
      final outbox = await ChatOutboxServiceHolder.instance();
      await outbox.drain();
    } catch (_) {}
  }

  Future<void> _pauseRealtime() async {
    try {
      final socket = await ChatSocketServiceHolder.instance();
      await socket.disconnect();
    } catch (_) {}
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);

    if (index == 3) {
      _checkAndShowSafetyTips();
    }
  }

  Future<void> _checkAndShowSafetyTips() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('has_shown_safety_tips') ?? false;

    if (!hasShown) {
      await prefs.setBool('has_shown_safety_tips', true);
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const SafetyTipsDialog(),
      );
    }
  }

  bool get _isDarkMode => _currentIndex == 0;

  Color get _navBg => _isDarkMode ? Colors.black : Colors.white;
  Color get _navActive =>
      _isDarkMode ? Colors.white : AppColors.textPrimary;
  Color get _navInactive =>
      _isDarkMode ? Colors.white38 : AppColors.textHint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const SwipeScreen(),
          const ExploreScreen(),
          _placeholder('Likes'),
          const ChatScreen(),
          const ProfileTabScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _navBg,
          border: Border(
            top: BorderSide(
              color: _isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.divider,
              width: 0.5,
            ),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onNavTap,
            type: BottomNavigationBarType.fixed,
            backgroundColor: _navBg,
            selectedItemColor: _navActive,
            unselectedItemColor: _navInactive,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            showSelectedLabels: true,
            showUnselectedLabels: true,
            selectedLabelStyle: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w400,
            ),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: 26,
                    color: _currentIndex == 0 ? _navActive : _navInactive,
                  ),
                ),
                label: 'Swipe',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: SvgPicture.asset(
                    'assets/svgs/compass.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 1 ? _navActive : _navInactive,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Explore',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: SvgPicture.asset(
                    'assets/svgs/heart.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 2 ? _navActive : _navInactive,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Likes',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: SvgPicture.asset(
                    'assets/svgs/message-circle.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 3 ? _navActive : _navInactive,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: SvgPicture.asset(
                    'assets/svgs/user-round.svg',
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      _currentIndex == 4 ? _navActive : _navInactive,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(String title) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
