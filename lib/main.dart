import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'features/calls/controllers/active_call_controller.dart';
import 'features/calls/services/call_actions_bridge.dart';
import 'features/calls/services/call_fcm_handler.dart';
import 'screens/splash_router.dart';
import 'theme/app_theme.dart';
import 'widgets/calls/call_overlay_host.dart';

Future<void> main() async {
  // Global async error sink. The livekit_client SDK throws unhandled
  // TimeoutException / TrackPublishException from internal listeners
  // (e.g. Room._onParticipantUpdateEvent, Room._setUpEngineListeners)
  // that we can't wrap in a try/catch from the outside. Without this
  // handler they propagate up to the Dart VM and the dev "flutter run"
  // session disconnects. In release builds they'd hit the platform's
  // uncaught-exception path. We log and swallow — the call flow has its
  // own recovery (`_connectToLiveKit` catches the related connect error
  // and ends the call cleanly).
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[uncaught] $error');
    return true;
  };

  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Firebase MUST be initialised before FCM handlers are registered. Both
    // the foreground listener and the @pragma('vm:entry-point') background
    // isolate handler depend on it.
    await Firebase.initializeApp();
    // Wire FCM listeners only — does not prompt the user. The OS
    // notification dialog and the backend device-token registration are
    // deferred to post-signup/login (see auth_service.dart) so a brand
    // new user sees the app first.
    await CallFcmHandler.attachHandlers();

    // Eagerly construct the controller so the socket+callkit listeners are
    // wired before the first frame — otherwise we'd miss a cold-start
    // Accept tap that fires before the home tree mounts.
    final callController = await ActiveCallControllerHolder.instance();
    CallActionsBridge.attach(callController);

    // Cold-start recovery: if the user tapped Accept on the native ringing
    // notification while the app was killed, the actionCallAccept event was
    // emitted before our listener was alive and got lost. The plugin
    // persists the accepted call which we query and process here.
    unawaited(CallActionsBridge.processColdStartLaunch(callController));

    runApp(const SkillderApp());
  }, (error, stack) {
    debugPrint('[zone uncaught] $error');
  });
}

class SkillderApp extends StatefulWidget {
  const SkillderApp({super.key});

  @override
  State<SkillderApp> createState() => _SkillderAppState();
}

class _SkillderAppState extends State<SkillderApp> {
  /// Used so the call controller can surface SnackBars (e.g. "Couldn't
  /// connect to the call") without having a BuildContext of its own.
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    _subscribeToCallErrors();
  }

  Future<void> _subscribeToCallErrors() async {
    final controller = await ActiveCallControllerHolder.instance();
    _errorSub = controller.errorEvents.listen((message) {
      final messenger = _scaffoldMessengerKey.currentState;
      if (messenger == null) return;
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  void dispose() {
    _errorSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skillder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      // CallOverlayHost wraps every screen so the active-call full screen
      // and the minimized minibar can render above any route without each
      // feature having to opt in.
      builder: (context, child) =>
          CallOverlayHost(child: child ?? const SizedBox.shrink()),
      home: const SplashRouter(),
    );
  }
}
