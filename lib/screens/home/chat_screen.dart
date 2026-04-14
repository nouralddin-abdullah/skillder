import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/dummy_chat.dart';
import '../../theme/app_colors.dart';
import '../../widgets/chat/safety_bottom_sheet.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  void _openSafetyToolkit(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SafetyBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () => _openSafetyToolkit(context),
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
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(
                    Icons.search_rounded,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Search ${newMatches.length} Matches',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── New Matches section ──
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
              itemCount: newMatches.length,
              itemBuilder: (context, index) {
                final match = newMatches[index];
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < newMatches.length - 1 ? 16 : 0,
                  ),
                  child: _MatchAvatar(match: match),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

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
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              itemCount: conversations.length,
              separatorBuilder: (context, index) => Padding(
                padding: const EdgeInsets.only(left: 88),
                child: Divider(
                  color: AppColors.divider,
                  height: 1,
                  thickness: 0.5,
                ),
              ),
              itemBuilder: (context, index) {
                final convo = conversations[index];
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
    return SizedBox(
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
              // Online indicator
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
      onTap: () => print('Open chat with ${conversation.name}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Avatar with online dot
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

            // Name + last message
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

            // Time + unread dot
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
