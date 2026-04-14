import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/dummy_user.dart';
import 'action_buttons.dart';
import 'photo_indicator.dart';
import 'profile_bottom_sheet.dart';
import 'skill_match_chip.dart';

class SwipeCard extends StatefulWidget {
  final DummyUser user;
  final VoidCallback onPass;
  final VoidCallback onSuperPitch;
  final VoidCallback onLike;

  const SwipeCard({
    super.key,
    required this.user,
    required this.onPass,
    required this.onSuperPitch,
    required this.onLike,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> {
  final PageController _photoController = PageController();
  int _currentPhoto = 0;

  // Bottom black zone height for buttons (15% ratio)
  static const double _buttonZoneHeight = 100;

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  void _goToPhoto(int index) {
    if (index < 0 || index >= widget.user.photos.length) return;
    _photoController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _openFullProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: ProfileBottomSheet(user: widget.user),
      ),
    );
  }

  Widget _buildDynamicContent() {
    switch (_currentPhoto) {
      case 1:
        return _buildSkillSection(
          'I can teach:',
          widget.user.giveSkills,
          matchAgainstCurrentUser: true,
        );
      case 2:
        return _buildSkillSection(
          'I want to learn:',
          widget.user.getSkills,
          matchAgainstCurrentUser: false,
        );
      default:
        return Text(
          widget.user.bio,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.5,
          ),
        );
    }
  }

  Widget _buildSkillSection(
    String title,
    List<String> skills, {
    required bool matchAgainstCurrentUser,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: skills.map((skill) {
            return SkillMatchChip(
              label: skill,
              isMatch: matchAgainstCurrentUser &&
                  currentUserGetSkills.contains(skill),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(
          top: Radius.zero,
          bottom: Radius.circular(16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Image: fills top ~80%, leaves bottom black zone ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: _buttonZoneHeight,
            child: PageView.builder(
              controller: _photoController,
              itemCount: widget.user.photos.length,
              onPageChanged: (index) =>
                  setState(() => _currentPhoto = index),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Image.network(
                  widget.user.photos[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF2C2C2E),
                      child: Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 80,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: const Color(0xFF2C2C2E),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white54),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ── Gradient: blends bottom of image into the black zone ──
          Positioned(
            left: 0,
            right: 0,
            bottom: _buttonZoneHeight - 1, // overlap by 1px to avoid seam
            height: 200,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Tap zones for photo navigation (over image area only) ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: _buttonZoneHeight,
            child: Row(
              children: [
                Expanded(
                  flex: 30,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _goToPhoto(_currentPhoto - 1),
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  flex: 70,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _goToPhoto(_currentPhoto + 1),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),

          // ── Photo progress dashes ──
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: PhotoIndicator(
              count: widget.user.photos.length,
              current: _currentPhoto,
            ),
          ),

          // ── Text overlay: sits in gradient zone above the buttons ──
          Positioned(
            left: 18,
            right: 18,
            bottom: _buttonZoneHeight + 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name, Age, expand button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            widget.user.firstName,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.user.age}',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _openFullProfile,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.7),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),

                // Headline
                Row(
                  children: [
                    Icon(
                      Icons.work_outline_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.user.headline,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dynamic content (bio / skills)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: KeyedSubtree(
                    key: ValueKey(_currentPhoto),
                    child: _buildDynamicContent(),
                  ),
                ),
              ],
            ),
          ),

          // ── Action buttons: in the solid black bottom zone ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SwipeActionButtons(
              onPass: widget.onPass,
              onSuperPitch: widget.onSuperPitch,
              onLike: widget.onLike,
            ),
          ),
        ],
      ),
    );
  }
}
