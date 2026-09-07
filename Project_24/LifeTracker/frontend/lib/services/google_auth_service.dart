import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../database/app_database.dart';
import '../database/dao/profile_dao.dart';
import '../database/tables/user_profile_table.dart';
import 'package:drift/drift.dart' as drift;

/// Manages Google Sign-In authentication — no server required.
/// Profile is stored locally in the Drift SQLite database.
class GoogleAuthService {
  GoogleAuthService({required AppDatabase database})
      : _db = database,
        _googleSignIn = GoogleSignIn(
          scopes: [
            'email',
            'profile',
            'https://www.googleapis.com/auth/drive.appdata',
            'https://www.googleapis.com/auth/drive.file',
          ],
        );

  final AppDatabase _db;
  final GoogleSignIn _googleSignIn;

  ProfileDao get _profileDao => _db.profileDao;

  /// Returns the currently signed-in Google account, or null.
  GoogleSignInAccount? get currentAccount => _googleSignIn.currentUser;

  /// True if a local profile exists (i.e. user has signed in before).
  Future<bool> hasLocalProfile() async {
    final profile = await _profileDao.getProfile();
    return profile != null;
  }

  /// Attempts silent sign-in first (restores session without UI).
  /// Falls back to returning null if no previous session exists.
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Silent sign-in failed: $e');
      return null;
    }
  }

  /// Shows the Google account picker and signs in interactively.
  /// Returns the signed-in account, or null if the user cancels.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _saveProfileLocally(account);
      }
      return account;
    } catch (e) {
      debugPrint('Google Sign-In failed: $e');
      return null;
    }
  }

  /// Gets a fresh access token for Google Drive API calls.
  Future<String?> getAccessToken() async {
    try {
      var account = _googleSignIn.currentUser;
      account ??= await signInSilently();
      account ??= await signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.accessToken;
    } catch (e) {
      debugPrint('Failed to get access token: $e');
      return null;
    }
  }

  /// Signs out from Google and clears the local profile.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _profileDao.clearProfile();
    } catch (e) {
      debugPrint('Sign-out failed: $e');
    }
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _saveProfileLocally(GoogleSignInAccount account) async {
    final now = DateTime.now();
    await _profileDao.upsertProfile(
      UserProfileTableCompanion(
        googleId: drift.Value(account.id),
        email: drift.Value(account.email),
        displayName: drift.Value(account.displayName),
        photoUrl: drift.Value(account.photoUrl),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );
  }
}
