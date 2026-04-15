import 'package:flutter/material.dart';

class ExploreCard {
  final String title;
  final String image; // asset path (starts with 'assets/') or http(s) URL
  final String? ctaLabel;
  final Color tint;
  final bool fullWidth;

  const ExploreCard({
    required this.title,
    required this.image,
    this.ctaLabel,
    this.tint = const Color(0x00000000),
    this.fullWidth = false,
  });

  bool get isAsset => !image.startsWith('http');
}

class ExploreSection {
  final String title;
  final String description;
  final List<ExploreCard> cards;

  const ExploreSection({
    required this.title,
    required this.description,
    required this.cards,
  });
}

class ExploreHero {
  final String title;
  final String image;
  final Color tint;

  const ExploreHero({
    required this.title,
    required this.image,
    this.tint = const Color(0xAA8B1A2B),
  });

  bool get isAsset => !image.startsWith('http');
}

// ─────────────────────────────── Dummy data ───────────────────────────────

const ExploreHero dummyExploreHero = ExploreHero(
  title: 'Short-term fun',
  image:
      'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=1200',
  tint: Color(0x998B1A2B),
);

const List<ExploreSection> dummyExploreSections = [
  ExploreSection(
    title: 'Goal-driven dating',
    description: 'Find people with similar relationship goals',
    cards: [
      ExploreCard(
        title: 'Serious Daters',
        image:
            'https://images.unsplash.com/photo-1521119989659-a83eee488004?w=800',
        tint: Color(0x884A1F10),
      ),
      ExploreCard(
        title: 'Long-term partner',
        image:
            'https://images.unsplash.com/photo-1529634597503-139d3726fed5?w=800',
        tint: Color(0x886A2410),
      ),
      ExploreCard(
        title: 'Just Exploring',
        image: 'assets/images/explore/image-1.png',
        tint: Color(0x883B2B6B),
      ),
      ExploreCard(
        title: 'Casual Dating',
        image: 'assets/images/explore/image-2.png',
        tint: Color(0x885B2A4B),
      ),
    ],
  ),
  ExploreSection(
    title: 'Similar plans and lifestyles',
    description: 'Find people with similar life goals',
    cards: [
      ExploreCard(
        title: 'Wants Kids',
        image:
            'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=1200',
        ctaLabel: 'TRY NOW',
        tint: Color(0x992C5E3A),
        fullWidth: true,
      ),
    ],
  ),
  ExploreSection(
    title: 'Shared interests or hobbies',
    description: 'Find people with similar interests',
    cards: [
      ExploreCard(
        title: 'Binge Watchers',
        image: 'assets/images/explore/image-3.png',
        tint: Color(0x88123B2E),
      ),
      ExploreCard(
        title: 'Music Lovers',
        image:
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800',
        tint: Color(0x883B1F4A),
      ),
      ExploreCard(
        title: 'Foodies',
        image:
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
        tint: Color(0x885A2C10),
      ),
      ExploreCard(
        title: 'Travelers',
        image:
            'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800',
        tint: Color(0x88123B5E),
      ),
      ExploreCard(
        title: 'Gym Rats',
        image:
            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=1200',
        tint: Color(0x99361218),
        fullWidth: true,
      ),
    ],
  ),
];
