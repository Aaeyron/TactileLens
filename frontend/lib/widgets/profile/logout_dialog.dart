import 'package:flutter/material.dart';

import '../../screens/auth/auth_screen.dart';
import '../../services/auth/google_sign_in_service.dart';
import '../../styles/widgets/profile/logout_dialog_styles.dart';
import '../../utils/session_manager.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  final BuildContext rootContext = context;
  bool isLoggingOut = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) {
          Future<void> confirmLogout() async {
            if (isLoggingOut) {
              return;
            }

            setDialogState(() {
              isLoggingOut = true;
            });

            try {
              // Google sign-out is best effort. The local TactileLens
              // session must still end if Google sign-out is unavailable.
              try {
                await GoogleSignInService.signOut();
              } catch (error, stackTrace) {
                debugPrint('Google provider sign-out failed: $error');
                debugPrintStack(stackTrace: stackTrace);
              }

              await SessionManager.logout();

              if (!rootContext.mounted) {
                return;
              }

              Navigator.of(rootContext).pushAndRemoveUntil<void>(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) {
                    return const AuthScreen();
                  },
                ),
                (Route<dynamic> route) => false,
              );
            } catch (error, stackTrace) {
              debugPrint('Logout failed: $error');
              debugPrintStack(stackTrace: stackTrace);

              if (!dialogContext.mounted) {
                return;
              }

              setDialogState(() {
                isLoggingOut = false;
              });

              ScaffoldMessenger.of(rootContext)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Text('Unable to log out. Please try again.'),
                  ),
                );
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                LogoutDialogStyles.dialogBorderRadius,
              ),
            ),
            title: const Row(
              children: <Widget>[
                Icon(
                  LogoutDialogStyles.logoutIcon,
                  color: LogoutDialogStyles.logoutIconColor,
                ),
                SizedBox(width: LogoutDialogStyles.titleIconSpacing),
                Text(LogoutDialogStyles.dialogTitle),
              ],
            ),
            content: const Text(LogoutDialogStyles.dialogMessage),
            actions: <Widget>[
              TextButton(
                onPressed: isLoggingOut
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                      },
                child: const Text(LogoutDialogStyles.cancelButtonText),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: LogoutDialogStyles.logoutButtonColor,
                  foregroundColor: LogoutDialogStyles.logoutButtonTextColor,
                ),
                onPressed: isLoggingOut ? null : confirmLogout,
                child: isLoggingOut
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: LogoutDialogStyles.logoutButtonTextColor,
                        ),
                      )
                    : const Text(LogoutDialogStyles.confirmButtonText),
              ),
            ],
          );
        },
      );
    },
  );
}
