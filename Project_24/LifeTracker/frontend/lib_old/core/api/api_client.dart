import 'package:dio/dio.dart';

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
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

extension DioExceptionMessage on DioException {
  String get friendlyMessage {
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
}
