import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'api_constants.dart';

class DioApiClient implements ApiClient {
  DioApiClient({required SharedPreferences sharedPreferences, Dio? dio})
      : _sharedPreferences = sharedPreferences,
        _dio = dio ?? Dio() {
    _dio.options.connectTimeout = ApiConstants.connectTimeout;
    _dio.options.receiveTimeout = ApiConstants.receiveTimeout;
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => debugPrint(obj.toString()),
      ),
    );
  }

  final SharedPreferences _sharedPreferences;
  final Dio _dio;

  Future<String> get currentBaseUrl async {
    await _refreshBaseUrl();
    return _dio.options.baseUrl;
  }

  Future<void> initialize() => _refreshBaseUrl();

  @override
  Future<T> get<T>(
    String path, {
    required T Function(dynamic data) parser,
    Map<String, dynamic>? queryParameters,
  }) async {
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
  }) async {
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
  }) async {
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
  }) async {
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

  Future<void> _refreshBaseUrl() async {
    final configured = ApiConstants.normalizeBaseUrl(
      _sharedPreferences.getString(ApiConstants.baseUrlKey),
    );
    _dio.options.baseUrl = configured;
  }
}
