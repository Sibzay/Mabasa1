import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> login(
      {required String usernameOrEmail, required String password}) async {
    final Response response = await _client.raw.post('/api/auth/token/', data: {
      'username': usernameOrEmail,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    await _saveTokens(data);
    return data['user'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
    required String? firstName,
    required String? lastName,
  }) async {
    final Response response =
        await _client.raw.post('/api/auth/register/', data: {
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
    });
    // Auto-login after register
    await login(usernameOrEmail: username, password: password);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> me() async {
    final dio = await _client.authed();
    final Response response = await dio.get('/api/auth/me/');
    return response.data as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('role');
  }

  Future<void> forgotPassword({required String email}) async {
    await _client.raw.post('/api/auth/forgot-password/', data: {
      'email': email,
    });
  }

  Future<void> _saveTokens(Map<String, dynamic> tokenResponse) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', tokenResponse['access']);
    await prefs.setString('refresh_token', tokenResponse['refresh']);
    final user = tokenResponse['user'] as Map<String, dynamic>;
    if (user['role'] != null) {
      await prefs.setString('role', user['role'] as String);
    }
  }
}
