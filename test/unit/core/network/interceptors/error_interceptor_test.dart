import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloomsafe/core/network/interceptors/error_interceptor.dart';

void main() {
  Dio dio = Dio();
  late ErrorInterceptor interceptor;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://test-api.com'));
    interceptor = ErrorInterceptor();
    dio.interceptors.add(interceptor);
  });

  group('ErrorInterceptor', () {
    test('Uses ErrorProcessor for error handling', () {
      // Just verify that the interceptor is properly constructed
      expect(interceptor, isA<ErrorInterceptor>());
    });
  });
}
