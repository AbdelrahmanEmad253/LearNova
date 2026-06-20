import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as google_auth;
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionRemoteDataSource {
  static String get _redirectUrl {
    if (kIsWeb) {
      return '${Uri.base.origin}/';
    }

    return 'io.supabase.flutter://login-callback/';
  }

  final SupabaseClient client;

  const SessionRemoteDataSource(this.client);

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {
        'display_name': username.trim(),
        'full_name': username.trim(),
      },
    );

    // Also update the public.users table with full_name
    if (response.user != null) {
      try {
        await client.from('users').upsert({
          'id': response.user!.id,
          'email': email.trim(),
          'full_name': username.trim(),
          'role': 'student',
        });
      } catch (e) {
        debugPrint('Failed to upsert users table: $e');
      }
    }

    return response;
  }

  static bool _googleSignInInitialized = false;

  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('DEBUG: Starting Native Google Sign-In...');
      const webClientId = '579522265439-hbf3osc7p37i75ud6em64lnja43min8b.apps.googleusercontent.com';

      // 1. Initialize Google Sign In (must be called exactly once in 7.2.0)
      final googleSignIn = google_auth.GoogleSignIn.instance;
      if (!_googleSignInInitialized) {
        await googleSignIn.initialize(
          serverClientId: webClientId,
        );
        _googleSignInInitialized = true;
      }

      debugPrint('DEBUG: Calling googleSignIn.authenticate()...');
      final googleUser = await googleSignIn.authenticate();
      
      debugPrint('DEBUG: googleUser display name: ${googleUser.displayName}');

      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      debugPrint('DEBUG: idToken found: ${idToken != null}');

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      // 2. Sign in to Supabase using the ID Token
      debugPrint('DEBUG: Signing into Supabase with ID Token...');
      // Note: accessToken is typically not required for Supabase Google Sign-In on mobile.
      // We skip fetching authorizeScopes to prevent double popups or silent failures.
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      debugPrint('DEBUG: Supabase response user: ${response.user?.id}');
      return response.user != null;
    } catch (e, stack) {
      debugPrint('DEBUG ERROR: Native Google Sign-In Error: $e');
      debugPrint('DEBUG STACKTRACE: $stack');
      rethrow;
    }
  }

  Future<bool> signInWithFacebook() {
    return client.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: _redirectUrl,
    );
  }

  Future<void> signOut() {
    return client.auth.signOut();
  }

  Future<void> resendConfirmationEmail(String email) {
    return client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
    );
  }

  Stream<AuthState> observeAuthChanges() {
    return client.auth.onAuthStateChange;
  }

  Session? currentSession() {
    return client.auth.currentSession;
  }

  User? currentUser() {
    return client.auth.currentUser;
  }
}
