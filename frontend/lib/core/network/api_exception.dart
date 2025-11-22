import 'package:dio/dio.dart';

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  @override
  String toString() {
    return 'ApiException: $message (statusCode: $statusCode)';
  }
}

/// Extension to handle Dio errors
extension DioErrorExtension on DioException {
  ApiException toApiException() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: null,
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Send timeout. Please try again.',
          statusCode: null,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Receive timeout. Server is taking too long to respond.',
          statusCode: null,
        );
      case DioExceptionType.badResponse:
        final statusCode = response?.statusCode;
        final data = response?.data;

        String message;
        if (statusCode == 400) {
          message = 'Bad request. Please check your input.';
        } else if (statusCode == 401) {
          message = 'Unauthorized. Please login again.';
        } else if (statusCode == 403) {
          message = 'Forbidden. You don\'t have permission.';
        } else if (statusCode == 404) {
          message = 'Resource not found.';
        } else if (statusCode == 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = 'Request failed with status code $statusCode';
        }

        return ApiException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
          statusCode: null,
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Connection error. Please check your internet connection.',
          statusCode: null,
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          message: 'Bad certificate. SSL verification failed.',
          statusCode: null,
        );
      case DioExceptionType.unknown:
      default:
        return ApiException(
          message:
              'An unexpected error occurred: ${error?.toString() ?? "Unknown error"}',
          statusCode: null,
        );
    }
  }
}
