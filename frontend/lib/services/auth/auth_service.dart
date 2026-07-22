import 'dart:convert';

import 'package:http/http.dart' as http;

class AuthService {
  // TODO:
  // Replace this with your computer's local IP address.
static const String baseUrl = "http://127.0.0.1:5000";

  static Future<http.Response> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/register");

    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "first_name": firstName,
        "last_name": lastName,
        "email": email,
        "password": password,
      }),
    );
  }
    static Future<http.Response> loginUser({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/login");

    return await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );
  }
}