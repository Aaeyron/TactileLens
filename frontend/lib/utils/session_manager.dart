import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  const SessionManager._();

  static const String userIdKey = 'user_id';
  static const String firstNameKey = 'first_name';
  static const String lastNameKey = 'last_name';
  static const String emailKey = 'email';
  static const String roleKey = 'role';
  static const String guestModeKey = 'guest_mode';
  static const String guestNicknameKey = 'guest_nickname';

  static const String _accessTokenKey = 'access_token';

  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  static Future<void> saveUser({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
  }) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await Future.wait(<Future<bool>>[
      prefs.setInt(userIdKey, id),
      prefs.setString(firstNameKey, firstName),
      prefs.setString(lastNameKey, lastName),
      prefs.setString(emailKey, email),
      prefs.setString(roleKey, role),
      prefs.setBool(guestModeKey, false),
    ]);

    await prefs.remove(guestNicknameKey);
  }

  static Future<void> saveAccessToken(
    String token,
  ) async {
    final String normalizedToken = token.trim();

    if (normalizedToken.isEmpty) {
      throw const FormatException(
        'The authentication token cannot be empty.',
      );
    }

    await _secureStorage.write(
      key: _accessTokenKey,
      value: normalizedToken,
    );
  }

  static Future<String?> getAccessToken() async {
    final String? token = await _secureStorage.read(
      key: _accessTokenKey,
    );

    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return token.trim();
  }

  static Future<bool> hasAccessToken() async {
    return await getAccessToken() != null;
  }

  static Future<void> saveGuest({
    required String nickname,
    required String role,
  }) async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await Future.wait(<Future<bool>>[
      prefs.setBool(guestModeKey, true),
      prefs.setString(guestNicknameKey, nickname),
      prefs.setString(roleKey, role),
    ]);

    await Future.wait(<Future<bool>>[
      prefs.remove(userIdKey),
      prefs.remove(firstNameKey),
      prefs.remove(lastNameKey),
      prefs.remove(emailKey),
    ]);

    await _secureStorage.delete(
      key: _accessTokenKey,
    );
  }

  static Future<void> logout() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await Future.wait<void>(<Future<void>>[
      prefs.clear(),
      _secureStorage.delete(
        key: _accessTokenKey,
      ),
    ]);
  }

  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    final bool hasUser = prefs.containsKey(userIdKey);
    final bool hasToken = await hasAccessToken();

    return hasUser && hasToken;
  }

  static Future<bool> isGuest() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(guestModeKey) ?? false;
  }

  static Future<int?> getUserId() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getInt(userIdKey);
  }

  static Future<String?> getFirstName() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(firstNameKey);
  }

  static Future<String?> getLastName() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(lastNameKey);
  }

  static Future<String?> getEmail() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(emailKey);
  }

  static Future<String?> getRole() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(roleKey);
  }

  static Future<String?> getGuestNickname() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(guestNicknameKey);
  }
}