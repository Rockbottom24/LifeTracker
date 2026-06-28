import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_constants.dart';
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

class DioApiClient implements ApiClient {
  DioApiClient({required this._sharedPreferences, Dio? dio})
      : _dio = dio ?? Dio() {
    _dio.options.connectTimeout = ApiConstants.connectTimeout;
    _dio.options.receiveTimeout = ApiConstants.receiveTimeout;
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _sharedPreferences.getString(ApiConstants.accessTokenKey);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          final statusCode = error.response?.statusCode;
          final path = error.requestOptions.path;
          if (statusCode == 401 &&
              !path.contains('/auth/login') &&
              !path.contains('/auth/register')) {
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
          logPrint: (obj) => AppLogger.debug(obj),
        ),
      );
    }
  }

  final SharedPreferences _sharedPreferences;
  final Dio _dio;

  VoidCallback? onUnauthorized;

  Future<void> initialize() => _refreshBaseUrl(logResolvedBaseUrl: true);

  Future<void> setBaseUrl(String url) async {
    await _sharedPreferences.setString(ApiConstants.baseUrlKey, ApiConstants.resolveBaseUrl(url));
    await _refreshBaseUrl();
  }

  String get currentBaseUrl =>
      ApiConstants.resolveBaseUrl(_sharedPreferences.getString(ApiConstants.baseUrlKey));

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
    if (logResolvedBaseUrl) {
      AppLogger.debug('Resolved API base URL: ${_dio.options.baseUrl}');
    }
  }
}
