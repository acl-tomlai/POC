import 'package:dio/dio.dart';
import 'package:dio_smart_retry/dio_smart_retry.dart';

import 'api_exception.dart';

typedef TokenProvider = String? Function();
typedef UnauthorizedHandler = void Function();

/// API base URL — overridable at compile time:
/// `flutter run --dart-define=API_BASE_URL=http://192.168.1.20:5202`.
const String _kDefaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5202',
);

/// Single Dio instance with JWT injection + 401 handling + transient retry.
///
/// The token provider is a callback into the session/device state so the
/// interceptor stays decoupled from Riverpod's lifecycle.
class ApiClient {
  ApiClient({
    String? baseUrl,
    required TokenProvider tokenProvider,
    UnauthorizedHandler? onUnauthorized,
  })  : _tokenProvider = tokenProvider,
        _onUnauthorized = onUnauthorized,
        dio = Dio(
          BaseOptions(
            baseUrl: baseUrl ?? _kDefaultBaseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 15),
            sendTimeout: const Duration(seconds: 15),
            headers: <String, String>{'Content-Type': 'application/json'},
          ),
        ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final String? token = _tokenProvider();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) {
          if (e.response?.statusCode == 401) {
            _onUnauthorized?.call();
          }
          handler.next(e);
        },
      ),
    );
    dio.interceptors.add(
      RetryInterceptor(
        dio: dio,
        retries: 2,
        retryDelays: const <Duration>[
          Duration(milliseconds: 250),
          Duration(milliseconds: 800),
        ],
      ),
    );
  }

  final Dio dio;
  final TokenProvider _tokenProvider;
  final UnauthorizedHandler? _onUnauthorized;

  String get baseUrl => dio.options.baseUrl;

  /// Runs a Dio call and rewraps DioException as ApiException with a friendly
  /// message extracted from the API's error body.
  Future<T> call<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
