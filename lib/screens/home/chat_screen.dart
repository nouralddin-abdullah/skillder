import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/dummy_chat.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat/safety_bottom_sheet.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  List<ChatMatch> get _filteredMatches => _query.isEmpty
      ? newMatches
      : newMatches
          .where((m) => m.name.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  List<ChatConversation> get _filteredConversations => _query.isEmpty
      ? conversations
      : conversations
          .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()) ||
              c.lastMessage.toLowerCase().contains(_query.toLowerCase()))
          .toList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSafetyToolkit() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SafetyBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredMatches = _filteredMatches;
    final filteredConvos = _filteredConversations;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: "Chat" + shield icon ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
            child: Row(
              children: [
                Text(
                  'Chat',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _openSafetyToolkit,
                  icon: const Icon(
                    Icons.shield_outlined,
                    color: AppColors.textSecondary,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Search bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Search ${newMatches.length} Matches',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textHint,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 14, right: 10),
                    child: Icon(
                      Icons.search_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: AppColors.textHint, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  filled: false,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── New Matches section ──
          if (filteredMatches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Text(
                'New Matches',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredMatches.length,
                itemBuilder: (context, index) {
                  final match = filteredMatches[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      right: index < filteredMatches.length - 1 ? 16 : 0,
                    ),
                    child: _MatchAvatar(match: match),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Messages section ──
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(
              'Messages',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Conversation list ──
          Expanded(
            child: filteredConvos.isEmpty
                ? Center(
                    child: Text(
                      'No results found',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.textHint,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filteredConvos.length,
                    separatorBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(left: 88),
                      child: Divider(
                        color: AppColors.divider,
                        height: 1,
                        thickness: 0.5,
                      ),
                    ),
                    itemBuilder: (context, index) {
                      final convo = filteredConvos[index];
                      return _ConversationTile(conversation: convo);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Match avatar in horizontal scroll ──
class _MatchAvatar extends StatelessWidget {
  final ChatMatch match;

  const _MatchAvatar({required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            contactName: match.name,
            contactPhotoUrl: match.photoUrl,
            isOnline: match.isOnline,
          ),
        ),
      ),
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGradient.colors.first,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(
                      child: Image.network(
                        match.photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.inputFill,
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.textHint,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (match.isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DDB6E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              match.name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Conversation tile ──
class _ConversationTile extends StatelessWidget {
  final ChatConversation conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            contactName: conversation.name,
            contactPhotoUrl: conversation.photoUrl,
            isOnline: conversation.isOnline,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Stack(
              children: [
                ClipOval(
                  child: Image.network(
                    conversation.photoUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: AppColors.inputFill,
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.textHint,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2DDB6E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: conversation.isUnread
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: conversation.isUnread
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: conversation.isUnread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.timeAgo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: conversation.isUnread
                        ? AppColors.primary
                        : AppColors.textHint,
                    fontWeight: conversation.isUnread
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                if (conversation.isUnread) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
