import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/explore_section.dart';
import '../../theme/app_colors.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  static const double _hPad = 10;
  static const double _gap = 10;
  static const double _cardRadius = 16;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildHero(dummyExploreHero)),
            for (final section in dummyExploreSections)
              ..._buildSection(section),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  // ─── Header ───
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(_hPad, 12, _hPad, 16),
      child: Text(
        'Explore',
        style: GoogleFonts.inter(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  // ─── Hero ───
  Widget _buildHero(ExploreHero hero) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _hPad),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: _CardSurface(
          image: hero.image,
          tint: hero.tint,
          title: hero.title,
          titleFontSize: 28,
        ),
      ),
    );
  }

  // ─── Section ───
  List<Widget> _buildSection(ExploreSection section) {
    // Split: half-width first (in pairs), full-width at end.
    final half = section.cards.where((c) => !c.fullWidth).toList();
    final full = section.cards.where((c) => c.fullWidth).toList();

    final rows = <Widget>[];

    // Pair half-width cards
    for (int i = 0; i < half.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(left: _hPad, right: _hPad, bottom: _gap),
          child: Row(
            children: [
              Expanded(
                child: AspectRatio(
                  aspectRatio: 0.68,
                  child: _CardSurface(
                    image: half[i].image,
                    tint: half[i].tint,
                    title: half[i].title,
                    titleFontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: _gap),
              Expanded(
                child: i + 1 < half.length
                    ? AspectRatio(
                        aspectRatio: 0.68,
                        child: _CardSurface(
                          image: half[i + 1].image,
                          tint: half[i + 1].tint,
                          title: half[i + 1].title,
                          titleFontSize: 18,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    // Full-width cards (one per row)
    for (final card in full) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(
            left: _hPad,
            right: _hPad,
            bottom: _gap,
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _CardSurface(
              image: card.image,
              tint: card.tint,
              title: card.title,
              titleFontSize: 24,
              ctaLabel: card.ctaLabel,
            ),
          ),
        ),
      );
    }

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_hPad, 22, _hPad, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                section.title,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                section.description,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      SliverList(delegate: SliverChildListDelegate(rows)),
    ];
  }
}

// ─────────────────────────── Card surface ───────────────────────────

class _CardSurface extends StatelessWidget {
  final String image;
  final Color tint;
  final String title;
  final double titleFontSize;
  final String? ctaLabel;

  const _CardSurface({
    required this.image,
    required this.tint,
    required this.title,
    required this.titleFontSize,
    this.ctaLabel,
  });

  bool get _isAsset => !image.startsWith('http');

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(ExploreScreen._cardRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _isAsset
              ? Image.asset(image, fit: BoxFit.cover)
              : Image.network(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      Container(color: const Color(0xFF2C2C2E)),
                ),
          // Color tint overlay
          Container(color: tint),
          // Bottom shadow gradient for text legibility
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
          // Title + optional CTA
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                ),
                if (ctaLabel != null) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ctaLabel!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
