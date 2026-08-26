import 'package:flutter/material.dart';

import '../utils/session_manager.dart';

class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() {
    return _AppHeaderState();
  }
}

class _AppHeaderState extends State<AppHeader> {
  static const String _logoAsset = 'assets/icons/tactilelens_app_icon.png';

  static const Color _backgroundColor = Colors.white;
  static const Color _iconColor = Color(0xFF082F6B);
  static const Color _outlineColor = Color(0xFFDCE8FA);

  static const Color _notificationBackgroundColor = Color(0xFFF2F4F7);

  static const Color _notificationOutlineColor = Color(0xFFD0D5DD);

  static const Color _profileBackgroundColor = Color(0xFFEAF2FF);

  static const Color _profileOutlineColor = Color(0xFFB9D2F5);

  static const Color _profileTextColor = Color(0xFF0D47A1);

  static const double _headerContentHeight = 100;
  static const double _controlSize = 35;
  static const double _notificationIconSize = 21;
  static const double _profileFontSize = 12;
  static const double _actionSpacing = 10;

  late final Future<String> _initialsFuture;

  @override
  void initState() {
    super.initState();
    _initialsFuture = _loadUserInitials();
  }

  Future<String> _loadUserInitials() async {
    final bool isGuest = await SessionManager.isGuest();

    if (isGuest) {
      final String nickname =
          (await SessionManager.getGuestNickname())?.trim() ?? '';

      return _createInitialsFromDisplayName(nickname);
    }

    final String firstName =
        (await SessionManager.getFirstName())?.trim() ?? '';

    final String lastName = (await SessionManager.getLastName())?.trim() ?? '';

    return _createInitials(firstName: firstName, lastName: lastName);
  }

  String _createInitials({
    required String firstName,
    required String lastName,
  }) {
    final String firstInitial = _firstCharacter(firstName);
    final String lastInitial = _firstCharacter(lastName);

    final String initials = '$firstInitial$lastInitial';

    return initials.isEmpty ? 'U' : initials;
  }

  String _createInitialsFromDisplayName(String displayName) {
    final List<String> nameParts = displayName
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList(growable: false);

    if (nameParts.isEmpty) {
      return 'G';
    }

    final String firstInitial = _firstCharacter(nameParts.first);

    if (nameParts.length == 1) {
      return firstInitial;
    }

    final String lastInitial = _firstCharacter(nameParts.last);

    return '$firstInitial$lastInitial';
  }

  String _firstCharacter(String value) {
    final String normalizedValue = value.trim();

    if (normalizedValue.isEmpty) {
      return '';
    }

    return normalizedValue.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _backgroundColor,
        border: Border(bottom: BorderSide(color: _outlineColor, width: 1)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0D0D47A1),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _headerContentHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    _logoAsset,
                    width: _controlSize,
                    height: _controlSize,
                    fit: BoxFit.cover,
                  ),
                ),
                const Spacer(),
                _buildNotificationButton(),
                const SizedBox(width: _actionSpacing),
                _buildProfileAvatar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton() {
    return Tooltip(
      message: 'Notifications',
      child: Material(
        color: _notificationBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: _notificationOutlineColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: null,
          borderRadius: BorderRadius.circular(10),
          child: const SizedBox(
            width: _controlSize,
            height: _controlSize,
            child: Icon(
              Icons.notifications_none_rounded,
              size: _notificationIconSize,
              color: _iconColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Tooltip(
      message: 'Profile',
      child: FutureBuilder<String>(
        future: _initialsFuture,
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          final String initials = snapshot.data ?? '';

          return Container(
            width: _controlSize,
            height: _controlSize,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _profileBackgroundColor,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: _profileOutlineColor, width: 1),
              ),
            ),
            child: snapshot.connectionState == ConnectionState.waiting
                ? const Icon(
                    Icons.person_outline_rounded,
                    size: 19,
                    color: _profileTextColor,
                  )
                : Text(
                    initials,
                    style: const TextStyle(
                      color: _profileTextColor,
                      fontSize: _profileFontSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          );
        },
      ),
    );
  }
}
