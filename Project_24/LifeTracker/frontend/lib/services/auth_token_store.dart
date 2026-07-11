import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_constants.dart';

/// Stores access/refresh tokens in secure storage and profile fields in SharedPreferences.
class AuthTokenStore {
  AuthTokenStore({
    required SharedPreferences sharedPreferences,
    FlutterSecureStorage? secureStorage,
  })  : _sharedPreferences = sharedPreferences,
        _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final SharedPreferences _sharedPreferences;
  final FlutterSecureStorage _secureStorage;

  Future<String?> readAccessToken() => _secureStorage.read(key: ApiConstants.accessTokenKey);

  Future<String?> readRefreshToken() => _secureStorage.read(key: ApiConstants.refreshTokenKey);

  Future<void> persistTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _secureStorage.write(key: ApiConstants.accessTokenKey, value: accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: ApiConstants.refreshTokenKey, value: refreshToken);
    }
    // Keep a non-secret marker in prefs so older code paths still see a session flag if needed.
    await _sharedPreferences.setString(ApiConstants.accessTokenKey, 'stored_securely');
  }

  Future<void> persistProfile({
    required int userId,
    required String email,
    required String firstName,
    required String houseKey,
  }) async {
    await _sharedPreferences.setInt(ApiConstants.userIdKey, userId);
    await _sharedPreferences.setString(ApiConstants.userEmailKey, email);
    await _sharedPreferences.setString(ApiConstants.userHouseKey, houseKey);
    if (firstName.isNotEmpty) {
      await _sharedPreferences.setString(ApiConstants.userDisplayNameKey, firstName);
    } else {
      await _sharedPreferences.remove(ApiConstants.userDisplayNameKey);
    }
  }

  int? readUserId() => _sharedPreferences.getInt(ApiConstants.userIdKey);

  String? readEmail() => _sharedPreferences.getString(ApiConstants.userEmailKey);

  String? readFirstName() => _sharedPreferences.getString(ApiConstants.userDisplayNameKey);

  String? readHouseKey() => _sharedPreferences.getString(ApiConstants.userHouseKey);

  Future<bool> hasSessionArtifacts() async {
    final refresh = await readRefreshToken();
    final access = await readAccessToken();
    final userId = readUserId();
    return userId != null && ((refresh != null && refresh.isNotEmpty) || (access != null && access.isNotEmpty));
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: ApiConstants.accessTokenKey);
    await _secureStorage.delete(key: ApiConstants.refreshTokenKey);
    await _sharedPreferences.remove(ApiConstants.accessTokenKey);
    await _sharedPreferences.remove(ApiConstants.userIdKey);
    await _sharedPreferences.remove(ApiConstants.userEmailKey);
    await _sharedPreferences.remove(ApiConstants.userDisplayNameKey);
    await _sharedPreferences.remove(ApiConstants.userHouseKey);
  }

  /// Migrates legacy plaintext access tokens from SharedPreferences into secure storage.
  Future<void> migrateLegacyAccessTokenIfNeeded() async {
    final legacy = _sharedPreferences.getString(ApiConstants.accessTokenKey);
    if (legacy == null || legacy.isEmpty || legacy == 'stored_securely') {
      return;
    }
    final existingSecure = await readAccessToken();
    if (existingSecure == null || existingSecure.isEmpty) {
      await _secureStorage.write(key: ApiConstants.accessTokenKey, value: legacy);
    }
    await _sharedPreferences.setString(ApiConstants.accessTokenKey, 'stored_securely');
  }
}
