import 'dart:async';

import 'package:livekit_client/livekit_client.dart' as lk;

/// State of the local participant's tracks. Mirrored into UI controls.
class LocalTrackState {
  final bool micEnabled;
  final bool cameraEnabled;
  final bool speakerEnabled;
  final lk.CameraPosition cameraPosition;

  const LocalTrackState({
    required this.micEnabled,
    required this.cameraEnabled,
    required this.speakerEnabled,
    required this.cameraPosition,
  });

  LocalTrackState copyWith({
    bool? micEnabled,
    bool? cameraEnabled,
    bool? speakerEnabled,
    lk.CameraPosition? cameraPosition,
  }) {
    return LocalTrackState(
      micEnabled: micEnabled ?? this.micEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      cameraPosition: cameraPosition ?? this.cameraPosition,
    );
  }
}

/// One stream of high-level room events the controller subscribes to.
sealed class RoomManagerEvent {
  const RoomManagerEvent();
}

class RoomConnectedEvent extends RoomManagerEvent {
  const RoomConnectedEvent();
}

class RoomReconnectingEvent extends RoomManagerEvent {
  const RoomReconnectingEvent();
}

class RoomReconnectedEvent extends RoomManagerEvent {
  const RoomReconnectedEvent();
}

class RoomDisconnectedEvent extends RoomManagerEvent {
  /// True when the disconnect was initiated by us (hangup); false when the
  /// server closed the room or the network died for good.
  final bool intentional;
  const RoomDisconnectedEvent({required this.intentional});
}

class ParticipantTracksChangedEvent extends RoomManagerEvent {
  /// True when the remote participant has at least one published track —
  /// used by the UI to swap the "connecting" placeholder for the real video
  /// or audio indicator.
  final bool hasRemoteVideo;
  final bool hasRemoteAudio;

  const ParticipantTracksChangedEvent({
    required this.hasRemoteVideo,
    required this.hasRemoteAudio,
  });
}

/// Wraps a [lk.Room] so the rest of the app talks in domain terms (mute,
/// switchCamera, hangup) instead of LiveKit primitives. Single-room: there
/// is at most one active call at a time.
class LiveKitRoomManager {
  lk.Room? _room;
  lk.CancelListenFunc? _cancelEvents;
  bool _intentionalDisconnect = false;

  /// Starts as muted-mic + camera-off-for-voice-calls; the controller flips
  /// these via [setMicEnabled] / [setCameraEnabled] before publishing.
  LocalTrackState _local = const LocalTrackState(
    micEnabled: false,
    cameraEnabled: false,
    speakerEnabled: false,
    cameraPosition: lk.CameraPosition.front,
  );

  final StreamController<RoomManagerEvent> _eventsCtl =
      StreamController<RoomManagerEvent>.broadcast();
  final StreamController<LocalTrackState> _localCtl =
      StreamController<LocalTrackState>.broadcast();

  Stream<RoomManagerEvent> get events => _eventsCtl.stream;
  Stream<LocalTrackState> get localTrackState => _localCtl.stream;

  LocalTrackState get currentLocal => _local;
  lk.Room? get currentRoom => _room;

  /// Connect to a LiveKit room. Publishes mic immediately for voice calls;
  /// publishes both mic and camera for video calls.
  Future<void> connect({
    required String url,
    required String token,
    required bool publishVideo,
  }) async {
    if (_room != null) {
      throw StateError('LiveKitRoomManager: already connected to a room');
    }

    // Reset to a known baseline. This manager is a singleton across calls,
    // so residual flags (cameraPosition, speakerEnabled) from a previous call
    // would otherwise leak into this one and show up as e.g. "speaker on" on
    // a voice call that should default to earpiece.
    _local = const LocalTrackState(
      micEnabled: false,
      cameraEnabled: false,
      speakerEnabled: false,
      cameraPosition: lk.CameraPosition.front,
    );

    final room = lk.Room(
      roomOptions: const lk.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );
    _intentionalDisconnect = false;
    _cancelEvents = room.createListener().on<lk.RoomEvent>(_onRoomEvent);

    await room.connect(
      url,
      token,
      // Publish defaults — fastConnectOptions is a best-effort hint. We
      // explicitly enforce the publish state below.
      fastConnectOptions: lk.FastConnectOptions(
        microphone: const lk.TrackOption(enabled: true),
        camera: lk.TrackOption(enabled: publishVideo),
      ),
      // Stretch LiveKit's PC/publish timeouts. Defaults are 10s each which
      // is too tight for slow networks and Android emulators — observed
      // peer connections succeeding at ~12-15s only to be torn down by the
      // 10s LiveKit timeout above them.
      connectOptions: const lk.ConnectOptions(
        timeouts: lk.Timeouts(
          connection: Duration(seconds: 20),
          debounce: Duration(milliseconds: 20),
          publish: Duration(seconds: 30),
          subscribe: Duration(seconds: 30),
          peerConnection: Duration(seconds: 30),
          iceRestart: Duration(seconds: 15),
        ),
      ),
    );

    _room = room;

    // Belt-and-suspenders: explicitly turn on the mic (and camera for video).
    // We've observed cases where fastConnectOptions doesn't actually publish
    // the mic on the first call after a permission grant — the UI shows the
    // mic icon as on, but the peer hears nothing. Awaiting the explicit
    // setter makes the publish state match the UI flag.
    try {
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (publishVideo) {
        await room.localParticipant?.setCameraEnabled(true);
      }
    } catch (e) {
      // Log but don't abort — a working call without mic is still better
      // than no call. The user can toggle the mic to retry.
      // ignore: avoid_print
      print('[livekit] enforce publish failed: $e');
    }

    // Voice calls default to earpiece; video calls default to speaker so
    // the user can hold the phone away from their face. setSpeakerphoneOn
    // is called AFTER the mic publish enforcement above so WebRTC's
    // AudioManager has already been put into MODE_IN_COMMUNICATION — a
    // setSpeakerphoneOn call before that is silently dropped on some
    // Android OEMs.
    final wantSpeaker = publishVideo;
    await lk.Hardware.instance.setSpeakerphoneOn(wantSpeaker);

    _local = _local.copyWith(
      micEnabled: true,
      cameraEnabled: publishVideo,
      speakerEnabled: wantSpeaker,
    );
    _localCtl.add(_local);

    _eventsCtl.add(const RoomConnectedEvent());
    _emitParticipantState();
  }

