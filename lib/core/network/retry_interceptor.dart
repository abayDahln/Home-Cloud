import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final Function(String) logPrint;
  final int retries;
  final List<Duration> retryDelays;

  RetryInterceptor({
    required this.dio,
    required this.logPrint,
    this.retries = 3,
    this.retryDelays = const [
      Duration(seconds: 1),
      Duration(seconds: 3),
      Duration(seconds: 5),
    ],
  });

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (_shouldRetry(err)) {
      final retryCount = err.requestOptions.extra['retry_count'] ?? 0;

      if (retryCount < retries) {
        final delay = retryDelays[retryCount];
        logPrint('🔄 [RetryInterceptor] Retrying in ${delay.inSeconds}s '
            '(attempt ${retryCount + 1}/$retries) for ${err.requestOptions.path}');

        await Future.delayed(delay);

        final options = err.requestOptions;
        options.extra['retry_count'] = retryCount + 1;

        try {
          final response = await dio.fetch(options);
          handler.resolve(response);
          return;
        } catch (e) {
          // If the retry itself fails, we'll end up here.
          // We need to pass the *new* error to handler.next/reject or let the next iteration handle it.
          // But actually, dio.fetch will trigger onError again if it fails.
          // However, to be safe and avoid recursion issues in some dio versions:
          if (e is DioException) {
            // Let the next catch handle it or it will recursively call onError
          } else {
            handler.reject(DioException(requestOptions: options, error: e));
            return;
          }
        }
      }
    }

    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError;
  }
}
