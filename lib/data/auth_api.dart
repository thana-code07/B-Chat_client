import 'package:dio/dio.dart';

import '../config/api_config.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}

class SessionUser {
  const SessionUser({required this.id, required this.username, this.email});

  final String id;
  final String username;
  final String? email;

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String?,
    );
  }
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final SessionUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String,
      user: SessionUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map),
      ),
    );
  }
}

class AuthApi {
  AuthApi({Dio? dio, String? baseUrl})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? apiBaseUrl(),
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
              headers: const {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  Future<AuthSession> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _send(
      () => _dio.post(
        '/api/auth/register',
        data: {
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
        },
      ),
    );
    return AuthSession.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _send(
      () => _dio.post(
        '/api/auth/login',
        data: {'username': username.trim(), 'password': password},
      ),
    );
    return AuthSession.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  Future<SessionUser> me(String token) async {
    final response = await _send(
      () => _dio.get('/api/auth/me', options: _bearer(token)),
    );
    final body = Map<String, dynamic>.from(response.data as Map);
    return SessionUser.fromJson(Map<String, dynamic>.from(body['user'] as Map));
  }

  Future<void> logout(String token) async {
    await _send(() => _dio.post('/api/auth/logout', options: _bearer(token)));
  }

  Future<void> deleteAccount(String token) async {
    await _send(
      () => _dio.delete('/api/auth/account', options: _bearer(token)),
    );
  }

  Options _bearer(String token) {
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<Response<dynamic>> _send(
    Future<Response<dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw AuthException(_message(error));
    }
  }

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final body = data['error'];
      if (body is Map &&
          body['message'] is String &&
          (body['message'] as String).isNotEmpty) {
        return body['message'] as String;
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'Cannot reach the server. Check that it is running.';
      default:
        return 'Something went wrong. Try again.';
    }
  }
}
