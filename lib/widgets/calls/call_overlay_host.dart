import 'package:flutter/material.dart';

import '../../features/calls/controllers/active_call_controller.dart';
import '../../features/calls/models/call_session.dart';
import '../../features/calls/ui/active_call_minibar.dart';
import '../../features/calls/ui/active_call_screen.dart';
import '../../features/calls/ui/incoming_call_screen.dart';
import '../../features/calls/ui/outgoing_call_screen.dart';

/// Wraps every screen in the app and renders call UI on top of it when a
/// call is active.
///
/// IMPORTANT: always returns a [Stack] with [widget.child] at the bottom.
/// We must NOT swap `child` out for the call screen — doing so unmounts
/// the entire Navigator subtree, which loses the user's route stack
/// (their open chat, their scroll position, in-flight typing) and then
/// cold-starts the app from SplashRouter when the call ends. The call
/// screens cover the whole viewport with opaque Scaffolds, so the user
/// experience is the same as a full-screen route while the Navigator
/// behind stays alive and intact.
class CallOverlayHost extends StatefulWidget {
  final Widget child;
  const CallOverlayHost({super.key, required this.child});

  @override
  State<CallOverlayHost> createState() => _CallOverlayHostState();
}

class _CallOverlayHostState extends State<CallOverlayHost> {
  ActiveCallController? _controller;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final c = await ActiveCallControllerHolder.instance();
    if (!mounted) return;
    setState(() => _controller = c);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return AnimatedBuilder(
      animation: controller ?? const _AlwaysStillNotifier(),
      builder: (context, _) {
        final overlay = _buildOverlay(controller);
        if (overlay == null) return widget.child;
        // StackFit.expand is critical here. The default (StackFit.loose)
        // sizes the Stack to its non-positioned child (widget.child).
        // When widget.child happens to render narrower than the screen
        // — e.g. during a Navigator transition, when an inner Scaffold
        // body uses unbounded width semantics, or any other intrinsic-
        // sizing edge case — Positioned.fill inherits that shrunken
        // viewport and the call screen gets shifted/cropped. Forcing
        // expand pins the Stack (and therefore the overlay) to the full
        // screen regardless of what's underneath.
        return Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            // TextFields / focus from the underlying route shouldn't
            // receive taps while a call overlay is up.
            Positioned.fill(child: overlay),
          ],
        );
      },
    );
  }

  Widget? _buildOverlay(ActiveCallController? controller) {
    if (controller == null) return null;
    final session = controller.session;
    if (session == null) return null;

    switch (session.phase) {
      case LocalCallPhase.dialing:
      case LocalCallPhase.outgoing:
        return OutgoingCallScreen(controller: controller);
      case LocalCallPhase.incoming:
      case LocalCallPhase.accepting:
        return IncomingCallScreen(controller: controller);
      case LocalCallPhase.connecting:
      case LocalCallPhase.active:
      case LocalCallPhase.reconnecting:
        if (controller.isMaximised) {
          return ActiveCallScreen(controller: controller);
        }
        // Minibar — anchored to the top; the underlying child shows
        // through everywhere else (no Positioned.fill wrapper here).
        return _MinibarOverlay(controller: controller);
      case LocalCallPhase.ended:
        return null;
    }
  }
}

/// A tiny anchored overlay so the minibar can be rendered without
/// blocking interaction with the chat / list / wherever the user
/// navigated while the call is active.
class _MinibarOverlay extends StatelessWidget {
  final ActiveCallController controller;
  const _MinibarOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pass-through region — taps fall to the screen behind us.
        const Positioned.fill(child: IgnorePointer(child: SizedBox.shrink())),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ActiveCallMinibar(controller: controller),
        ),
      ],
    );
  }
}

/// `AnimatedBuilder` needs a non-null `Listenable`. While the controller
/// is loading we feed it this no-op stand-in so the build doesn't NPE
/// before _bootstrap completes.
class _AlwaysStillNotifier implements Listenable {
  const _AlwaysStillNotifier();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}
