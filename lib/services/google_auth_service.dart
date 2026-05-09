import 'package:google_sign_in/google_sign_in.dart';

/// Wraps the Google Sign-In SDK. Returns the Google ID token that should be
/// sent to our backend's `POST /auth/google` endpoint for verification.
class GoogleAuthService {
  /// The **Web** OAuth client ID from Google Cloud Console. On Android the
  /// SDK uses this as the `serverClientId` so the issued ID token's audience
  /// matches what our backend expects.
  static const String _webClientId =
      '125212125733-ke01ioteqb7v882bnt3sr360fhbsttjv.apps.googleusercontent.com';

  static final GoogleSignIn _signIn = GoogleSignIn(
    serverClientId: _webClientId,
    scopes: const ['email', 'profile'],
  );

  /// Triggers the native Google account picker. Returns the ID token, or
  /// `null` if the user cancelled.
  static Future<String?> signInAndGetIdToken() async {
    // Start fresh so the picker always shows (avoids "silently signed in
    // with the wrong account" surprises).
    await _signIn.signOut();
    final account = await _signIn.signIn();
    if (account == null) return null;
    final auth = await account.authentication;
    return auth.idToken;
  }

  static Future<void> signOut() => _signIn.signOut();
}
