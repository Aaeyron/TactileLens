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
    String title,
    String value,
  ) {
    return Padding(
      padding: AccountInformationStyles.infoTilePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: AccountInformationStyles.infoTitleStyle,
          ),

          const SizedBox(height: 6),

          Text(
            value,
            style: AccountInformationStyles.infoValueStyle,
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
              const SizedBox(width: 12),

              Text(
                AccountInformationStyles.screenTitle,
                style: AccountInformationStyles.screenTitleStyle,
              ),
            ],
          ),

          const SizedBox(height: 24),

           Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                color: AccountInformationStyles.profileCardBackgroundColor,  // App dark blue
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    CircleAvatar(
                      radius: 34,
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
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),


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
                                  width: 1.2,
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
                    const Divider(),

                    buildInfoTile(
                      "Full Name",
                      "$firstName $lastName",
                    ),

                    const Divider(),

                    buildInfoTile(
                      "Email Address",
                      email,
                    ),

                    const Divider(),

                    buildInfoTile(
                      "Password",
                      "••••••••",
                    ),

                    const Divider(),

                    buildInfoTile(
                      "Account Status",
                      "Active",
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