  Future<void> setMicEnabled(bool enabled) async {
    final room = _room;
    if (room == null) return;
    await room.localParticipant?.setMicrophoneEnabled(enabled);
    _local = _local.copyWith(micEnabled: enabled);
    _localCtl.add(_local);
  }

  Future<void> setCameraEnabled(bool enabled) async {
    final room = _room;
    if (room == null) return;
    await room.localParticipant?.setCameraEnabled(enabled);
    _local = _local.copyWith(cameraEnabled: enabled);
    _localCtl.add(_local);
  }

  Future<void> switchCamera() async {
    final room = _room;
    if (room == null) return;
    final cameraTrack = room.localParticipant?.videoTrackPublications
        .firstWhere(
          (t) => t.source == lk.TrackSource.camera,
          orElse: () => throw StateError('No camera track to switch'),
        )
        .track;
    if (cameraTrack is! lk.LocalVideoTrack) return;
    final next = _local.cameraPosition == lk.CameraPosition.front
        ? lk.CameraPosition.back
        : lk.CameraPosition.front;
    await cameraTrack.setCameraPosition(next);
    _local = _local.copyWith(cameraPosition: next);
    _localCtl.add(_local);
  }

  Future<void> setSpeakerEnabled(bool enabled) async {
    if (_room == null) return;
    await lk.Hardware.instance.setSpeakerphoneOn(enabled);
    _local = _local.copyWith(speakerEnabled: enabled);
    _localCtl.add(_local);
  }

  /// Disconnect cleanly and flag the disconnect as intentional so the
  /// listener doesn't emit a "lost connection" UI state.
  Future<void> hangup() async {
    _intentionalDisconnect = true;
    final room = _room;
    _room = null;
    if (room != null) {
      await room.disconnect();
      await room.dispose();
    }
    _cancelEvents?.call();
    _cancelEvents = null;
  }

  Future<void> dispose() async {
    await hangup();
    await _eventsCtl.close();
    await _localCtl.close();
  }

  // ─────────────────────────── Internals ────────────────────────────────

  void _onRoomEvent(lk.RoomEvent event) {
    switch (event) {
      case lk.RoomReconnectingEvent _:
        _eventsCtl.add(const RoomReconnectingEvent());
      case lk.RoomReconnectedEvent _:
        _eventsCtl.add(const RoomReconnectedEvent());
      case lk.RoomDisconnectedEvent _:
        _eventsCtl.add(
          RoomDisconnectedEvent(intentional: _intentionalDisconnect),
        );
      case lk.ParticipantConnectedEvent _:
      case lk.ParticipantDisconnectedEvent _:
      case lk.TrackPublishedEvent _:
      case lk.TrackUnpublishedEvent _:
      case lk.TrackSubscribedEvent _:
      case lk.TrackUnsubscribedEvent _:
      // Local publishes (our own camera/mic going live) fire these — without
      // them the UI never rebuilds after our local camera publishes, so the
      // PIP preview never appears even though the track exists.
      case lk.LocalTrackPublishedEvent _:
      case lk.LocalTrackUnpublishedEvent _:
      // Track-mute changes don't add/remove publications but they do change
      // what should render in the local preview.
      case lk.TrackMutedEvent _:
      case lk.TrackUnmutedEvent _:
        _emitParticipantState();
      default:
        // Other events (active speaker, data, etc.) are not surfaced to UI yet.
        break;
    }
  }

  void _emitParticipantState() {
    final remotes = _room?.remoteParticipants.values ?? const [];
    var hasVideo = false;
    var hasAudio = false;
    for (final p in remotes) {
      for (final pub in p.trackPublications.values) {
        if (pub.muted || !pub.subscribed) continue;
        switch (pub.source) {
          case lk.TrackSource.microphone:
            hasAudio = true;
          case lk.TrackSource.camera:
            hasVideo = true;
          default:
            break;
        }
      }
    }
    _eventsCtl.add(ParticipantTracksChangedEvent(
      hasRemoteVideo: hasVideo,
      hasRemoteAudio: hasAudio,
    ));
  }
}
