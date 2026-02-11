import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  late final Dio _dio;
  String? _authToken;
  String _baseUrl;

  ApiClient({String? authToken, String? baseUrl})
      : _authToken = authToken,
        _baseUrl = baseUrl ?? 'http://localhost:8090' {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 60),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        debugPrint('API Error: ${e.message} at ${e.requestOptions.path}');
        return handler.next(e);
      },
    ));
  }

  void setToken(String token) {
    _authToken = token;
  }

  void setBaseUrl(String url) {
    _baseUrl = url;
    _dio.options.baseUrl = url;
  }

  String get baseUrl => _baseUrl;
  String? get authToken => _authToken;

  Dio get dio => _dio;

  CancelToken _cancelToken = CancelToken();
  CancelToken get cancelToken => _cancelToken;

  void cancelAllRequests() {
    _cancelToken.cancel('User logged out');
    _cancelToken = CancelToken(); // Reset so next session works
  }
}
