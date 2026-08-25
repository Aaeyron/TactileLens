import 'package:flutter/material.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  static const String _logoAsset = 'assets/icons/tactilelens_app_icon.png';

  static const Color _backgroundColor = Colors.white;
  static const Color _iconColor = Color(0xFF082F6B);
  static const Color _outlineColor = Color(0xFFDCE8FA);

  static const Color _notificationBackgroundColor = Color(0xFFF2F4F7);

  static const Color _notificationOutlineColor = Color(0xFFD0D5DD);

  static const double _headerContentHeight = 100;
  static const double _logoSize = 35;
  static const double _notificationButtonSize = _logoSize;
  static const double _notificationIconSize = 21;

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
                    width: _logoSize,
                    height: _logoSize,
                    fit: BoxFit.cover,
                  ),
                ),
                const Spacer(),
                Tooltip(
                  message: 'Notifications',
                  child: Material(
                    color: _notificationBackgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: _notificationOutlineColor,
                        width: 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: null,
                      borderRadius: BorderRadius.circular(10),
                      child: const SizedBox(
                        width: _notificationButtonSize,
                        height: _notificationButtonSize,
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: _notificationIconSize,
                          color: _iconColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
