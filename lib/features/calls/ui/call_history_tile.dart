import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/chat_models.dart';
import '../../../theme/app_colors.dart';
import '../models/call_models.dart';

/// Renders a system-kind message representing a call event as a centered,
/// inline tile. Reads everything from `systemPayload` (always set by the
/// backend per the call.create flow) — no body-string sniffing.
class CallHistoryTile extends StatelessWidget {
  final MessageEntity message;
  final bool mine;

  /// Called when the tile is tapped. Receives the inferred [CallKind] so
  /// the caller can dial the right kind of call back.
  final void Function(CallKind kind)? onCallBack;

  const CallHistoryTile({
    super.key,
    required this.message,
    required this.mine,
    this.onCallBack,
  });

  /// True iff this message is a call record. Used by the chat-detail
  /// filter to decide whether to render this tile vs. fall through to
  /// the regular bubble path.
  static bool isCallRecord(MessageEntity m) =>
      m.isSystem && m.systemPayload?['kind'] == 'call';

  @override
  Widget build(BuildContext context) {
    final view = _resolve();
    return Center(
      child: GestureDetector(
        onTap: onCallBack == null ? null : () => onCallBack!(view.kind),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(view.icon, size: 16, color: view.iconColor),
              const SizedBox(width: 8),
              Text(
                view.label,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CallTileView _resolve() {
    final p = message.systemPayload ?? const <String, dynamic>{};
    final callKind =
        p['callKind']?.toString() == 'video' ? CallKind.video : CallKind.voice;
    final endReason = p['endReason']?.toString();
    final dur = (p['durationSeconds'] as num?)?.toInt();
    final missed = endReason == 'missed' ||
        endReason == 'cancelled' ||
        endReason == 'rejected';
    final isVideo = callKind == CallKind.video;

    String label;
    if (endReason == 'missed' || endReason == 'cancelled') {
      label = isVideo ? 'Missed video call' : 'Missed call';
    } else if (endReason == 'rejected') {
      label = 'Call declined';
    } else if (dur != null && dur > 0) {
      final m = (dur ~/ 60).toString().padLeft(2, '0');
      final s = (dur % 60).toString().padLeft(2, '0');
      label = isVideo ? '🎥 Video call · $m:$s' : '📞 Voice call · $m:$s';
    } else {
      label = isVideo ? 'Video call' : 'Voice call';
    }

    return _CallTileView(
      label: label,
      kind: callKind,
      icon: missed
          ? Icons.call_end_rounded
          : (isVideo ? Icons.videocam_rounded : Icons.call_rounded),
      iconColor: missed
          ? AppColors.error
          : (mine ? const Color(0xFF22C55E) : AppColors.primary),
    );
  }
}

class _CallTileView {
  final String label;
  final CallKind kind;
  final IconData icon;
  final Color iconColor;
  const _CallTileView({
    required this.label,
    required this.kind,
    required this.icon,
    required this.iconColor,
  });
}
