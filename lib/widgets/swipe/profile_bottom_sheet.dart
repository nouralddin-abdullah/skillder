import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/dummy_user.dart';
import '../../theme/app_colors.dart';
import 'photo_indicator.dart';
import 'skill_match_chip.dart';

enum ProfileViewMode { swipe, chat }

const Color _kPageBg = Color(0xFFF2F2F7);

class ProfileScreen extends StatefulWidget {
  final DummyUser user;
  final ProfileViewMode mode;
  final VoidCallback? onPass;
  final VoidCallback? onSuperPitch;
  final VoidCallback? onLike;

  const ProfileScreen({
    super.key,
    required this.user,
    required this.mode,
    this.onPass,
    this.onSuperPitch,
    this.onLike,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PageController _photoController = PageController();
  int _currentPhoto = 0;

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

  bool get _isChatMode => widget.mode == ProfileViewMode.chat;
  bool get _isSwipeMode => widget.mode == ProfileViewMode.swipe;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final actionBarHeight = _isSwipeMode ? 90.0 : 0.0;

    return Scaffold(
      backgroundColor: _kPageBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Sticky header ──
              SliverAppBar(
                pinned: true,
                elevation: 0,
                scrolledUnderElevation: 0.5,
                surfaceTintColor: Colors.white,
                backgroundColor: Colors.white,
                automaticallyImplyLeading: false,
                titleSpacing: 20,
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      widget.user.firstName,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.user.age}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.textPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Content ──
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  12,
                  12,
                  actionBarHeight + bottomInset + 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _photoCard(),
                    const SizedBox(height: 10),
                    _headlineCard(),
                    const SizedBox(height: 10),
                    _aboutCard(),
                    const SizedBox(height: 10),
                    _intentCard(),
                    const SizedBox(height: 10),
                    _essentialsCard(),
                    const SizedBox(height: 10),
                    _skillsCard(
                      title: 'I can teach',
                      icon: Icons.school_outlined,
                      skills: widget.user.giveSkills,
                      matchAgainstCurrentUser: true,
                    ),
                    const SizedBox(height: 10),
                    _skillsCard(
                      title: 'I want to learn',
                      icon: Icons.menu_book_outlined,
                      skills: widget.user.getSkills,
                      matchAgainstCurrentUser: false,
                    ),
                    const SizedBox(height: 20),
                    _actionListCard(
                      'Share ${widget.user.firstName}\'s profile',
                      onTap: () => _placeholderAction('Share profile'),
                    ),
                    const SizedBox(height: 10),
                    if (_isChatMode) ...[
                      _actionListCard(
                        'Unmatch ${widget.user.firstName}',
                        onTap: _showUnmatchConfirmation,
                      ),
                      const SizedBox(height: 10),
                    ],
                    _actionListCard(
                      'Block ${widget.user.firstName}',
                      onTap: _showBlockConfirmation,
                    ),
                    const SizedBox(height: 10),
                    _actionListCard(
                      'Report ${widget.user.firstName}',
                      isDanger: true,
                      onTap: () => _placeholderAction('Report'),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // ── Floating action buttons (swipe mode only) ──
          if (_isSwipeMode)
            Positioned(
              left: 0,
              right: 0,
              bottom: bottomInset + 16,
              child: _outlinedActionButtons(),
            ),
        ],
      ),
    );
  }

  // ── Cards ──

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }

  Widget _photoCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: Colors.white,
        height: 460,
        width: double.infinity,
        child: Stack(
          children: [
            PageView.builder(
              controller: _photoController,
              itemCount: widget.user.photos.length,
              onPageChanged: (i) => setState(() => _currentPhoto = i),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Image.network(
                  widget.user.photos[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, _, _) => Container(
                    color: const Color(0xFF2C2C2E),
                    child: const Center(
                      child: Icon(Icons.person_rounded,
                          size: 80, color: Colors.white30),
                    ),
                  ),
                );
              },
            ),
            Row(
              children: [
                Expanded(
                  flex: 30,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _goToPhoto(_currentPhoto - 1),
                  ),
                ),
                Expanded(
                  flex: 70,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _goToPhoto(_currentPhoto + 1),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: PhotoIndicator(
                count: widget.user.photos.length,
                current: _currentPhoto,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headlineCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.work_outline_rounded, 'Profession'),
          const SizedBox(height: 10),
          Text(
            widget.user.headline,
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _aboutCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.person_outline_rounded, 'About me'),
          const SizedBox(height: 10),
          Text(
            widget.user.bio,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _intentCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.search_rounded, 'Looking for'),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '🤝',
                style: GoogleFonts.inter(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                widget.user.intent,
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _essentialsCard() {
    return _card(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(Icons.local_offer_outlined, 'Essentials'),
          const SizedBox(height: 14),
          _essentialRow(Icons.location_on_outlined, widget.user.location),
          const Divider(color: AppColors.divider, height: 24),
          _essentialRow(
              Icons.translate_rounded, widget.user.languages.join(', ')),
        ],
      ),
    );
  }

  Widget _essentialRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillsCard({
    required String title,
    required IconData icon,
    required List<String> skills,
    required bool matchAgainstCurrentUser,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(icon, title),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: skills.map((skill) {
              return SkillMatchChip(
                label: skill,
                isMatch: matchAgainstCurrentUser &&
                    currentUserGetSkills.contains(skill),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _cardHeader(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _actionListCard(
    String label, {
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDanger ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ── Outlined action buttons (swipe mode) ──

  Widget _outlinedActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          icon: Icons.close_rounded,
          iconColor: const Color(0xFFFF3B5C),
          size: 60,
          iconSize: 32,
          onTap: () {
            Navigator.pop(context);
            widget.onPass?.call();
          },
        ),
        const SizedBox(width: 20),
        _circleButton(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFF4FC3F7),
          size: 48,
          iconSize: 24,
          onTap: () {
            Navigator.pop(context);
            widget.onSuperPitch?.call();
          },
        ),
        const SizedBox(width: 20),
        _circleButton(
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFF2DDB6E),
          size: 60,
          iconSize: 30,
          onTap: () {
            Navigator.pop(context);
            widget.onLike?.call();
          },
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color iconColor,
    required double size,
    required double iconSize,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }

  void _placeholderAction(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — coming soon'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showBlockConfirmation() {
    _showConfirmDialog(
      title: 'Block ${widget.user.firstName}?',
      description:
          "You won\u2019t be able to undo this. Are you sure you want to continue?",
      confirmLabel: 'Yes, block',
      cancelLabel: "No, don't block",
      onConfirm: () {
        Navigator.pop(context);
        _placeholderAction('Blocked ${widget.user.firstName}');
      },
    );
  }

  void _showUnmatchConfirmation() {
    _showConfirmDialog(
      title: 'Unmatch ${widget.user.firstName}?',
      description:
          "They will be removed from your matches and you won\u2019t be able to chat with them anymore.",
      confirmLabel: 'Yes, unmatch',
      cancelLabel: "No, don't unmatch",
      onConfirm: () {
        Navigator.pop(context);
        _placeholderAction('Unmatched ${widget.user.firstName}');
      },
    );
  }

  void _showConfirmDialog({
    required String title,
    required String description,
    required String confirmLabel,
    required String cancelLabel,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: const Icon(Icons.close_rounded,
                      color: AppColors.textPrimary, size: 24),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Text(
                  cancelLabel,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
