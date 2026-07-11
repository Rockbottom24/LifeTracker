import '../models/auth/auth_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/user_response.dart';
import 'api_client.dart';
import 'auth_token_store.dart';

class AuthService {
  AuthService({
    required ApiClient apiClient,
    required AuthTokenStore tokenStore,
  })  : _apiClient = apiClient,
        _tokenStore = tokenStore;

  final ApiClient _apiClient;
  final AuthTokenStore _tokenStore;

  Future<AuthResponse> register(RegisterRequest request) async {
    return _apiClient.post<AuthResponse>(
      '/auth/register',
      data: request.toJson(),
      parser: _parseAuthResponse,
    );
  }

  Future<AuthResponse> login(LoginRequest request) async {
    return _apiClient.post<AuthResponse>(
      '/auth/login',
      data: request.toJson(),
      parser: _parseAuthResponse,
    );
  }

  Future<AuthResponse> refreshSession() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw ApiException('No refresh token available', statusCode: 401);
    }

    return _apiClient.post<AuthResponse>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      parser: _parseAuthResponse,
    );
  }

  Future<void> logoutRemote() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    try {
      await _apiClient.post<void>(
        '/auth/logout',
        data: refreshToken == null ? null : {'refreshToken': refreshToken},
        parser: (_) {},
      );
    } catch (_) {
      // Local logout must succeed even if the network call fails.
    }
  }

  Future<UserResponse> getCurrentUser() async {
    return _apiClient.get<UserResponse>(
      '/auth/me',
      parser: (data) => UserResponse.fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  AuthResponse _parseAuthResponse(dynamic data) {
    return AuthResponse.fromJson(Map<String, dynamic>.from(data as Map));
  }
}
