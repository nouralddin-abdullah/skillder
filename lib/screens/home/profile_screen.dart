import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_colors.dart';

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({super.key});

  static const Color _pageGray = Color(0xFFF2F2F7);
  static const double _headerCurveHeight = 40;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageGray,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // ── White top block with curved bottom ──
            ClipPath(
              clipper: _BottomCurveClipper(),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.only(
                  top: 56,
                  bottom: _headerCurveHeight + 40,
                ),
                child: Column(
                  children: [
                    const _AvatarWithProgress(
                      imageUrl:
                          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
                      progress: 0.20,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Luna, 23',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          size: 20,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const _ActionRow(),
                  ],
                ),
              ),
            ),

            // ── Gray section below with Platinum placeholder cards ──
            const SizedBox(height: 72),
            _PlatinumCarousel(),
            const SizedBox(height: 32),
          ],
        ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Avatar + progress ───────────────────────────

class _AvatarWithProgress extends StatelessWidget {
  final String imageUrl;
  final double progress; // 0.0 – 1.0

  const _AvatarWithProgress({
    required this.imageUrl,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 128;
    return SizedBox(
      width: size + 20,
      height: size + 34,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Dashed progress ring
          SizedBox(
            width: size + 20,
            height: size + 20,
            child: CustomPaint(
              painter: _DashedRingPainter(progress: progress),
            ),
          ),
          // Avatar
          Positioned(
            top: 10,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // Percent pill
          Positioned(
            bottom: 0,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(progress * 100).round()}% complete',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedRingPainter extends CustomPainter {
  final double progress;
  _DashedRingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2;
    const int dashCount = 40;
    const double gapFraction = 0.35;

    final sweepPerSlot = (2 * 3.141592653589793) / dashCount;
    final dashSweep = sweepPerSlot * (1 - gapFraction);

    final filledDashes = (dashCount * progress).round();

    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..shader = AppColors.primaryGradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    final inactivePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE5E5EA);

    for (int i = 0; i < dashCount; i++) {
      final startAngle = -3.141592653589793 / 2 + i * sweepPerSlot;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashSweep,
        false,
        i < filledDashes ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRingPainter old) =>
      old.progress != progress;
}

// ─────────────────────────── 3 action buttons ───────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionItem(
            label: 'Settings',
            child: _OutlinedCircleIcon(
              icon: Icon(
                Icons.settings_rounded,
                size: 26,
                color: AppColors.textPrimary,
              ),
            ),
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(top: 36),
            child: _ActionItem(
            label: 'Edit profile',
            child: _OutlinedCircleIcon(
              icon: Icon(
                Icons.mode_edit_rounded,
                size: 26,
                color: AppColors.textPrimary,
              ),
              redDot: true,
            ),
            onTap: () {},
          ),
          ),
          _ActionItem(
            label: 'Add media',
            child: _GradientCircleIcon(
              icon: const Icon(
                Icons.photo_camera_outlined,
                size: 26,
                color: Colors.white,
              ),
              plusBadge: true,
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback onTap;

  const _ActionItem({
    required this.label,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          child,
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlinedCircleIcon extends StatelessWidget {
  final Widget icon;
  final bool redDot;
  const _OutlinedCircleIcon({required this.icon, this.redDot = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE5E5EA),
                width: 1.5,
              ),
            ),
            child: Center(child: icon),
          ),
          if (redDot)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradientCircleIcon extends StatelessWidget {
  final Widget icon;
  final bool plusBadge;
  const _GradientCircleIcon({required this.icon, this.plusBadge = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Center(child: icon),
          ),
          if (plusBadge)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Curve clipper ───────────────────────────

class _BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 20);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      size.width,
      size.height - 20,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─────────────────────────── Platinum placeholder ───────────────────────────

class _PlatinumCarousel extends StatefulWidget {
  @override
  State<_PlatinumCarousel> createState() => _PlatinumCarouselState();
}

class _PlatinumCarouselState extends State<_PlatinumCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  final List<_PlatinumSlide> _slides = const [
    _PlatinumSlide(
      title: 'Skillder Platinum™',
      subtitle: 'Level up every action you take on Skillder',
    ),
    _PlatinumSlide(
      title: 'Priority Likes',
      subtitle: 'Your likes go to the top of their stack',
    ),
    _PlatinumSlide(
      title: 'See Who Likes You',
      subtitle: 'Skip the guesswork and match instantly',
    ),
    _PlatinumSlide(
      title: 'Message Before Matching',
      subtitle: 'Send a note to stand out from the crowd',
    ),
    _PlatinumSlide(
      title: 'Unlimited Swipes',
      subtitle: 'Keep discovering without limits',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 90,
          child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final s = _slides[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      s.title,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.subtitle,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _page;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: active
                    ? AppColors.textPrimary
                    : const Color(0xFFD1D1D6),
              ),
            );
          }),
        ),
        const SizedBox(height: 20),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            elevation: 1,
            shadowColor: Colors.black12,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text(
                    'GET SKILLDER PLATINUM™',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatinumSlide {
  final String title;
  final String subtitle;
  const _PlatinumSlide({required this.title, required this.subtitle});
}
