import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  const AuthService._();

  static const String baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

  static Future<http.Response> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
  }) {
    final Uri url = Uri.parse(
      '$baseUrl/api/auth/register',
    );

    return http.post(
      url,
      headers: const <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(
        <String, dynamic>{
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'role': role,
        },
      ),
    );
  }

  static Future<http.Response> loginUser({
    required String email,
    required String password,
  }) {
    final Uri url = Uri.parse(
      '$baseUrl/api/auth/login',
    );

    return http.post(
      url,
      headers: const <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(
        <String, dynamic>{
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      ),
    );
  }
}