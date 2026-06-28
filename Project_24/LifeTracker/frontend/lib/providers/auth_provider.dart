import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth/auth_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/user_response.dart';
import '../theme/house_theme.dart';
import '../services/api_client.dart';
import '../services/api_constants.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this._sharedPreferences,
    required this._authService,
    required this._apiClient,
  }) {
    _apiClient.onUnauthorized = _handleUnauthorized;
  }

  final SharedPreferences _sharedPreferences;
  final AuthService _authService;
  final DioApiClient _apiClient;

  bool isInitializing = true;
  bool isLoading = false;
  bool isAuthenticated = false;
  String? errorMessage;
  int? userId;
  String? email;
  String? firstName;
  String? houseKey;

  HouseTheme get house => HouseTheme.fromKey(houseKey);
  String get profileLabel => '${firstName ?? 'Traveler'} of ${house.displayName}';

  Future<void> initialize() async {
    isInitializing = true;
    notifyListeners();

    final token = _sharedPreferences.getString(ApiConstants.accessTokenKey);
    if (token == null || token.isEmpty) {
      _clearSessionState();
      isInitializing = false;
      notifyListeners();
      return;
    }

    try {
      final user = await _authService.getCurrentUser();
      _applyUser(user);
      isAuthenticated = true;
      errorMessage = null;
    } catch (_) {
      await _clearStoredSession();
      _clearSessionState();
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> login(LoginRequest request) async {
    return _authenticate(() => _authService.login(request));
  }

  Future<bool> register(RegisterRequest request) async {
    return _authenticate(() => _authService.register(request));
  }

  Future<void> logout() async {
    await _clearStoredSession();
    _clearSessionState();
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _authenticate(Future<AuthResponse> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await action();
      await _persistSession(response);
      userId = response.userId;
      email = response.email;
      firstName = response.firstName;
      houseKey = response.houseKey;
      isAuthenticated = true;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.message;
      return false;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _persistSession(AuthResponse response) async {
    await _sharedPreferences.setString(ApiConstants.accessTokenKey, response.accessToken);
    await _sharedPreferences.setInt(ApiConstants.userIdKey, response.userId);
    await _sharedPreferences.setString(ApiConstants.userEmailKey, response.email);
    if (response.firstName.isNotEmpty) {
      await _sharedPreferences.setString(ApiConstants.userDisplayNameKey, response.firstName);
    } else {
      await _sharedPreferences.remove(ApiConstants.userDisplayNameKey);
    }
  }

  Future<void> _clearStoredSession() async {
    await _sharedPreferences.remove(ApiConstants.accessTokenKey);
    await _sharedPreferences.remove(ApiConstants.userIdKey);
    await _sharedPreferences.remove(ApiConstants.userEmailKey);
    await _sharedPreferences.remove(ApiConstants.userDisplayNameKey);
  }

  void _applyUser(UserResponse user) {
    userId = user.id;
    email = user.email;
    firstName = user.firstName;
    houseKey = user.houseKey;
  }

  void _clearSessionState() {
    isAuthenticated = false;
    userId = null;
    email = null;
    firstName = null;
    houseKey = null;
  }

  void _handleUnauthorized() {
    if (!isAuthenticated) return;
    logout();
  }
}
