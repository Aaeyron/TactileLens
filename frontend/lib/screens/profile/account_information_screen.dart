import 'package:flutter/material.dart';
import '../../styles/screens/profile/account_information_screen_styles.dart';
import '../../utils/session_manager.dart';

class AccountInformationScreen extends StatefulWidget {
  const AccountInformationScreen({super.key});

  @override
  State<AccountInformationScreen> createState() =>
      _AccountInformationScreenState();
}

class _AccountInformationScreenState
    extends State<AccountInformationScreen> {

  String firstName = "";
  String lastName = "";
  String email = "";
  String role = "";

  bool isGuest = false;
  String guestNickname = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
  isGuest = await SessionManager.isGuest();

  if (isGuest) {
    guestNickname =
        await SessionManager.getGuestNickname() ?? "";

    role =
        await SessionManager.getRole() ?? "";
  } else {
    firstName =
        await SessionManager.getFirstName() ?? "";

    lastName =
        await SessionManager.getLastName() ?? "";

    email =
        await SessionManager.getEmail() ?? "";

    role =
        await SessionManager.getRole() ?? "";
  }

  setState(() {});
}

 Widget buildInfoTile({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Padding(
    padding: AccountInformationStyles.infoTilePadding,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Padding(
          padding: AccountInformationStyles.infoIconPadding,
          child: Icon(
            icon,
            size: AccountInformationStyles.infoIconSize,
            color: AccountInformationStyles.appPrimaryColor,
          ),
        ),

        SizedBox(width: AccountInformationStyles.infoTileSpacing),

        Expanded(
          child: Padding(
            padding: AccountInformationStyles.infoTextPadding,
            child: Text(
              title,
              style: AccountInformationStyles.infoTitleStyle,
            ),
          ),
        ),

        Padding(
          padding: AccountInformationStyles.infoTextPadding,
          child: Text(
            value,
            style: AccountInformationStyles.infoValueStyle,
          ),
        ),
      ],
    ),
  );
} 

 @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: AccountInformationStyles.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  AccountInformationStyles.backIcon,
                  size: AccountInformationStyles.backIconSize,
                  color: AccountInformationStyles.primaryTextColor,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
             SizedBox(
                width: AccountInformationStyles.headerSpacing,
              ),

              Text(
                AccountInformationStyles.screenTitle,
                style: AccountInformationStyles.screenTitleStyle,
              ),
            ],
          ),

         SizedBox(
            height: AccountInformationStyles.headerBottomSpacing,
          ),

           Container(
                width: double.infinity,
                padding: AccountInformationStyles.profileCardPadding,
                decoration: BoxDecoration(
                color: AccountInformationStyles.profileCardBackgroundColor,
                 borderRadius: BorderRadius.circular(
                  AccountInformationStyles.profileCardBorderRadius,
                 ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    CircleAvatar(
                      radius: AccountInformationStyles.profileAvatarRadius,
                      backgroundColor: Colors.white24,
                      child: const Icon(
                        Icons.person,
                        size: 38,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 18),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          Text(
                            isGuest
                                ? guestNickname
                                : "$firstName $lastName",
                            style: AccountInformationStyles.profileNameStyle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(
              height: AccountInformationStyles.headerBottomSpacing,
            ),


              Container(
                decoration: AccountInformationStyles.cardDecoration,
               child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Padding(
                      padding: AccountInformationStyles.personalDetailsPadding,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Text(
                            AccountInformationStyles.personalDetailsTitle,
                            style: AccountInformationStyles.personalDetailsTitleStyle,
                          ),

                          if (!isGuest)
                          InkWell(
                            onTap: () {
                              // TODO: Navigate to Edit Account
                            },
                            borderRadius: BorderRadius.circular(
                              AccountInformationStyles.editButtonRadius,
                            ),
                            child: Container(
                              padding: AccountInformationStyles.editButtonPadding,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                  AccountInformationStyles.editButtonRadius,
                                ),
                                border: Border.all(
                                  color: AccountInformationStyles.appPrimaryColor,
                                  width:
                                      AccountInformationStyles.editButtonBorderWidth,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  Icon(
                                    AccountInformationStyles.editButtonIcon,
                                    size:
                                        AccountInformationStyles.editButtonIconSize,
                                    color:
                                        AccountInformationStyles.appPrimaryColor,
                                  ),

                                  const SizedBox(width: 6),

                                  Text(
                                    AccountInformationStyles.editButtonTitle,
                                    style:
                                        AccountInformationStyles.editButtonStyle,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),

                        if (isGuest) ...[
                          buildInfoTile(
                            icon: Icons.person_outline_rounded,
                            title: "Nickname",
                            value: guestNickname,
                          ),

                          Divider(
                            color: AccountInformationStyles.dividerColor,
                            thickness: AccountInformationStyles.dividerThickness,
                          ),

                          buildInfoTile(
                            icon: Icons.badge_outlined,
                            title: "Role",
                            value: role,
                          ),

                          Divider(
                            color: AccountInformationStyles.dividerColor,
                            thickness: AccountInformationStyles.dividerThickness,
                          ),

                          buildInfoTile(
                            icon: Icons.wifi_off_rounded,
                            title: "Account Type",
                            value: "Offline Guest",
                          ),
                        ] else ...[
                          buildInfoTile(
                            icon: Icons.person_outline_rounded,
                            title: "Full Name",
                            value: "$firstName $lastName",
                          ),

                          Divider(
                            color: AccountInformationStyles.dividerColor,
                            thickness: AccountInformationStyles.dividerThickness,
                          ),

                          buildInfoTile(
                            icon: Icons.email_outlined,
                            title: "Email Address",
                            value: email,
                          ),

                          Divider(
                            color: AccountInformationStyles.dividerColor,
                            thickness: AccountInformationStyles.dividerThickness,
                          ),

                          buildInfoTile(
                            icon: Icons.lock_outline_rounded,
                            title: "Password",
                            value: "••••••••",
                          ),

                          Divider(
                            color: AccountInformationStyles.dividerColor,
                            thickness: AccountInformationStyles.dividerThickness,
                          ),

                          buildInfoTile(
                            icon: Icons.badge_outlined,
                            title: "Role",
                            value: role,
                          ),
                        ],
                      ],
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