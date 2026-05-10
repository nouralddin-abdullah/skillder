import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class ApiConfig {
  /// Build-time override. Lets you point a real device at your laptop:
  ///
  /// ```
  /// flutter build apk --release --dart-define=API_HOST=192.168.1.17
  /// ```
  ///
  /// The same value is used for REST (`/api`) and Socket.IO (`/realtime`).
  static const _envHost = String.fromEnvironment('API_HOST');

  /// Override the port too if your backend isn't on 3000.
  static const _envPort = String.fromEnvironment('API_PORT');

  static String get _host {
    if (_envHost.isNotEmpty) return _envHost;
    // Android emulator can't reach the host's localhost via 127.0.0.1 — it
    // gets there through the special bridge address 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return 'localhost';
  }

  static String get _port => _envPort.isNotEmpty ? _envPort : '3000';

  static String get baseUrl => 'http://$_host:$_port/api';

  /// Socket.IO uses the same host as REST but lives outside the `/api`
  /// prefix.
  static String get socketUrl => 'http://$_host:$_port';
}
