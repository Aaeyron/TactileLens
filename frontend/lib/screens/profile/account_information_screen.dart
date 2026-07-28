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

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    firstName = await SessionManager.getFirstName() ?? "";
    lastName = await SessionManager.getLastName() ?? "";
    email = await SessionManager.getEmail() ?? "";

    setState(() {});
  }

 Widget buildInfoTile(
  IconData icon,
  String title,
  String value,
) {
  return Padding(
 padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Icon(
            icon,
            size: AccountInformationStyles.infoIconSize,
            color: AccountInformationStyles.appPrimaryColor,
          ),
        ),
        const SizedBox(width: 14),

        Expanded(
        child: Padding(
         padding: const EdgeInsets.only(top: 8),
          child: Text(
            title,
            style: AccountInformationStyles.infoTitleStyle,
          ),
        ),
      ),

        Padding(
       padding: const EdgeInsets.only(top: 8),
        child: Text(
          value,
          style: AccountInformationStyles.infoValueStyle,
          textAlign: TextAlign.end,
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
                            "$firstName $lastName",
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
                                  width: AccountInformationStyles.editButtonBorderWidth,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  Icon(
                                    AccountInformationStyles.editButtonIcon,
                                    size: AccountInformationStyles.editButtonIconSize,
                                    color: AccountInformationStyles.appPrimaryColor,
                                  ),

                                  const SizedBox(width: 6),

                                  Text(
                                    AccountInformationStyles.editButtonTitle,
                                    style: AccountInformationStyles.editButtonStyle,
                                  ),

                                ],
                              ),
                            ),
                          ),

                        ],
                      ),
                    ),
                  const SizedBox(height: 6),

                    Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Icon(
                            Icons.person_outline_rounded,
                            size: AccountInformationStyles.infoIconSize,
                            color: AccountInformationStyles.appPrimaryColor,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Text(
                              "Full Name",
                              style: AccountInformationStyles.infoTitleStyle,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Text(
                            "$firstName $lastName",
                            style: AccountInformationStyles.infoValueStyle,
                          ),
                        ),
                      ],
                    ),
                  ),

                   Divider(
                    color: AccountInformationStyles.dividerColor,
                    thickness: AccountInformationStyles.dividerThickness,
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Icon(
                            Icons.email_outlined,
                            size: AccountInformationStyles.infoIconSize,
                            color: AccountInformationStyles.appPrimaryColor,
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 18),
                            child: Text(
                              "Email Address",
                              style: AccountInformationStyles.infoTitleStyle,
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Text(
                            email,
                            style: AccountInformationStyles.infoValueStyle,
                          ),
                        ),

                      ],
                    ),
                  ),

                  Divider(
                    color: AccountInformationStyles.dividerColor,
                    thickness: AccountInformationStyles.dividerThickness,
                  ),
                  
                    Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  size: AccountInformationStyles.infoIconSize,
                                  color: AccountInformationStyles.appPrimaryColor,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 18),
                                  child: Text(
                                    "Password",
                                    style: AccountInformationStyles.infoTitleStyle,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Text(
                                  "••••••••",
                                  style: AccountInformationStyles.infoValueStyle,
                                ),
                              ),

                            ],
                          ),
                        ),

                        Divider(
                          color: AccountInformationStyles.dividerColor,
                          thickness: AccountInformationStyles.dividerThickness,
                        ),

                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Icon(
                                  Icons.badge_outlined,
                                  size: AccountInformationStyles.infoIconSize,
                                  color: AccountInformationStyles.appPrimaryColor,
                                ),
                              ),

                              const SizedBox(width: 14),

                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 18),
                                  child: Text(
                                    "Role",
                                    style: AccountInformationStyles.infoTitleStyle,
                                  ),
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Text(
                                  "Student",
                                  style: AccountInformationStyles.infoValueStyle,
                                ),
                              ),
                            ],
                          ),
                        ),
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