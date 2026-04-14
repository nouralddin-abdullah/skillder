import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';
import 'swipe_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  bool get _isDarkMode => _currentIndex == 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkMode ? Colors.black : Colors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          const SwipeScreen(),
          _placeholder('Explore'),
          _placeholder('Likes'),
          _placeholder('Chat'),
          _placeholder('Profile'),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
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
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white38,
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
              const BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child:
                      Icon(Icons.local_fire_department_rounded, size: 26),
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
                      _currentIndex == 1 ? Colors.white : Colors.white38,
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
                      _currentIndex == 2 ? Colors.white : Colors.white38,
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
                      _currentIndex == 3 ? Colors.white : Colors.white38,
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
                      _currentIndex == 4 ? Colors.white : Colors.white38,
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
      color: _isDarkMode ? Colors.black : Colors.white,
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: _isDarkMode ? Colors.white38 : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
