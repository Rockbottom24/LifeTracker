import '../models/auth/auth_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/user_response.dart';
import 'api_client.dart';

class AuthService {
  AuthService({required this._apiClient});

  final ApiClient _apiClient;

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
