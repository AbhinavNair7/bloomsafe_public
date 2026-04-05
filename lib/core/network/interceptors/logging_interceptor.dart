import 'package:dio/dio.dart';
import 'package:bloomsafe/core/utils/logger.dart';

/// Custom logging interceptor that only logs in debug mode
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != 'GET' && options.method != 'POST') {
      Logger.network('REQUEST[${options.method}] => PATH: ${options.path}');
      Logger.network('QUERY PARAMETERS: ${options.queryParameters}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.requestOptions.method != 'GET' &&
        response.requestOptions.method != 'POST') {
      Logger.network(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      );
      Logger.network('DATA: ${response.data}');
    }
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Logger.network(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    Logger.network('ERROR TYPE: ${err.type}');
    Logger.network('ERROR MESSAGE: ${err.error}');
    super.onError(err, handler);
  }
}
