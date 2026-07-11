import 'package:flutter/foundation.dart';

import '../models/auth/auth_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/user_response.dart';
import '../theme/house_theme.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/auth_token_store.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required AuthTokenStore tokenStore,
    required AuthService authService,
    required DioApiClient apiClient,
  })  : _tokenStore = tokenStore,
        _authService = authService,
        _apiClient = apiClient {
    _apiClient.onUnauthorized = _handleUnauthorized;
    _apiClient.tokenRefresher = tryRefreshSession;
  }

  final AuthTokenStore _tokenStore;
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
  bool _logoutInProgress = false;

  HouseTheme get house => HouseTheme.fromKey(houseKey);
  String get profileLabel => '${firstName ?? 'Traveler'} of ${house.displayName}';

  Future<void> initialize() async {
    isInitializing = true;
    notifyListeners();

    await _tokenStore.migrateLegacyAccessTokenIfNeeded();

    final hasSession = await _tokenStore.hasSessionArtifacts();
    if (!hasSession) {
      _clearSessionState();
      isInitializing = false;
      notifyListeners();
      return;
    }

    _restoreProfileFromStore();

    try {
      final user = await _authService.getCurrentUser();
      _applyUser(user);
      await _tokenStore.persistProfile(
        userId: user.id,
        email: user.email,
        firstName: user.firstName,
        houseKey: user.houseKey,
      );
      isAuthenticated = true;
      errorMessage = null;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        final outcome = await tryRefreshSession();
        if (outcome == RefreshOutcome.success) {
          try {
            final user = await _authService.getCurrentUser();
            _applyUser(user);
            await _tokenStore.persistProfile(
              userId: user.id,
              email: user.email,
              firstName: user.firstName,
              houseKey: user.houseKey,
            );
            isAuthenticated = true;
            errorMessage = null;
          } on ApiException catch (retryError) {
            if (retryError.statusCode == 401) {
              await _forceClearSession();
            } else {
              _keepOfflineAuthenticatedSession();
            }
          } catch (_) {
            _keepOfflineAuthenticatedSession();
          }
        } else if (outcome == RefreshOutcome.invalidSession) {
          await _forceClearSession();
        } else {
          _keepOfflineAuthenticatedSession();
        }
      } else {
        // Network/timeout/5xx — preserve local login.
        _keepOfflineAuthenticatedSession();
      }
    } catch (_) {
      _keepOfflineAuthenticatedSession();
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
    if (_logoutInProgress) return;
    _logoutInProgress = true;
    try {
      final currentUserId = userId ?? _tokenStore.readUserId();
      if (currentUserId != null) {
        await NotificationService().cancelNotificationsForUser(currentUserId);
      } else {
        await NotificationService().cancelAllNotifications();
      }
      await _authService.logoutRemote();
      await _tokenStore.clear();
      _clearSessionState();
      notifyListeners();
    } finally {
      _logoutInProgress = false;
    }
  }

  Future<RefreshOutcome> tryRefreshSession() async {
    try {
      final response = await _authService.refreshSession();
      await _persistSession(response);
      userId = response.userId;
      email = response.email;
      firstName = response.firstName;
      houseKey = response.houseKey;
      isAuthenticated = true;
      return RefreshOutcome.success;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        return RefreshOutcome.invalidSession;
      }
      return RefreshOutcome.transientFailure;
    } catch (_) {
      return RefreshOutcome.transientFailure;
    }
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
      final previousUserId = userId ?? _tokenStore.readUserId();
      if (previousUserId != null) {
        await NotificationService().cancelNotificationsForUser(previousUserId);
      }

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
    await _tokenStore.persistTokens(
      accessToken: response.accessToken,
      refreshToken: response.refreshToken,
    );
    await _tokenStore.persistProfile(
      userId: response.userId,
      email: response.email,
      firstName: response.firstName,
      houseKey: response.houseKey,
    );
  }

  void _restoreProfileFromStore() {
    userId = _tokenStore.readUserId();
    email = _tokenStore.readEmail();
    firstName = _tokenStore.readFirstName();
    houseKey = _tokenStore.readHouseKey();
  }

  void _keepOfflineAuthenticatedSession() {
    _restoreProfileFromStore();
    if (userId != null) {
      isAuthenticated = true;
      errorMessage = null;
    } else {
      isAuthenticated = false;
    }
  }

  Future<void> _forceClearSession() async {
    final currentUserId = userId ?? _tokenStore.readUserId();
    if (currentUserId != null) {
      await NotificationService().cancelNotificationsForUser(currentUserId);
    } else {
      await NotificationService().cancelAllNotifications();
    }
    await _tokenStore.clear();
    _clearSessionState();
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
    if (!isAuthenticated || _logoutInProgress) return;
    logout();
  }
}
