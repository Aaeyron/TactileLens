import 'package:flutter/material.dart';

import '../../utils/session_manager.dart';
import '../../screens/auth/signin_screen.dart';
import '../../styles/widgets/profile/logout_dialog_styles.dart';

Future<void> showLogoutDialog(BuildContext context) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(
            LogoutDialogStyles.dialogBorderRadius,
          ),
        ),

        title: const Row(
          children: [
            Icon(
              LogoutDialogStyles.logoutIcon,
              color: LogoutDialogStyles.logoutIconColor,
            ),
          SizedBox(
            width: LogoutDialogStyles.titleIconSpacing,
          ),
           Text(
              LogoutDialogStyles.dialogTitle,
            ),
          ],
        ),

        content: const Text(
          LogoutDialogStyles.dialogMessage,
        ),

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
           child: const Text(
              LogoutDialogStyles.cancelButtonText,
            ),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
               LogoutDialogStyles.logoutButtonColor,

              foregroundColor:
               LogoutDialogStyles.logoutButtonTextColor,
             ),
            onPressed: () async {
              await SessionManager.logout();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const SignInScreen(),
                ),
                (route) => false,
              );
            },
           child: const Text(
              LogoutDialogStyles.confirmButtonText,
            ),
          ),
        ],
      );
    },
  );
}