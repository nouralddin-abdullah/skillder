import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../theme/app_colors.dart';
import '../controllers/active_call_controller.dart';
import '../models/call_models.dart';
import '../models/call_session.dart';
import '_call_avatar.dart';

/// In-call screen. Voice calls use the app's light theme so the screen
/// matches the rest of the app; video calls overlay the controls on top
/// of the remote video on a dark backdrop so the video pops. Either way
/// the 2x3 control grid matches the user's screenshot.
class ActiveCallScreen extends StatefulWidget {
  final ActiveCallController controller;
  const ActiveCallScreen({super.key, required this.controller});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  Timer? _ticker;

  /// User-controlled toggle for the bottom control panel. When true, the
  /// panel fades out and a single tap anywhere on the media area brings
  /// it back. Lets the user reclaim the full screen during a video call.
  bool _controlsHidden = false;

  /// Position of the local-camera PIP. Lazy-initialised on the first
  /// build because we need MediaQuery to anchor it to the top-right.
  /// Stored as a left/top offset (not right/top) so drag updates compose
  /// arithmetically and we don't have to flip signs.
  Offset? _localPreviewOffset;

  static const double _previewWidth = 110;
  static const double _previewHeight = 160;
  static const double _previewMargin = 16;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_localPreviewOffset == null) {
      final size = MediaQuery.of(context).size;
      _localPreviewOffset = Offset(
        size.width - _previewWidth - _previewMargin,
        _previewMargin + 64, // below the top bar
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _onPreviewPanUpdate(DragUpdateDetails details, Size screenSize) {
    final current = _localPreviewOffset;
    if (current == null) return;
    setState(() {
      _localPreviewOffset = Offset(
        (current.dx + details.delta.dx).clamp(
          0.0,
          screenSize.width - _previewWidth,
        ),
        (current.dy + details.delta.dy).clamp(
          0.0,
          screenSize.height - _previewHeight - 80, // leave room above controls
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final session = widget.controller.session;
        if (session == null) return const SizedBox.shrink();
        final hasRemoteVideo = _hasRemoteVideo();
        final darkMode = session.kind == CallKind.video && hasRemoteVideo;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            // Status bar and nav bar are transparent so the remote video
            // shows through edge-to-edge. Icon brightness flips with the
            // backdrop so they stay legible.
            statusBarColor: Colors.transparent,
            statusBarBrightness:
                darkMode ? Brightness.dark : Brightness.light,
            statusBarIconBrightness:
                darkMode ? Brightness.light : Brightness.dark,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarIconBrightness:
                darkMode ? Brightness.light : Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: darkMode
                ? const Color(0xFF0F1419)
                : AppColors.surface,
            // Lets the body extend behind the (now-transparent) system bars
            // so the video really fills the screen.
            extendBody: true,
            extendBodyBehindAppBar: true,
            body: SizedBox.expand(
              child: DecoratedBox(
                decoration: darkMode
                    ? const BoxDecoration(color: Color(0xFF0F1419))
                    : const BoxDecoration(
                        gradient: AppColors.backgroundGradient,
                      ),
                // No SafeArea here — the media area fills the entire screen.
                // Top bar and bottom controls each wrap their own SafeArea
                // *inside* their Positioned so they keep the right insets
                // without clipping the video.
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: _buildMediaArea(session, darkMode)),
                    _buildTopBar(session, darkMode),
                    _buildBottomControls(session, darkMode),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _hasRemoteVideo() {
    final room = widget.controller.room.currentRoom;
    final remote = room?.remoteParticipants.values.isNotEmpty == true
        ? room!.remoteParticipants.values.first
        : null;
    if (remote == null) return false;
    return remote.videoTrackPublications.any(
      (p) => !p.muted && p.subscribed && p.track != null,
    );
  }

  Widget _buildMediaArea(CallSession session, bool darkMode) {
    final room = widget.controller.room.currentRoom;
    final remote = room?.remoteParticipants.values.isNotEmpty == true
        ? room!.remoteParticipants.values.first
        : null;
    final remoteVideoTrack = remote?.videoTrackPublications
        .where((p) => !p.muted && p.subscribed)
        .map((p) => p.track)
        .whereType<lk.VideoTrack>()
        .firstOrNull;

    final hasRemoteVideo = remoteVideoTrack != null;
    final hasLocalCamera = widget.controller.localTracks.cameraEnabled;
    final screenSize = MediaQuery.of(context).size;
    final offset = _localPreviewOffset;

    return GestureDetector(
      // Tap anywhere on the call's media area to restore the hidden
      // controls panel. translucent so taps still register on top of the
      // video render layer.
      behavior: HitTestBehavior.translucent,
      onTap: _controlsHidden
          ? () => setState(() => _controlsHidden = false)
          : null,
      child: Stack(
        children: [
          if (hasRemoteVideo)
            Positioned.fill(
              child: lk.VideoTrackRenderer(
                remoteVideoTrack,
                // Fill the viewport edge-to-edge so the name/status overlay
                // sits on top of the live frame. Default `contain` would
                // letterbox a landscape camera feed inside a portrait phone,
                // leaving black bars where the top bar visually "floats
                // above" the video.
                fit: lk.VideoViewFit.cover,
              ),
            )
          else
            Center(
              child: CallAvatar(
                photoUrl: session.peerPhotoUrl,
                size: 200,
                light: !darkMode,
              ),
            ),
          // Render the local preview whenever the local camera is actually
          // publishing — not just when the call was initiated as video.
          // A voice call promoted to video via the Video toggle still
          // publishes a real camera track, and the user needs to see their
          // own framing.
          if (hasLocalCamera && offset != null)
            Positioned(
              left: offset.dx,
              top: offset.dy,
              child: _buildLocalPreview(screenSize),
            ),
        ],
      ),
    );
  }

  Widget _buildLocalPreview(Size screenSize) {
    final room = widget.controller.room.currentRoom;
    // Don't filter by !p.muted — the publication's muted flag can flip true
    // for brief windows during renegotiation, and excluding muted tracks
    // would make the preview disappear/reappear on toggle. Filter by source
    // and require a non-null LocalVideoTrack so we still render an actual
    // capturing track.
    final cameraTrack = room?.localParticipant?.videoTrackPublications
        .where((p) => p.source == lk.TrackSource.camera)
        .map((p) => p.track)
        .whereType<lk.LocalVideoTrack>()
        .firstOrNull;
    if (cameraTrack == null) return const SizedBox.shrink();
    return GestureDetector(
      onPanUpdate: (details) => _onPreviewPanUpdate(details, screenSize),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: _previewWidth,
              height: _previewHeight,
              // IgnorePointer suppresses LiveKit's internal GestureDetector
              // around the local renderer (see video_track_renderer.dart
              // L254-270: for LocalVideoTrack on mobile, the SDK auto-wraps
              // the renderer with onTapDown → Helper.setFocusPoint +
              // setExposurePoint, plus onScaleUpdate → setZoom).
              //
              // onTapDown fires on the initial finger-down — BEFORE the
              // gesture arena decides whether the gesture is a tap or a
              // drag — so every attempt to drag the PIP triggers a focus
              // call. On flutter_webrtc 1.4.0 (transitive via livekit_client
              // 2.7.0) the native CameraUtils.convertPointToMeteringRectangle
              // dereferences a null PlatformChannel.DeviceOrientation and
              // throws an NPE, which surfaces as the uncaught
              // PlatformException seen in the call screen logs.
              //
              // We don't need pinch-zoom or tap-to-focus on a 110×160 PIP,
              // so blocking the inner detector is fine. The outer drag
              // GestureDetector (onPanUpdate above) sits OUTSIDE this
              // IgnorePointer so it still receives the drag, and the
              // switch-camera button below is a sibling so it still taps.
              child: IgnorePointer(
                child: lk.VideoTrackRenderer(
                  cameraTrack,
                  mirrorMode: lk.VideoViewMirrorMode.auto,
                ),
              ),
            ),
          ),
          // Switch-camera affordance moved off the bottom More menu and
          // onto the local preview itself. Sits in the top-right corner
          // so it's reachable without occluding the rear-facing image.
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: widget.controller.switchCamera,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cameraswitch_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(CallSession session, bool darkMode) {
    final isReconnecting = session.phase == LocalCallPhase.reconnecting;
    final titleColor = darkMode ? Colors.white : AppColors.textPrimary;
    final subColor = isReconnecting
        ? Colors.amberAccent
        : (darkMode ? Colors.white70 : AppColors.textSecondary);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      // SafeArea lives INSIDE the Positioned (not around it) so the
      // Positioned remains a direct child of Stack — otherwise its
      // StackParentData gets swallowed by SafeArea's parent-data widget.
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Row(
          children: [
            _CircleIconButton(
              icon: Icons.close_fullscreen_rounded,
              dark: darkMode,
              onTap: () => widget.controller.setMaximised(false),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    session.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: titleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isReconnecting ? 'Reconnecting…' : _statusLine(session),
                    style: GoogleFonts.inter(color: subColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40),
          ],
        ),
        ),
      ),
    );
  }

  String _statusLine(CallSession session) {
    if (session.phase == LocalCallPhase.dialing ||
        session.phase == LocalCallPhase.outgoing) {
      return 'Calling…';
    }
    if (session.phase == LocalCallPhase.connecting) {
      // LiveKit room.connect + track publish is in flight (~1-3s). The
      // local mic/camera flags are still false here so we deliberately
      // skip the duration timer and the control row — see _buildBottomControls.
      return 'Connecting…';
    }
    final answered = session.answeredAt;
    if (answered == null) return 'End-to-end encrypted';
    final secs = DateTime.now().toUtc().difference(answered).inSeconds;
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildBottomControls(CallSession session, bool darkMode) {
    final tracks = widget.controller.localTracks;
    final panelColor = darkMode
        ? Colors.black.withValues(alpha: 0.5)
        : AppColors.surface;
    // During the LiveKit handshake the track-state flags aren't backed by
    // real published tracks yet — showing Mic/Video/Speaker would render
    // a misleading "muted mic" icon. Collapse to End Call only so the user
    // can still bail if connect hangs.
    final isConnecting = session.phase == LocalCallPhase.connecting;
    // IMPORTANT: the [AnimatedOpacity] + [IgnorePointer] wrappers MUST live
    // INSIDE the [Positioned] — not around it. Positioned carries
    // StackParentData and must be a direct child of the parent Stack;
    // wrapping it in another ParentDataWidget swallows the offsets and
    // re-parents the visual into the full Stack region, producing a
    // screen-blocking translucent overlay (the "white layer that blocks
    // input" symptom).
    return Positioned(
      left: 16,
      right: 16,
      bottom: 0,
      child: IgnorePointer(
        ignoring: _controlsHidden,
        child: AnimatedOpacity(
          opacity: _controlsHidden ? 0 : 1,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          // SafeArea inside the Positioned (NOT around it — same rule as
          // _buildTopBar above) keeps the panel above the nav bar/gesture
          // pill on devices that have one. 16dp padding below the safe area
          // gives it the floating look.
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: darkMode
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: isConnecting
            ? Center(
                child: _EndCallButton(
                  dark: darkMode,
                  onTap: () =>
                      widget.controller.hangup(reason: CallEndReason.normal),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ControlButton(
                        icon: tracks.speakerEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_down_rounded,
                        label: 'Speaker',
                        active: tracks.speakerEnabled,
                        dark: darkMode,
                        onTap: widget.controller.toggleSpeaker,
                      ),
                      _ControlButton(
                        icon: tracks.cameraEnabled
                            ? Icons.videocam_rounded
                            : Icons.videocam_off_rounded,
                        label: 'Video',
                        active: tracks.cameraEnabled,
                        dark: darkMode,
                        onTap: widget.controller.toggleCamera,
                      ),
                      _ControlButton(
                        icon: tracks.micEnabled
                            ? Icons.mic_rounded
                            : Icons.mic_off_rounded,
                        label: 'Mute',
                        active: !tracks.micEnabled,
                        dark: darkMode,
                        onTap: widget.controller.toggleMic,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ControlButton(
                        icon: Icons.visibility_off_rounded,
                        label: 'Hide',
                        dark: darkMode,
                        onTap: () =>
                            setState(() => _controlsHidden = true),
                      ),
                      _EndCallButton(
                        dark: darkMode,
                        onTap: () => widget.controller
                            .hangup(reason: CallEndReason.normal),
                      ),
                    ],
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.inputFill,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: dark ? Colors.white : AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool dark;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (dark) {
      bg = active ? Colors.white : Colors.white.withValues(alpha: 0.18);
      fg = active ? const Color(0xFF1A1A2E) : Colors.white;
    } else {
      bg = active ? AppColors.primary : AppColors.inputFill;
      fg = active ? Colors.white : AppColors.textPrimary;
    }
    final labelColor = dark ? Colors.white : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(icon, color: fg, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.inter(color: labelColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EndCallButton extends StatelessWidget {
  final bool dark;
  final VoidCallback onTap;
  const _EndCallButton({required this.onTap, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final labelColor = dark ? Colors.white : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.call_end_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'End',
            style: GoogleFonts.inter(color: labelColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
