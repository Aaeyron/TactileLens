import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String userIdKey = "user_id";
  static const String firstNameKey = "first_name";
  static const String lastNameKey = "last_name";
  static const String emailKey = "email";

  static Future<void> saveUser({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(userIdKey, id);
    await prefs.setString(firstNameKey, firstName);
    await prefs.setString(lastNameKey, lastName);
    await prefs.setString(emailKey, email);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.containsKey(userIdKey);
  }

  static Future<String?> getFirstName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(firstNameKey);
  }

  static Future<String?> getLastName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(lastNameKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(emailKey);
  }
}