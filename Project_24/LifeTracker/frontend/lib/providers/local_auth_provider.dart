import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../local/local_cache_store.dart';
import '../services/google_auth_service.dart';
import '../services/notification_service.dart';
import '../theme/house_theme.dart';
import '../database/app_database.dart';

/// Auth state backed entirely by Google Sign-In + local Drift DB.
/// No server, no JWT, no token refresh needed.
class LocalAuthProvider extends ChangeNotifier {
  LocalAuthProvider({
    required GoogleAuthService googleAuthService,
    required AppDatabase database,
  })  : _googleAuthService = googleAuthService,
        _database = database;

  final GoogleAuthService _googleAuthService;
  final AppDatabase _database;

  bool isInitializing = true;
  bool isLoading = false;
  bool isAuthenticated = false;
  bool isRegistered = false;
  String? errorMessage;

  String? googleId;
  String? email;
  String? displayName;
  String? originalDisplayName;
  String? photoUrl;
  String? houseKey;
  int? age;
  String? gender;

  // Kept for compatibility with existing UI that reads these fields
  int? get userId => null; // no server user ID needed
  String? get firstName => displayName?.split(' ').first;
  String get userOriginalName {
    if (originalDisplayName != null && originalDisplayName!.trim().isNotEmpty) {
      return originalDisplayName!.trim();
    }
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    return 'Noble Lord';
  }

  HouseTheme get house => HouseTheme.fromKey(houseKey);
  String get profileLabel => '${firstName ?? 'Traveler'} of ${house.displayName}';

