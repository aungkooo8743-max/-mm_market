import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

/// Handles social OAuth authentication for Facebook and TikTok.
/// TikTok uses a WebView-based OAuth flow since no official Flutter SDK exists.
class SocialAuthService {
  final FirebaseAuth _auth;

  SocialAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  // ── Facebook ────────────────────────────────────────────────────────────────

  /// Signs in with Facebook OAuth.
  /// Returns a [UserCredential] on success.
  /// Throws [SocialAuthException] on failure.
  Future<UserCredential> signInWithFacebook() async {
    try {
      // Trigger the Facebook OAuth flow
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.cancelled) {
        throw const SocialAuthException(
          message: 'Facebook Sign-In ကို ဖျက်သိမ်းလိုက်ပါသည်',
          code: 'sign-in-cancelled',
        );
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        final msg = result.message ?? '';
        // Detect unconfigured SDK (placeholder App ID in strings.xml)
        if (msg.contains('REPLACE_WITH') ||
            msg.contains('YOUR_FACEBOOK') ||
            msg.contains('Invalid App ID') ||
            msg.contains('App ID')) {
          throw const SocialAuthException(
            message:
                'Facebook App ID မသတ်မှတ်ရသေးပါ။\n'
                'Meta Developer Console မှ App ID ရယူပြီး\n'
                'strings.xml ထဲ ထည့်ပြီး rebuild လုပ်ပါ',
            code: 'facebook-not-configured',
          );
        }
        throw SocialAuthException(
          message: msg.isNotEmpty ? msg : 'Facebook Sign-In မအောင်မြင်ပါ',
          code: 'facebook-auth-failed',
        );
      }

      // Create a Firebase credential from the Facebook access token
      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      // Sign in to Firebase with the Facebook credential
      return await _auth.signInWithCredential(credential);
    } on SocialAuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      // Handle account-exists-with-different-credential
      if (e.code == 'account-exists-with-different-credential') {
        throw SocialAuthException(
          message:
              'ဤ email ဖြင့် အကောင့်တစ်ခု ရှိပြီးသားဖြစ်သည်။\n'
              'Google သို့မဟုတ် Email ဖြင့် ဝင်ရောက်ပါ',
          code: e.code,
        );
      }
      throw SocialAuthException(
        message: e.message ?? 'Facebook Sign-In မအောင်မြင်ပါ',
        code: e.code,
      );
    } catch (e) {
      debugPrint('[SocialAuthService] Facebook error: $e');
      final errStr = e.toString();
      if (errStr.contains('REPLACE_WITH') ||
          errStr.contains('YOUR_FACEBOOK') ||
          errStr.contains('Invalid App ID')) {
        throw const SocialAuthException(
          message:
              'Facebook App ID မသတ်မှတ်ရသေးပါ။\n'
              'Meta Developer Console မှ App ID ရယူပြီး\n'
              'strings.xml ထဲ ထည့်ပြီး rebuild လုပ်ပါ',
          code: 'facebook-not-configured',
        );
      }
      throw SocialAuthException(
        message: 'Facebook Sign-In မအောင်မြင်ပါ။ ထပ်မံကြိုးစားပါ',
        code: 'unknown',
      );
    }
  }

  // ── TikTok ──────────────────────────────────────────────────────────────────
  //
  // TikTok does not have an official Flutter SDK. The recommended production
  // approach is:
  //   1. Generate a code_verifier + code_challenge (PKCE)
  //   2. Open TikTok OAuth URL in Chrome Custom Tab / WebView
  //   3. Receive the auth code via deep-link redirect URI
  //   4. Exchange the code for an access_token on your backend
  //   5. Use the access_token to get user profile, then create a Firebase
  //      Custom Token via your Cloud Function / backend
  //   6. Sign in to Firebase with the custom token
  //
  // To complete TikTok integration:
  //   • Register at https://developers.tiktok.com
  //   • Create a "Login Kit" app, add Android package: com.mmmarket.app
  //   • Add a Cloud Function that exchanges TikTok auth codes for Firebase tokens
  //   • Replace the throw below with the full PKCE + deep-link flow

  /// Placeholder for TikTok Sign-In.
  /// Throws [SocialAuthException] with actionable message.
  Future<UserCredential> signInWithTikTok() async {
    throw const SocialAuthException(
      message:
          'TikTok Sign-In ကို မကြာမီ ထည့်သွင်းပေးပါမည်\n'
          '(TikTok Developer Console တွင် App registration လိုအပ်ပါသည်)',
      code: 'tiktok-pending-backend',
    );
  }

  // ── Helpers (for future PKCE TikTok flow) ──────────────────────────────────

  /// Generates a cryptographically random string for PKCE code_verifier.
  static String generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// Derives a PKCE code_challenge from a code_verifier (S256 method).
  static String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}

/// Exception thrown by [SocialAuthService].
class SocialAuthException implements Exception {
  final String message;
  final String code;

  const SocialAuthException({required this.message, required this.code});

  @override
  String toString() => 'SocialAuthException($code): $message';
}
