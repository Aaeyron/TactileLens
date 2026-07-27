import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../../styles/screens/profile/profile_screen_styles.dart';
import '../../utils/session_manager.dart';
import '../../widgets/logout_dialog.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

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

  @override
Widget build(BuildContext context) {
  return Scaffold(
  body: Column(
    children: [
      const AppHeader(),

      Expanded(
        child: SingleChildScrollView(
          child: Padding(
            padding: ProfileStyles.screenPadding,
            child: Column(
              children: [
                SizedBox(
                  height: ProfileStyles.profileAvatarTopSpacing,
                ),

            CircleAvatar(
              radius: ProfileStyles.profileAvatarRadius,
              backgroundColor: ProfileStyles.profileAvatarBackgroundColor,
              child: Icon(
               ProfileStyles.profileAvatarIcon,
                size: ProfileStyles.profileAvatarIconSize,
                color: ProfileStyles.profileAvatarIconColor,
              ),
            ),

            SizedBox(
                height: ProfileStyles.profileNameTopSpacing,
              ),

              Text(
              "$firstName $lastName",
              style: ProfileStyles.profileNameStyle,
            ),

              SizedBox(
                height: ProfileStyles.profileEmailTopSpacing,
              ),

              Text(
              email,
              style: ProfileStyles.profileEmailStyle,
            ),
              SizedBox(
                height: ProfileStyles.menuTopSpacing,
              ),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    ProfileStyles.menuBorderRadius,
                  ),
                  boxShadow: ProfileStyles.menuShadow,
                ),
                child: Material(
                  color: ProfileStyles.menuBackgroundColor,
                  borderRadius: BorderRadius.circular(
                    ProfileStyles.menuBorderRadius,
                  ),
                  clipBehavior: ProfileStyles.menuClipBehavior, // Keeps the ripple inside the rounded corners
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.symmetric(
                        horizontal: ProfileStyles.menuHorizontalPadding,
                        vertical: ProfileStyles.menuVerticalPadding,
                      ),

                      minTileHeight: ProfileStyles.menuTileHeight,
                        leading: Icon(
                        Icons.history,
                        size: ProfileStyles.menuIconSize,
                        color: ProfileStyles.menuIconColor,
                      ),
                        title: Text(
                          ProfileStyles.activityTitle,
                          style: ProfileStyles.menuTitleStyle,
                        ),
                       trailing: Icon(
                        Icons.chevron_right,
                        size: ProfileStyles.menuArrowSize,
                        color: ProfileStyles.menuArrowColor,
                      ),
                        onTap: () {},
                      ),

                      Divider(
                      indent: ProfileStyles.menuDividerIndent,
                      endIndent: ProfileStyles.menuDividerIndent,
                      height: 1,
                      color: ProfileStyles.menuDividerColor,
                    ),

                      ListTile(
                        contentPadding: EdgeInsets.symmetric(
                        horizontal: ProfileStyles.menuHorizontalPadding,
                        vertical: ProfileStyles.menuVerticalPadding,
                      ),

                      minTileHeight: ProfileStyles.menuTileHeight,
                        leading: Icon(
                        Icons.bookmark_border,
                        size: ProfileStyles.menuIconSize,
                        color: ProfileStyles.menuIconColor,
                      ),
                        title: Text(
                         ProfileStyles.savedItemsTitle,
                          style: ProfileStyles.menuTitleStyle,
                        ),
                        trailing: Icon(
                        Icons.chevron_right,
                        size: ProfileStyles.menuArrowSize,
                        color: ProfileStyles.menuArrowColor,
                      ),
                        onTap: () {},
                      ),

                      Divider(
                      indent: ProfileStyles.menuDividerIndent,
                      endIndent: ProfileStyles.menuDividerIndent,
                      height: 1,
                      color: ProfileStyles.menuDividerColor,
                    ),

                      ListTile(
                        contentPadding: EdgeInsets.symmetric(
                        horizontal: ProfileStyles.menuHorizontalPadding,
                        vertical: ProfileStyles.menuVerticalPadding,
                      ),

                      minTileHeight: ProfileStyles.menuTileHeight,
                        leading: Icon(
                        Icons.description_outlined,
                        size: ProfileStyles.menuIconSize,
                        color: ProfileStyles.menuIconColor,
                      ),
                        title: Text(
                        ProfileStyles.termsTitle,
                          style: ProfileStyles.menuTitleStyle,
                        ),
                       trailing: Icon(
                        Icons.chevron_right,
                        size: ProfileStyles.menuArrowSize,
                        color: ProfileStyles.menuArrowColor,
                      ),
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(
              height: ProfileStyles.secondaryMenuTopSpacing,
            ),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  ProfileStyles.menuBorderRadius,
                ),
                boxShadow: ProfileStyles.menuShadow,
              ),
              child: Material(
                color: ProfileStyles.menuBackgroundColor,
                borderRadius: BorderRadius.circular(
                  ProfileStyles.menuBorderRadius,
                ),
                clipBehavior: ProfileStyles.menuClipBehavior,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ProfileStyles.menuHorizontalPadding,
                        vertical: ProfileStyles.menuVerticalPadding,
                      ),
                      minTileHeight: ProfileStyles.menuTileHeight,
                      leading: Icon(
                        Icons.settings_outlined,
                        size: ProfileStyles.menuIconSize,
                        color: ProfileStyles.menuIconColor,
                      ),
                      title: Text(
                        ProfileStyles.settingsTitle,
                        style: ProfileStyles.menuTitleStyle,
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: ProfileStyles.menuArrowSize,
                        color: ProfileStyles.menuArrowColor,
                      ),
                      onTap: () {},
                    ),

                    Divider(
                      indent: ProfileStyles.menuDividerIndent,
                      endIndent: ProfileStyles.menuDividerIndent,
                      height: 1,
                      color: ProfileStyles.menuDividerColor,
                    ),

                    ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: ProfileStyles.menuHorizontalPadding,
                        vertical: ProfileStyles.menuVerticalPadding,
                      ),
                      minTileHeight: ProfileStyles.menuTileHeight,
                      leading: Icon(
                        Icons.shield_outlined,
                        size: ProfileStyles.menuIconSize,
                        color: ProfileStyles.menuIconColor,
                      ),
                      title: Text(
                        ProfileStyles.privacyTitle,
                        style: ProfileStyles.menuTitleStyle,
                      ),
                      trailing: Icon(
                        Icons.chevron_right,
                        size: ProfileStyles.menuArrowSize,
                        color: ProfileStyles.menuArrowColor,
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

                              SizedBox(
                                height: ProfileStyles.logoutMenuTopSpacing,
                              ),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  ProfileStyles.menuBorderRadius,
                                ),
                                boxShadow: ProfileStyles.menuShadow,
                              ),
                              child: Material(
                                color: ProfileStyles.menuBackgroundColor,
                                borderRadius: BorderRadius.circular(
                                  ProfileStyles.menuBorderRadius,
                                ),
                                clipBehavior: ProfileStyles.menuClipBehavior,
                              child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: ProfileStyles.menuHorizontalPadding,
                                vertical: ProfileStyles.menuVerticalPadding,
                              ),
                              minTileHeight: ProfileStyles.menuTileHeight,

                              leading: Icon(
                                Icons.logout_rounded,
                                size: ProfileStyles.menuIconSize,
                                color: ProfileStyles.logoutIconColor,
                              ),

                              title: Text(
                                ProfileStyles.logoutTitle,
                                style: ProfileStyles.logoutTitleStyle,
                              ),

                              trailing: Icon(
                                Icons.chevron_right,
                                size: ProfileStyles.menuArrowSize,
                                color: ProfileStyles.logoutIconColor,
                              ),

                              onTap: () {
                                showLogoutDialog(context);
                              },
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ),
             ],
            ),
          );
        }
      }