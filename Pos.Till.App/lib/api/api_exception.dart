import 'package:dio/dio.dart';

/// Friendly wrapper around DioException with a human message extracted from
/// the API's ProblemDetails / ErrorResponse body.
class ApiException implements Exception {
  ApiException({
    required this.message,
    required this.statusCode,
    this.details,
  });

  factory ApiException.fromDio(DioException e) {
    final int? status = e.response?.statusCode;
    final dynamic data = e.response?.data;
    String message = e.message ?? 'Network error';
    String? details;
    if (data is Map<String, dynamic>) {
      // ASP.NET ProblemDetails
      final dynamic title = data['title'];
      final dynamic detail = data['detail'];
      final dynamic errors = data['errors'];
      final dynamic msg = data['message'];
      if (errors is Map && errors.isNotEmpty) {
        final dynamic first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          message = first.first.toString();
        }
      } else if (msg is String && msg.isNotEmpty) {
        message = msg;
      } else if (detail is String && detail.isNotEmpty) {
        message = detail;
      } else if (title is String && title.isNotEmpty) {
        message = title;
      }
      if (detail is String && detail != message) details = detail;
    }
    return ApiException(
      message: message,
      statusCode: status,
      details: details,
    );
  }

  final String message;
  final int? statusCode;
  final String? details;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
