import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Thin wrapper over Dio that unwraps the API's `{success, data}` envelope and
/// turns every failure into an [ApiException].
///
/// Base URL is compile-time so a web build can be pointed at staging without a
/// code change:  flutter build web --dart-define=API_BASE_URL=https://...
class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: const String.fromEnvironment(
                'API_BASE_URL',
                defaultValue: 'http://localhost:3000/api/v1',
              ),
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Content-Type': 'application/json'},
            ));

  final Dio _dio;

  /// Set once the student signs in; cleared on sign-out or a rejected token.
  /// Held here rather than passed per call so every repository picks it up.
  String? _token;

  // ignore: avoid_setters_without_getters
  set token(String? value) => _token = value;

  Future<T> get<T>(String path, {Map<String, dynamic>? query}) =>
      _send<T>(() => _dio.get<Map<String, dynamic>>(path, queryParameters: query));

  Future<T> post<T>(String path, {Object? body}) =>
      _send<T>(() => _dio.post<Map<String, dynamic>>(path, data: body));

  Future<T> delete<T>(String path) =>
      _send<T>(() => _dio.delete<Map<String, dynamic>>(path));

  Future<T> _send<T>(Future<Response<Map<String, dynamic>>> Function() call) async {
    try {
      _dio.options.headers['Authorization'] =
          _token == null ? null : 'Bearer $_token';
      final response = await call();
      final body = response.data;
      if (body == null) {
        throw ApiException('The server returned an empty response.');
      }
      // Success bodies are always {success: true, data: ...}.
      return body['data'] as T;
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  ApiException _toApiException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return ApiException(
        'Cannot reach the server. Is the API running on '
        '${_dio.options.baseUrl}?',
      );
    }

    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is List) {
          final errors = message.map((m) => m.toString()).toList();
          return ApiException(errors.first,
              statusCode: e.response?.statusCode, fieldErrors: errors);
        }
        if (message is String) {
          return ApiException(message, statusCode: e.response?.statusCode);
        }
      }
    }
    return ApiException(
      e.message ?? 'Something went wrong.',
      statusCode: e.response?.statusCode,
    );
  }
}
