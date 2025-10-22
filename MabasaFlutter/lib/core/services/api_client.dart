import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  ApiClient._internal();
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio _dio = Dio(BaseOptions(
    baseUrl: kIsWeb ? 'http://localhost:8000' : 'http://10.0.2.2:8000',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ));

  Future<Dio> authed() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final dio = Dio(_dio.options);
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }
    return dio;
  }

  Dio get raw => _dio;
}
