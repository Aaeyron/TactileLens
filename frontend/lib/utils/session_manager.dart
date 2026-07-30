import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String userIdKey = "user_id";
  static const String firstNameKey = "first_name";
  static const String lastNameKey = "last_name";
  static const String emailKey = "email";
  static const String roleKey = "role";
  static const String guestModeKey = "guest_mode";
  static const String guestNicknameKey = "guest_nickname";

  static Future<void> saveUser({
  required int id,
  required String firstName,
  required String lastName,
  required String email,
  required String role,
}) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setInt(userIdKey, id);
  await prefs.setString(firstNameKey, firstName);
  await prefs.setString(lastNameKey, lastName);
  await prefs.setString(emailKey, email);
  await prefs.setString(roleKey, role);
}

static Future<void> saveGuest({
  required String nickname,
  required String role,
}) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setBool(guestModeKey, true);
  await prefs.setString(guestNicknameKey, nickname);
  await prefs.setString(roleKey, role);
}

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.containsKey(userIdKey);
  }

  static Future<bool> isGuest() async {
  final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(guestModeKey) ?? false;
  }

// ==========================
// Get User ID
// ==========================

static Future<int?> getUserId() async {
  final prefs = await SharedPreferences.getInstance();

  return prefs.getInt(userIdKey);
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

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(roleKey);
  }

  static Future<String?> getGuestNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(guestNicknameKey);
  }
}