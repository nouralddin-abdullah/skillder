import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/dummy_user.dart';
import '../../services/api_exception.dart';
import '../../services/user_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/swipe/swipe_card.dart';
import 'answer_prompt_screen.dart';
import 'basics_sheet.dart';
import 'edit_intent_screen.dart';
import 'edit_skills_screen.dart';
import 'select_prompt_screen.dart';

const Map<String, ({String emoji, String label})> _intentMeta = {
  'swap': (emoji: '🔄', label: 'Skill Swap'),
  'colearn': (emoji: '🤝', label: 'Co-Learning'),
  'mentor': (emoji: '🎓', label: 'Mentorship'),
};

class EditProfileScreen extends StatefulWidget {
  final String? scrollTo;
  final ({String prompt, String answer})? initialPrompt;

  /// Profile from `GET /users/me` used to hydrate every field. Required —
  /// the parent (`ProfileTab`) fetches it before pushing this screen.
  final Map<String, dynamic> initialProfile;

  const EditProfileScreen({
    super.key,
    required this.initialProfile,
    this.scrollTo,
    this.initialPrompt,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _PromptEntry {
  final String prompt;
  final String answer;
  const _PromptEntry({required this.prompt, required this.answer});
}

/// A photo entry. Server-side photos always have an [id]; freshly picked
/// photos may not (until upload completes).
class _Photo {
  final String? id;
  final String? url;
  final String? filePath;
  final Uint8List? bytes;
  final bool uploading;
  const _Photo({
    this.id,
    this.url,
    this.filePath,
    this.bytes,
    this.uploading = false,
  });
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  int _tab = 0;

  final List<_Photo?> _photos = List<_Photo?>.filled(9, null, growable: false);
  final ImagePicker _picker = ImagePicker();
  final GlobalKey _aboutMeKey = GlobalKey();
  final GlobalKey _promptsKey = GlobalKey();
  final ScrollController _scrollController = ScrollController();

  static const int _maxAboutChars = 500;
  static const int _maxPrompts = 3;

  final TextEditingController _aboutController = TextEditingController();
  Timer? _bioDebounce;

  final List<_PromptEntry> _prompts = [];

  List<String> _giveSkills = [];
  List<String> _getSkills = [];

  Set<String> _intents = {};

  String? _education;
  String? _careerStage;
  String? _domain;
  String? _workStyle;

  static const List<String> _educationOptions = [
    'High School',
    'In College',
    'Bachelors',
    'In Grad School',
    'Masters',
    'PhD',
    'Trade School',
  ];
  static const List<String> _careerOptions = [
    'Student',
    'Intern',
    'Junior',
    'Mid-level',
    'Senior',
    'Lead',
    'Manager',
    'Founder',
  ];
  static const List<String> _domainOptions = [
    'Technology',
    'Finance',
    'HR',
    'Marketing',
    'Design',
    'Healthcare',
    'Education',
    'Legal',
    'Sales',
    'Operations',
  ];
  static const List<String> _workStyleOptions = ['Remote', 'Office', 'Hybrid'];

  String? _fuelSource;
  String? _focusSoundtrack;
  String? _rechargeMode;

  static const List<String> _fuelOptions = [
    'Coffee',
    'Matcha',
    'Tea',
    'Energy Drinks',
    'Photosynthesizing',
  ];
  static const List<String> _focusOptions = [
    'Lofi Beats',
    'Silence',
    'Heavy Metal',
    'Spotify Random',
  ];
  static const List<String> _rechargeOptions = [
    'Cozy Gaming',
    'Gym',
    'Touching Grass',
    'Reading',
    'Sleeping',
  ];

  /// Send a partial PATCH to /users/me. Surfaces failures via snackbar so
  /// the user sees them, but doesn't roll back local state — the user can
  /// retry by changing the field again.
  Future<void> _patch(Map<String, dynamic> fields) async {
    try {
      await UserService.patchMe(fields);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error. Try again.')),
      );
    }
  }

  Future<void> _pickBasic({
    required IconData icon,
    required String question,
    required List<String> options,
    required String? current,
    required ValueChanged<String> onPicked,
    required String fieldName,
  }) async {
    final result = await showBasicsSheet(
      context: context,
      icon: icon,
      question: question,
      options: options,
      initial: current,
    );
    if (result == null || !mounted) return;
    setState(() => onPicked(result));
    _patch({fieldName: result});
  }

  Future<void> _editIntent() async {
    final result = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute(
        builder: (_) => EditIntentScreen(initialIntents: _intents),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _intents = result);
    _patch({'intents': result.toList()});
  }

  Future<void> _editSkills({required bool isGive}) async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(
        builder: (_) => EditSkillsScreen(
          title: isGive ? 'Your Give' : 'Your Get',
          subtitle: isGive
              ? 'Skills you can teach others'
              : 'Skills you want to learn',
          initialSkills: (isGive ? _giveSkills : _getSkills).toSet(),
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (isGive) {
        _giveSkills = result;
      } else {
        _getSkills = result;
      }
    });
    _patch({isGive ? 'giveSkills' : 'getSkills': result});
  }

  Future<void> _pickPhoto(int index) async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    // Show optimistic local placeholder while uploading.
    Uint8List? bytes;
    String? filePath;
    if (kIsWeb) {
      bytes = await picked.readAsBytes();
    } else {
      filePath = picked.path;
    }

    if (!mounted) return;
    setState(() => _photos[index] = _Photo(
          bytes: bytes,
          filePath: filePath,
          uploading: true,
        ));

    try {
      final result = await UserService.uploadPhoto(
        filePath: filePath,
        bytes: bytes,
        filename: kIsWeb ? 'photo.jpg' : picked.name,
      );
      if (!mounted) return;
      setState(() => _photos[index] = _Photo(
            id: result['id'] as String?,
            url: result['url'] as String?,
          ));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _photos[index] = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message}')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _photos[index] = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Network error during upload')),
      );
    }
  }

  Future<void> _removePhoto(int index) async {
    final photo = _photos[index];
    if (photo == null) return;

    // Optimistic local removal.
    setState(() {
      for (int i = index; i < _photos.length - 1; i++) {
        _photos[i] = _photos[i + 1];
      }
      _photos[_photos.length - 1] = null;
    });

    if (photo.id == null) return; // never made it to the server
    try {
      await UserService.deletePhoto(photo.id!);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    final p = widget.initialProfile;

    // Photos
    final photos = p['photos'];
    if (photos is List) {
      for (int i = 0; i < photos.length && i < _photos.length; i++) {
        final ph = photos[i];
        if (ph is Map<String, dynamic>) {
          _photos[i] = _Photo(
            id: ph['id'] as String?,
            url: ph['url'] as String?,
          );
        }
      }
    }

    // About me
    final bio = p['bio'];
    if (bio is String) _aboutController.text = bio;

    // Prompts
    final prompts = p['prompts'];
    if (prompts is List) {
      for (final pr in prompts) {
        if (pr is Map<String, dynamic>) {
          _prompts.add(_PromptEntry(
            prompt: pr['prompt']?.toString() ?? '',
            answer: pr['answer']?.toString() ?? '',
          ));
        }
      }
    }

    // Skills, intent
    final give = p['giveSkills'];
    if (give is List) _giveSkills = give.cast<String>();
    final get = p['getSkills'];
    if (get is List) _getSkills = get.cast<String>();
    final intents = p['intents'];
    if (intents is List) _intents = intents.cast<String>().toSet();

    // Basics + lifestyle
    _education = p['education'] as String?;
    _careerStage = p['careerStage'] as String?;
    _domain = p['domain'] as String?;
    _workStyle = p['workStyle'] as String?;
    _fuelSource = p['fuelSource'] as String?;
    _focusSoundtrack = p['focusSoundtrack'] as String?;
    _rechargeMode = p['rechargeMode'] as String?;

    _aboutController.addListener(() {
      setState(() {});
      _bioDebounce?.cancel();
      _bioDebounce = Timer(const Duration(milliseconds: 700), () {
        _patch({'bio': _aboutController.text});
      });
    });

    if (widget.initialPrompt != null) {
      _prompts.add(_PromptEntry(
        prompt: widget.initialPrompt!.prompt,
        answer: widget.initialPrompt!.answer,
      ));
    }

    if (widget.scrollTo == 'aboutMe' || widget.scrollTo == 'prompts') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = widget.scrollTo == 'aboutMe' ? _aboutMeKey : _promptsKey;
        final ctx = key.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: Duration.zero);
        }
      });
    }
  }

  @override
  void dispose() {
    _bioDebounce?.cancel();
    _aboutController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addPrompt() async {
    if (_prompts.length >= _maxPrompts) return;
    final used = _prompts.map((p) => p.prompt).toSet();
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => SelectPromptScreen(usedPrompts: used),
      ),
    );
    if (selected == null || !mounted) return;
    final result = await Navigator.of(context).push<({String prompt, String answer})>(
      MaterialPageRoute(
        builder: (_) => AnswerPromptScreen(
          prompt: selected,
          usedPrompts: used,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _prompts.add(
          _PromptEntry(prompt: result.prompt, answer: result.answer),
        ));
    _patchPrompts();
  }

  Future<void> _editPrompt(int index) async {
    final used = _prompts
        .asMap()
        .entries
        .where((e) => e.key != index)
        .map((e) => e.value.prompt)
        .toSet();
    final entry = _prompts[index];
    final result = await Navigator.of(context).push<({String prompt, String answer})>(
      MaterialPageRoute(
        builder: (_) => AnswerPromptScreen(
          prompt: entry.prompt,
          initialAnswer: entry.answer,
          usedPrompts: used,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() => _prompts[index] =
        _PromptEntry(prompt: result.prompt, answer: result.answer));
    _patchPrompts();
  }

  void _removePrompt(int index) {
    setState(() => _prompts.removeAt(index));
    _patchPrompts();
  }

  void _patchPrompts() {
    _patch({
      'prompts': _prompts
          .map((p) => {'prompt': p.prompt, 'answer': p.answer})
          .toList(),
    });
  }

  /// Drag-and-drop reorder. If `to` is empty, simple move. If `to` is filled,
  /// pull `from` out and insert it at `to`'s position, shifting others.
  Future<void> _reorder(int from, int to) async {
    if (from == to) return;
    final moving = _photos[from];
    if (moving == null) return;

    setState(() {
      final list = List<_Photo?>.from(_photos);
      list.removeAt(from);
      list.insert(to, moving);
      final filled = list.where((p) => p != null).toList();
      while (filled.length < 9) {
        filled.add(null);
      }
      for (int i = 0; i < 9; i++) {
        _photos[i] = filled[i];
      }
    });

    // Push the new order to the server using the photo IDs.
    final orderedIds = <String>[];
    for (final p in _photos) {
      if (p != null && p.id != null) orderedIds.add(p.id!);
    }
    if (orderedIds.length < 2) return;

    try {
      await UserService.reorderPhotos(orderedIds);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reorder failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leadingWidth: 56,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          'Edit profile',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [SizedBox(width: 56)],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: _tab == 0
                ? SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Media',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add up to 9 photos. Use prompts to share your '
                          'personality, workspace or projects.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Stand out with our photo tips',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildGrid(),
                        const SizedBox(height: 32),
                        _buildAboutMe(),
                        const SizedBox(height: 28),
                        _buildPromptsSection(),
                        const SizedBox(height: 28),
                        _buildInterestsSection(),
                        const SizedBox(height: 28),
                        _buildIntentSection(),
                        const SizedBox(height: 28),
                        _buildBasicsSection(),
                        const SizedBox(height: 28),
                        _buildLifestyleSection(),
                      ],
                    ),
                  )
                : _buildPreview(),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPreview() {
    // Photo URLs the SwipeCard can render. Local-only photos (just picked,
    // not yet uploaded) are skipped — they appear once the upload finishes.
    final photoUrls = <String>[];
    for (final p in _photos) {
      if (p?.url != null) photoUrls.add(p!.url!);
    }

    final me = widget.initialProfile;
    final name = (me['name'] as String?)?.split(' ').first ?? 'You';
    final age = me['age'] is int ? me['age'] as int : 0;

    final previewUser = DummyUser(
      firstName: name,
      age: age,
      headline: (me['headline'] as String?) ?? '',
      bio: _aboutController.text,
      location: '',
      languages: const [],
      photos: photoUrls,
      giveSkills: _giveSkills,
      getSkills: _getSkills,
      intents: _intents.toList(),
      prompts: _prompts
          .map((p) => DummyPrompt(prompt: p.prompt, answer: p.answer))
          .toList(),
      education: _education,
      careerStage: _careerStage,
      domain: _domain,
      workStyle: _workStyle,
      fuelSource: _fuelSource,
      focusSoundtrack: _focusSoundtrack,
      rechargeMode: _rechargeMode,
    );

    if (photoUrls.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Add at least one photo to preview your card.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    // Lock the card to a 9:16 portrait ratio (same proportion as the swipe
    // deck) so photos render with their intended composition. Aligned to top
    // so the card sits flush under the tabs instead of vertically centered.
    return Align(
      alignment: Alignment.topCenter,
      child: AspectRatio(
        aspectRatio: 9 / 16,
        child: SwipeCard(
          user: previewUser,
          showActions: false,
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _TabItem(
            label: 'Edit',
            active: _tab == 0,
            onTap: () => setState(() => _tab = 0),
          ),
          _TabItem(
            label: 'Preview',
            active: _tab == 1,
            onTap: () => setState(() => _tab = 1),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 9,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (_, i) => _PhotoCell(
        index: i,
        photo: _photos[i],
        onPick: () => _pickPhoto(i),
        onRemove: () => _removePhoto(i),
        onReorder: _reorder,
      ),
    );
  }

  // ── About Me ──
  Widget _buildAboutMe() {
    final count = _aboutController.text.characters.length;
    final remaining = _maxAboutChars - count;
    return Column(
      key: _aboutMeKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('About Me'),
        const SizedBox(height: 10),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _aboutController,
                maxLength: _maxAboutChars,
                minLines: 3,
                maxLines: 6,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Write something about yourself...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.textHint,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$remaining',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {},
          child: Text(
            "Quick 'About Me' tips",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ── Prompts ──
  Widget _buildPromptsSection() {
    return Column(
      key: _promptsKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Prompts'),
        const SizedBox(height: 10),
        for (int i = 0; i < _prompts.length; i++) ...[
          _PromptCard(
            entry: _prompts[i],
            onTap: () => _editPrompt(i),
            onRemove: () => _removePrompt(i),
          ),
          const SizedBox(height: 10),
        ],
        if (_prompts.length < _maxPrompts)
          _AddPromptCard(onTap: _addPrompt),
      ],
    );
  }

  // ── Skills (Give / Get) ──
  Widget _buildInterestsSection() {
    String join(List<String> list) =>
        list.isEmpty ? 'Add skills' : list.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Skills'),
        const SizedBox(height: 10),
        _InterestRow(
          label: 'Give',
          value: join(_giveSkills),
          onTap: () => _editSkills(isGive: true),
        ),
        const SizedBox(height: 10),
        _InterestRow(
          label: 'Get',
          value: join(_getSkills),
          onTap: () => _editSkills(isGive: false),
        ),
      ],
    );
  }

  // ── Basics ──
  Widget _buildBasicsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Basics'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _BasicsRow(
                icon: Icons.school_outlined,
                label: 'Education',
                value: _education,
                onTap: () => _pickBasic(
                  icon: Icons.school_outlined,
                  question: 'What is your education level?',
                  options: _educationOptions,
                  current: _education,
                  onPicked: (v) => _education = v,
                  fieldName: 'education',
                ),
              ),
              const _BasicsDivider(),
              _BasicsRow(
                icon: Icons.work_outline_rounded,
                label: 'Career Stage',
                value: _careerStage,
                onTap: () => _pickBasic(
                  icon: Icons.work_outline_rounded,
                  question: 'What stage are you at in your career?',
                  options: _careerOptions,
                  current: _careerStage,
                  onPicked: (v) => _careerStage = v,
                  fieldName: 'careerStage',
                ),
              ),
              const _BasicsDivider(),
              _BasicsRow(
                icon: Icons.business_center_outlined,
                label: 'Domain',
                value: _domain,
                onTap: () => _pickBasic(
                  icon: Icons.business_center_outlined,
                  question: 'Which domain do you work in?',
                  options: _domainOptions,
                  current: _domain,
                  onPicked: (v) => _domain = v,
                  fieldName: 'domain',
                ),
              ),
              const _BasicsDivider(),
              _BasicsRow(
                icon: Icons.laptop_mac_outlined,
                label: 'Work Style',
                value: _workStyle,
                onTap: () => _pickBasic(
                  icon: Icons.laptop_mac_outlined,
                  question: 'How do you prefer to work?',
                  options: _workStyleOptions,
                  current: _workStyle,
                  onPicked: (v) => _workStyle = v,
                  fieldName: 'workStyle',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Lifestyle ──
  Widget _buildLifestyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Lifestyle'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _BasicsRow(
                icon: Icons.local_cafe_outlined,
                label: 'Fuel Source',
                value: _fuelSource,
                onTap: () => _pickBasic(
                  icon: Icons.local_cafe_outlined,
                  question: 'What fuels your day?',
                  options: _fuelOptions,
                  current: _fuelSource,
                  onPicked: (v) => _fuelSource = v,
                  fieldName: 'fuelSource',
                ),
              ),
              const _BasicsDivider(),
              _BasicsRow(
                icon: Icons.headphones_outlined,
                label: 'Focus Soundtrack',
                value: _focusSoundtrack,
                onTap: () => _pickBasic(
                  icon: Icons.headphones_outlined,
                  question: 'What do you listen to while focusing?',
                  options: _focusOptions,
                  current: _focusSoundtrack,
                  onPicked: (v) => _focusSoundtrack = v,
                  fieldName: 'focusSoundtrack',
                ),
              ),
              const _BasicsDivider(),
              _BasicsRow(
                icon: Icons.battery_charging_full_rounded,
                label: 'Recharge Mode',
                value: _rechargeMode,
                onTap: () => _pickBasic(
                  icon: Icons.battery_charging_full_rounded,
                  question: 'How do you recharge?',
                  options: _rechargeOptions,
                  current: _rechargeMode,
                  onPicked: (v) => _rechargeMode = v,
                  fieldName: 'rechargeMode',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Intent ──
  Widget _buildIntentSection() {
    final selected = _intents
        .where(_intentMeta.containsKey)
        .map((k) => _intentMeta[k]!)
        .toList();

    final String displayText;
    final String displayEmoji;
    if (selected.isEmpty) {
      displayText = 'Add intent';
      displayEmoji = '';
    } else if (selected.length == 1) {
      displayText = selected.first.label;
      displayEmoji = selected.first.emoji;
    } else {
      displayText =
          '${selected.first.label} +${selected.length - 1}';
      displayEmoji = selected.first.emoji;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Intent'),
        const SizedBox(height: 10),
        InkWell(
          onTap: _editIntent,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('👁', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(
                  'Looking for...',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                if (displayEmoji.isNotEmpty) ...[
                  Text(displayEmoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    displayText,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      );
}

// ─────────────────────────── Prompt card ───────────────────────────

class _PromptCard extends StatelessWidget {
  final _PromptEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PromptCard({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '\u201C',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.prompt,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                  ],
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.only(left: 22),
                  child: Text(
                    entry.answer,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE5E5EA),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Add prompt card ───────────────────────────

class _AddPromptCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPromptCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: const Color(0xFFBDBDC7),
              radius: 12,
              strokeWidth: 1.5,
              dashLength: 5,
              gapLength: 4,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select a prompt',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Answer prompt',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Interest row ───────────────────────────

class _InterestRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _InterestRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Basics row ───────────────────────────

class _BasicsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  const _BasicsRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.textSecondary),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              value ?? 'Empty',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: value == null
                    ? AppColors.textHint
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _BasicsDivider extends StatelessWidget {
  const _BasicsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      color: Color(0xFFE5E5EA),
      indent: 16,
      endIndent: 16,
    );
  }
}

// ─────────────────────────── Tab item ───────────────────────────

class _TabItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabItem({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: active ? AppColors.textPrimary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Photo cell (drag + drop) ───────────────────────────

class _PhotoCell extends StatelessWidget {
  final int index;
  final _Photo? photo;
  final VoidCallback onPick;
  final VoidCallback onRemove;
  final void Function(int from, int to) onReorder;

  const _PhotoCell({
    required this.index,
    required this.photo,
    required this.onPick,
    required this.onRemove,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != index,
      onAcceptWithDetails: (d) => onReorder(d.data, index),
      builder: (context, candidate, rejected) {
        final isHovered = candidate.isNotEmpty;
        final cell = photo == null
            ? _EmptyPhotoSlot(onTap: onPick, highlighted: isHovered)
            : _FilledPhotoSlot(photo: photo!, onRemove: onRemove);

        if (photo == null) return cell;

        return LongPressDraggable<int>(
          data: index,
          delay: const Duration(milliseconds: 200),
          feedback: _DragFeedback(photo: photo!),
          childWhenDragging: Opacity(opacity: 0.25, child: cell),
          child: cell,
        );
      },
    );
  }
}

class _DragFeedback extends StatelessWidget {
  final _Photo photo;
  const _DragFeedback({required this.photo});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final cellW = (w - 32 - 20) / 3; // page padding 16*2 + 2 gaps of 10
    return Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.08,
        child: SizedBox(
          width: cellW,
          height: cellW / 0.72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _photoImage(photo),
          ),
        ),
      ),
    );
  }
}

Widget _photoImage(_Photo photo) {
  if (photo.bytes != null) {
    return Image.memory(photo.bytes!, fit: BoxFit.cover);
  }
  if (photo.filePath != null) {
    return Image.file(File(photo.filePath!), fit: BoxFit.cover);
  }
  return Image.network(
    photo.url!,
    fit: BoxFit.cover,
    errorBuilder: (_, _, _) => Container(color: const Color(0xFFE5E5EA)),
  );
}

// ─────────────────────────── Filled / empty slots ───────────────────────────

class _FilledPhotoSlot extends StatelessWidget {
  final _Photo photo;
  final VoidCallback onRemove;

  const _FilledPhotoSlot({required this.photo, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _photoImage(photo),
          ),
        ),
        if (photo.uploading)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (!photo.uploading)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyPhotoSlot extends StatelessWidget {
  final VoidCallback onTap;
  final bool highlighted;
  const _EmptyPhotoSlot({required this.onTap, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: highlighted
              ? AppColors.primary
              : const Color(0xFFD1D1D6),
          radius: 10,
          strokeWidth: highlighted ? 2 : 1.5,
          dashLength: 5,
          gapLength: 4,
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            size: 28,
            color: highlighted
                ? AppColors.primary
                : const Color(0xFFBDBDC7),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Dashed border painter ───────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}
