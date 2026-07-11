import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_constants.dart';
import 'auth_token_store.dart';
import '../utils/app_logger.dart';

abstract class ApiClient {
  Future<T> get<T>(
    String path, {
    required T Function(dynamic data) parser,
    Map<String, dynamic>? queryParameters,
  });

  Future<T> post<T>(
    String path, {
    required T Function(dynamic data) parser,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });

  Future<T> put<T>(
    String path, {
    required T Function(dynamic data) parser,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  });

  Future<T> delete<T>(
    String path, {
    required T Function(dynamic data) parser,
    Map<String, dynamic>? queryParameters,
  });
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

extension DioExceptionMessage on DioException {
  String get friendlyMessage {
    final responseMessage = _extractErrorMessage(response?.data);
    if (responseMessage != null && responseMessage.isNotEmpty) {
      return responseMessage;
    }

    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return 'The request timed out. Please try again.';
    }

    if (type == DioExceptionType.connectionError) {
      return 'Unable to reach the server. Please check your connection.';
    }

    if (response?.statusCode != null) {
      return 'Request failed with status ${response!.statusCode}.';
    }

    return 'Something went wrong while processing the request.';
  }

  String? _extractErrorMessage(dynamic data) {
    if (data is Map) {
      final error = data['error'] ?? data['message'];
      if (error != null) return error.toString();
    }
    return null;
  }
}

typedef TokenRefresher = Future<RefreshOutcome> Function();

enum RefreshOutcome { success, invalidSession, transientFailure }

class DioApiClient implements ApiClient {
  DioApiClient({
    required AuthTokenStore tokenStore,
    required SharedPreferences sharedPreferences,
    Dio? dio,
  })  : _tokenStore = tokenStore,
        _sharedPreferences = sharedPreferences,
        _dio = dio ?? Dio() {
    _dio.options.connectTimeout = ApiConstants.connectTimeout;
    _dio.options.receiveTimeout = ApiConstants.receiveTimeout;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_isAuthPublicPath(options.path)) {
            final token = await _tokenStore.readAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;
          final path = error.requestOptions.path;
          final alreadyRetried = error.requestOptions.extra['authRetried'] == true;

          if (statusCode == 401 &&
              !_isAuthPublicPath(path) &&
              !alreadyRetried &&
              tokenRefresher != null) {
            try {
              final outcome = await _refreshSingleFlight();
              if (outcome == RefreshOutcome.success) {
                final request = error.requestOptions;
                final accessToken = await _tokenStore.readAccessToken();
                if (accessToken != null && accessToken.isNotEmpty) {
                  request.headers['Authorization'] = 'Bearer $accessToken';
                }
                request.extra['authRetried'] = true;
                final response = await _dio.fetch<dynamic>(request);
                return handler.resolve(response);
              }
              if (outcome == RefreshOutcome.invalidSession) {
                onUnauthorized?.call();
              }
            } catch (_) {
              // Network/server failure during refresh must preserve the local session.
            }
          } else if (statusCode == 401 && !_isAuthPublicPath(path) && alreadyRetried) {
            onUnauthorized?.call();
          }

          handler.next(error);
        },
      ),
    );
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) {
            final text = obj.toString().toLowerCase();
            if (text.contains('authorization') ||
                text.contains('refreshtoken') ||
                text.contains('accesstoken') ||
                text.contains('password')) {
              AppLogger.debug('[redacted auth log]');
              return;
            }
            AppLogger.debug(obj);
          },
        ),
      );
    }
  }

  final AuthTokenStore _tokenStore;
  final SharedPreferences _sharedPreferences;
  final Dio _dio;

  VoidCallback? onUnauthorized;
  TokenRefresher? tokenRefresher;

  Future<RefreshOutcome>? _refreshInFlight;

  Future<void> initialize() => _refreshBaseUrl(logResolvedBaseUrl: true);

  Future<void> setBaseUrl(String url) async {
    await _sharedPreferences.setString(ApiConstants.baseUrlKey, ApiConstants.resolveBaseUrl(url));
    await _refreshBaseUrl();
  }

  String get currentBaseUrl =>
      ApiConstants.resolveBaseUrl(_sharedPreferences.getString(ApiConstants.baseUrlKey));

  Future<RefreshOutcome> _refreshSingleFlight() {
    final existing = _refreshInFlight;
    if (existing != null) return existing;
    final future = () async {
      try {
        return await tokenRefresher!.call();
      } finally {
        _refreshInFlight = null;
      }
    }();
    _refreshInFlight = future;
    return future;
  }

  bool _isAuthPublicPath(String path) {
    return path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/logout');
  }

  @override
  Future<T> get<T>(
    String path, {
    required T Function(dynamic data) parser,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request<T>(
      method: 'GET',
      path: path,
      parser: parser,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<T> post<T>(
    String path, {
    required T Function(dynamic data) parser,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request<T>(
      method: 'POST',
      path: path,
      parser: parser,
      data: data,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<T> put<T>(
    String path, {
    required T Function(dynamic data) parser,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request<T>(
      method: 'PUT',
      path: path,
      parser: parser,
      data: data,
      queryParameters: queryParameters,
    );
  }

  @override
  Future<T> delete<T>(
    String path, {
    required T Function(dynamic data) parser,
    Map<String, dynamic>? queryParameters,
  }) {
    return _request<T>(
      method: 'DELETE',
      path: path,
      parser: parser,
      queryParameters: queryParameters,
    );
  }

  Future<T> _request<T>({
    required String method,
    required String path,
    required T Function(dynamic data) parser,
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      await _refreshBaseUrl();
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method),
      );

      return _parseResponse(response.data, parser);
    } on DioException catch (error) {
      debugPrint('======== DIO ERROR ========');
      debugPrint('Type: ${error.type}');
      debugPrint('Status: ${error.response?.statusCode}');
      debugPrint('===========================');
      throw ApiException(error.friendlyMessage, statusCode: error.response?.statusCode);
    } catch (error) {
      throw ApiException('Unexpected error: $error');
    }
  }

  T _parseResponse<T>(dynamic data, T Function(dynamic data) parser) {
    if (data is Map<String, dynamic> && data.containsKey('data') && data['data'] != null) {
      return parser(data['data']);
    }

    return parser(data);
  }

  Future<void> _refreshBaseUrl({bool logResolvedBaseUrl = false}) async {
    _dio.options.baseUrl = currentBaseUrl;

    debugPrint('========== API BASE URL ==========');
    debugPrint(_dio.options.baseUrl);
    debugPrint('==================================');

    if (logResolvedBaseUrl) {
      AppLogger.debug('Resolved API base URL: ${_dio.options.baseUrl}');
    }
  }
}
