import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  const SessionManager._();

  // Active registered-user session.
  static const String userIdKey = 'user_id';
  static const String firstNameKey = 'first_name';
  static const String lastNameKey = 'last_name';
  static const String emailKey = 'email';
  static const String roleKey = 'role';

  // Current session type.
  static const String guestModeKey = 'guest_mode';

  // Persistent Guest Profile stored on this device.
  static const String guestNicknameKey = 'guest_nickname';
  static const String guestRoleKey = 'guest_profile_role';

  static const int guestNicknameMaximumLength = 40;

  static const String studentRole = 'Student';
  static const String educatorRole = 'Educator';

  static const String _accessTokenKey = 'access_token';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  static Future<void> saveUser({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Preserve guest information created by older app versions before
    // replacing the active role with the registered account role.
    await _preserveLegacyGuestProfile(prefs);

    await Future.wait(<Future<bool>>[
      prefs.setInt(userIdKey, id),
      prefs.setString(firstNameKey, firstName.trim()),
      prefs.setString(lastNameKey, lastName.trim()),
      prefs.setString(emailKey, email.trim()),
      prefs.setString(roleKey, role.trim()),
      prefs.setBool(guestModeKey, false),
    ]);

    // Do not remove guestNicknameKey or guestRoleKey here.
    // The device Guest Profile must survive account sign-in.
  }

  static Future<void> saveAccessToken(String token) async {
    final String normalizedToken = token.trim();

    if (normalizedToken.isEmpty) {
      throw const FormatException('The authentication token cannot be empty.');
    }

    await _secureStorage.write(key: _accessTokenKey, value: normalizedToken);
  }

  static Future<String?> getAccessToken() async {
    final String? token = await _secureStorage.read(key: _accessTokenKey);

    return _normalizeOptionalText(token);
  }

  static Future<bool> hasAccessToken() async {
    return await getAccessToken() != null;
  }

  static Future<void> saveGuest({
    required String nickname,
    required String role,
  }) async {
    final String normalizedNickname = _normalizeGuestNickname(nickname);
    final String normalizedRole = _normalizeGuestRole(role);
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Save both the persistent Guest Profile and the active guest session.
    await Future.wait(<Future<bool>>[
      prefs.setString(guestNicknameKey, normalizedNickname),
      prefs.setString(guestRoleKey, normalizedRole),
      prefs.setBool(guestModeKey, true),
      prefs.setString(roleKey, normalizedRole),
    ]);

    await _removeRegisteredUserPreferences(prefs);

    await _secureStorage.delete(key: _accessTokenKey);
  }

  static Future<void> updateGuestProfile({
    required String nickname,
    required String role,
  }) async {
    final String normalizedNickname = _normalizeGuestNickname(nickname);
    final String normalizedRole = _normalizeGuestRole(role);

    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await _preserveLegacyGuestProfile(prefs);

    final bool guestIsActive = prefs.getBool(guestModeKey) ?? false;

    if (!guestIsActive) {
      throw StateError(
        'A guest profile can only be edited while Guest Mode is active.',
      );
    }

    final String? existingNickname = _normalizeOptionalText(
      prefs.getString(guestNicknameKey),
    );

    final String? existingRole = _normalizeOptionalText(
      prefs.getString(guestRoleKey),
    );

    if (existingNickname == null || existingRole == null) {
      throw StateError('No saved guest profile was found on this device.');
    }

    await Future.wait(<Future<bool>>[
      prefs.setString(guestNicknameKey, normalizedNickname),
      prefs.setString(guestRoleKey, normalizedRole),
      prefs.setString(roleKey, normalizedRole),
      prefs.setBool(guestModeKey, true),
    ]);
  }

  static Future<bool> hasGuestProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await _preserveLegacyGuestProfile(prefs);

    final String? nickname = _normalizeOptionalText(
      prefs.getString(guestNicknameKey),
    );

    final String? guestRole = _normalizeOptionalText(
      prefs.getString(guestRoleKey),
    );

    return nickname != null && guestRole != null;
  }

  static Future<bool> activateSavedGuest() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await _preserveLegacyGuestProfile(prefs);

    final String? nickname = _normalizeOptionalText(
      prefs.getString(guestNicknameKey),
    );

    final String? guestRole = _normalizeOptionalText(
      prefs.getString(guestRoleKey),
    );

    if (nickname == null || guestRole == null) {
      return false;
    }

    await _removeRegisteredUserPreferences(prefs);

    await Future.wait(<Future<bool>>[
      prefs.setBool(guestModeKey, true),
      prefs.setString(roleKey, guestRole),
    ]);

    await _secureStorage.delete(key: _accessTokenKey);

    return true;
  }

  static Future<void> logout() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // End only the active session. The persistent Guest Profile remains.
    await _removeRegisteredUserPreferences(prefs);

    await Future.wait(<Future<bool>>[
      prefs.remove(roleKey),
      prefs.remove(guestModeKey),
    ]);

    await _secureStorage.delete(key: _accessTokenKey);
  }

  static Future<void> resetGuestProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool guestIsActive = prefs.getBool(guestModeKey) ?? false;

    await Future.wait(<Future<bool>>[
      prefs.remove(guestNicknameKey),
      prefs.remove(guestRoleKey),
    ]);

    if (guestIsActive) {
      await Future.wait(<Future<bool>>[
        prefs.remove(roleKey),
        prefs.remove(guestModeKey),
      ]);
    }
  }

  static Future<bool> isLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    final bool guestIsActive = prefs.getBool(guestModeKey) ?? false;

    if (guestIsActive) {
      return false;
    }

    final bool hasUser = prefs.containsKey(userIdKey);
    final bool hasToken = await hasAccessToken();

    return hasUser && hasToken;
  }

  static Future<bool> isGuest() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(guestModeKey) ?? false;
  }

  static Future<int?> getUserId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getInt(userIdKey);
  }

  static Future<String?> getFirstName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return _normalizeOptionalText(prefs.getString(firstNameKey));
  }

  static Future<String?> getLastName() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return _normalizeOptionalText(prefs.getString(lastNameKey));
  }

  static Future<String?> getEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return _normalizeOptionalText(prefs.getString(emailKey));
  }

  static Future<String?> getRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return _normalizeOptionalText(prefs.getString(roleKey));
  }

  static Future<String?> getGuestNickname() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return _normalizeOptionalText(prefs.getString(guestNicknameKey));
  }

  static Future<String?> getGuestRole() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await _preserveLegacyGuestProfile(prefs);

    return _normalizeOptionalText(prefs.getString(guestRoleKey));
  }

  static Future<void> _removeRegisteredUserPreferences(
    SharedPreferences prefs,
  ) async {
    await Future.wait(<Future<bool>>[
      prefs.remove(userIdKey),
      prefs.remove(firstNameKey),
      prefs.remove(lastNameKey),
      prefs.remove(emailKey),
    ]);
  }

  static Future<void> _preserveLegacyGuestProfile(
    SharedPreferences prefs,
  ) async {
    final String? existingGuestRole = _normalizeOptionalText(
      prefs.getString(guestRoleKey),
    );

    if (existingGuestRole != null) {
      return;
    }

    final bool guestIsActive = prefs.getBool(guestModeKey) ?? false;

    if (!guestIsActive) {
      return;
    }

    final String? nickname = _normalizeOptionalText(
      prefs.getString(guestNicknameKey),
    );

    final String? activeRole = _normalizeOptionalText(prefs.getString(roleKey));

    if (nickname == null || activeRole == null) {
      return;
    }

    await prefs.setString(guestRoleKey, activeRole);
  }

  static String _normalizeGuestNickname(String nickname) {
    final String normalizedNickname = nickname.trim();

    if (normalizedNickname.isEmpty) {
      throw const FormatException('The guest nickname cannot be empty.');
    }

    if (normalizedNickname.length > guestNicknameMaximumLength) {
      throw const FormatException(
        'The guest nickname cannot exceed 40 characters.',
      );
    }

    return normalizedNickname;
  }

  static String _normalizeGuestRole(String role) {
    final String normalizedRole = role.trim().toLowerCase();

    return switch (normalizedRole) {
      'student' => studentRole,
      'educator' => educatorRole,
      _ => throw const FormatException(
        'The guest role must be Student or Educator.',
      ),
    };
  }

  static String? _normalizeOptionalText(String? value) {
    final String normalizedValue = value?.trim() ?? '';

    return normalizedValue.isEmpty ? null : normalizedValue;
  }
}