  /// Called once at app startup.
  /// 1. Try to load profile from local DB & SharedPreferences.
  /// 2. If valid profile exists, directly enter home page.
  Future<void> initialize() async {
    isInitializing = true;
    notifyListeners();

    try {
      final sp = await SharedPreferences.getInstance();
      age = sp.getInt('user_age');
      gender = sp.getString('user_gender');
      originalDisplayName = sp.getString('original_user_name');
      final savedHouse = sp.getString('user_house_key');
      if (savedHouse != null && savedHouse.isNotEmpty) {
        houseKey = savedHouse;
      }

      // Check for a locally stored profile first (works fully offline)
      final localProfile = await _database.profileDao.getProfile();
      if (localProfile != null && localProfile.displayName != null && localProfile.displayName!.isNotEmpty) {
        _applyLocalProfile(localProfile);
        if (savedHouse != null && savedHouse.isNotEmpty) {
          houseKey = savedHouse;
        }
        if (originalDisplayName == null || originalDisplayName!.trim().isEmpty) {
          originalDisplayName = localProfile.displayName;
          await sp.setString('original_user_name', originalDisplayName!);
        }
        isRegistered = true;
        isAuthenticated = true;
        isInitializing = false;
        notifyListeners();

        // Refresh Google tokens silently in background (non-blocking)
        unawaited(_googleAuthService.signInSilently().catchError((_) => null));
        return;
      }

      // No local profile — check if house or name is in SharedPreferences
      if (savedHouse != null && savedHouse.isNotEmpty) {
        houseKey = savedHouse;
      }

      // Try silent sign-in
      final account = await _googleAuthService.signInSilently();
      if (account != null) {
        email = account.email;
        displayName = account.displayName;
        originalDisplayName = account.displayName;
        if (displayName != null) {
          await sp.setString('original_user_name', displayName!);
        }
        photoUrl = account.photoUrl;
        googleId = account.id;
        isAuthenticated = true;
        if (savedHouse != null && savedHouse.isNotEmpty) {
          isRegistered = true;
        }
      } else {
        isAuthenticated = false;
      }
    } catch (e) {
      debugPrint('Auth init error: $e');
      isAuthenticated = false;
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  /// Register user for first time with Name, Age, Gender, and House choice.
  Future<void> registerUser({
    required String displayName,
    required int age,
    required String gender,
    required String houseKey,
  }) async {
    this.displayName = displayName.trim();
    originalDisplayName = this.displayName;
    this.age = age;
    this.gender = gender;
    this.houseKey = houseKey;

    final sp = await SharedPreferences.getInstance();
    await sp.setInt('user_age', age);
    await sp.setString('user_gender', gender);
    await sp.setString('original_user_name', this.displayName!);
    await sp.setString('user_house_key', houseKey);

    await _database.profileDao.upsertProfile(
      UserProfileTableCompanion(
        id: const Value(1),
        googleId: Value(googleId ?? 'local-user'),
        email: Value(email ?? 'user@lifetracker.local'),
        displayName: Value(this.displayName!),
        photoUrl: Value(photoUrl),
        houseKey: Value(houseKey),
        updatedAt: Value(DateTime.now()),
      ),
    );

    isRegistered = true;
    isAuthenticated = true;
    notifyListeners();
  }

  Future<void> updateCharacterName(String newName) async {
    displayName = newName.trim();
    notifyListeners();

    try {
      final existing = await _database.profileDao.getProfile();
      await _database.profileDao.upsertProfile(
        UserProfileTableCompanion(
          id: const Value(1),
          googleId: Value(existing?.googleId ?? googleId ?? 'local-user'),
          email: Value(existing?.email ?? email ?? 'user@lifetracker.local'),
          displayName: Value(displayName!),
          photoUrl: Value(existing?.photoUrl ?? photoUrl),
          houseKey: Value(houseKey ?? 'stark'),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      debugPrint('Failed to save profile character name: $e');
    }
  }

  Future<void> updateHouse(String newHouseKey) async {
    houseKey = newHouseKey;
    notifyListeners();

    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('user_house_key', newHouseKey);

      final existing = await _database.profileDao.getProfile();
      await _database.profileDao.upsertProfile(
        UserProfileTableCompanion(
          id: const Value(1),
          googleId: Value(existing?.googleId ?? googleId ?? 'local-user'),
          email: Value(existing?.email ?? email ?? 'user@lifetracker.local'),
          displayName: Value(existing?.displayName ?? displayName ?? 'Traveler'),
          photoUrl: Value(existing?.photoUrl ?? photoUrl),
          houseKey: Value(newHouseKey),
          updatedAt: Value(DateTime.now()),
        ),
      );
    } catch (e) {
      debugPrint('Failed to save profile house key: $e');
    }
    notifyListeners();
  }

  Future<void> updateProfile({
    required String newDisplayName,
    required String newHouseKey,
  }) async {
    displayName = newDisplayName.trim();
    houseKey = newHouseKey;

    final sp = await SharedPreferences.getInstance();
    await sp.setString('user_house_key', newHouseKey);

    await _database.profileDao.upsertProfile(
      UserProfileTableCompanion(
        id: const Value(1),
        googleId: Value(googleId ?? 'local-user'),
        email: Value(email ?? 'user@lifetracker.local'),
        displayName: Value(displayName!),
        photoUrl: Value(photoUrl),
        houseKey: Value(houseKey),
        updatedAt: Value(DateTime.now()),
      ),
    );

    isAuthenticated = true;
    isRegistered = true;
    notifyListeners();
  }

  /// Shows the Google account picker. Sets auth state on success.
  Future<bool> signInWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final account = await _googleAuthService.signIn();
      if (account == null) {
        // User dismissed the picker
        errorMessage = 'Sign-in cancelled.';
        return false;
      }

      final sp = await SharedPreferences.getInstance();
      final savedHouse = sp.getString('user_house_key');
      if (savedHouse != null && savedHouse.isNotEmpty) {
        houseKey = savedHouse;
      }

      // Reload from DB after save
      final profile = await _database.profileDao.getProfile();
      if (profile != null && profile.displayName != null && profile.displayName!.isNotEmpty) {
        _applyLocalProfile(profile);
        if (savedHouse != null && savedHouse.isNotEmpty) {
          houseKey = savedHouse;
        }
        isRegistered = true;
      } else {
        email = account.email;
        displayName = account.displayName;
        photoUrl = account.photoUrl;
        googleId = account.id;
        if (houseKey != null && houseKey!.isNotEmpty) {
          isRegistered = true;
        }
      }

      isAuthenticated = true;
      errorMessage = null;
      return true;
    } catch (e) {
      errorMessage = 'Sign-in failed: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Signs out from Google and clears active session state without destroying local offline data.
  Future<void> signOut() async {
    try {
      final id = userId;
      if (id != null) {
        await NotificationService().cancelNotificationsForUser(id);
      } else {
        await NotificationService().cancelAllNotifications();
      }
      await _googleAuthService.signOut();
      _clearState();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign-out error: $e');
    }
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  void _applyLocalProfile(dynamic profile) {
    googleId = profile.googleId;
    email = profile.email;
    displayName = profile.displayName;
    photoUrl = profile.photoUrl;
    houseKey = profile.houseKey;
  }

  void _clearState() {
    isAuthenticated = false;
    isRegistered = false;
    googleId = null;
    email = null;
    displayName = null;
    photoUrl = null;
    houseKey = null;
  }
}

