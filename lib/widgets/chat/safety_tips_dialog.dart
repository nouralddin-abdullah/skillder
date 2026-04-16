import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SafetyTipsDialog extends StatefulWidget {
  const SafetyTipsDialog({super.key});

  @override
  State<SafetyTipsDialog> createState() => _SafetyTipsDialogState();
}

class _SafetyTipsDialogState extends State<SafetyTipsDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<SafetyPageData> _pages = [
    SafetyPageData(
      title: 'Be respectful',
      description: "Don't bully, harass, or threaten others. We don't support discrimination of any kind. Skillder is no place for hate.",
      subTitle: 'Respect boundaries',
      subDescription: 'Always get consent from people before talking about personal info or expressing non-professional desires.',
      imagePath: 'assets/images/safety-widget/safety-slide-1.png',
    ),
    SafetyPageData(
      title: 'Is it a scam?',
      description: "Be mindful of someone playing on your emotions or claiming they desperately need money. It's okay to say \"no.\"",
      subTitle: 'Spot a get-rich-quick scheme',
      subDescription: 'If someone promises a big cash-out that sounds too good to be true - it probably is. Trust your gut.',
      imagePath: 'assets/images/safety-widget/safety-slide-2.png',
    ),
    SafetyPageData(
      title: 'Take your time, if you want',
      description: 'You can always ask someone to get Verified or video chat first before sharing too much info or meeting up.',
      subTitle: 'Unmatch, block, or report',
      subDescription: 'If someone crosses a line, tell us. Reports are treated confidentially. You can also block or unmatch them.',
      imagePath: 'assets/images/safety-widget/safety-slide-3.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shield Header
            Row(
              children: [
                const Icon(Icons.shield_rounded, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Skill Safely',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Pager for Content
            SizedBox(
              height: 460, // Height to fit illustration + text
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Illustration Area
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F1F7),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Image.asset(
                            page.imagePath,
                            fit: BoxFit.contain,
                            height: 120,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title & Description
                      Text(
                        page.title,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        page.description,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subtitle & SubDescription
                      Text(
                        page.subTitle,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        page.subDescription,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.4,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (index) {
                return Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.black
                        : Colors.grey.withValues(alpha: 0.4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Got it' : 'Next',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SafetyPageData {
  final String title;
  final String description;
  final String subTitle;
  final String subDescription;
  final String imagePath;

  SafetyPageData({
    required this.title,
    required this.description,
    required this.subTitle,
    required this.subDescription,
    required this.imagePath,
  });
}
