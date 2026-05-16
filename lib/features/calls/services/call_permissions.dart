import 'package:permission_handler/permission_handler.dart';

import '../models/call_models.dart';

/// Thrown when the OS denies a permission the call cannot proceed without.
/// `permanentlyDenied=true` means the user picked "Don't ask again" and the
/// only path forward is opening App Settings.
class CallPermissionDeniedException implements Exception {
  final Permission permission;
  final bool permanentlyDenied;
  CallPermissionDeniedException({
    required this.permission,
    required this.permanentlyDenied,
  });

  String get userMessage {
    final what = permission == Permission.camera ? 'camera' : 'microphone';
    if (permanentlyDenied) {
      return '$what permission is blocked. Enable it in Settings to make calls.';
    }
    return '$what permission is required to make this call.';
  }

  @override
  String toString() =>
      'CallPermissionDeniedException(${permission.toString()}, permanent=$permanentlyDenied)';
}

/// Request mic and (when video) camera permission. Throws
/// [CallPermissionDeniedException] on the first one the user denies so the
/// caller can show a single error and bail.
class CallPermissions {
  static Future<void> ensureForCall(CallKind kind) async {
    await _ensure(Permission.microphone);
    if (kind == CallKind.video) {
      await _ensure(Permission.camera);
    }
  }

  static Future<void> _ensure(Permission p) async {
    var status = await p.status;
    if (status.isGranted || status.isLimited) return;
    status = await p.request();
    if (status.isGranted || status.isLimited) return;
    throw CallPermissionDeniedException(
      permission: p,
      permanentlyDenied: status.isPermanentlyDenied,
    );
  }
}
