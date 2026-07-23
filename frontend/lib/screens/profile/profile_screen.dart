import 'package:flutter/material.dart';
import '../../styles/screens/profile/profile_styles.dart';
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
    return SafeArea(
      child: SingleChildScrollView(
      child: Padding(
        padding: ProfileStyles.screenPadding,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    // TODO: Back navigation will be implemented later.
                  },
                  icon: Icon(
                    Icons.arrow_back,
                    size: ProfileStyles.backIconSize,
                    color: ProfileStyles.backIconColor,
                  ),
                ),

                Expanded(
                  child: Text(
                    ProfileStyles.screenTitle,
                    textAlign: TextAlign.center,
                    style: ProfileStyles.titleStyle,
                  ),
                ),

                SizedBox(
                  width: ProfileStyles.titleRightSpacing,
                ),
              ],
            ),

            SizedBox(
              height: ProfileStyles.profileAvatarTopSpacing,
            ),

            CircleAvatar(
              radius: ProfileStyles.profileAvatarRadius,
              backgroundColor: ProfileStyles.profileAvatarBackgroundColor,
              child: Icon(
                Icons.person,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: ProfileStyles.menuBackgroundColor,
                  borderRadius: BorderRadius.circular(
                    ProfileStyles.menuBorderRadius,
                  ),
                  clipBehavior: Clip.antiAlias, // Keeps the ripple inside the rounded corners
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
                          "My Activity hahaha",
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
                          "Saved Items",
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
                          "Terms & Policy",
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: ProfileStyles.menuBackgroundColor,
                borderRadius: BorderRadius.circular(
                  ProfileStyles.menuBorderRadius,
                ),
                clipBehavior: Clip.antiAlias,
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
                        "Settings",
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
                        "Privacy & Security",
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: ProfileStyles.menuBackgroundColor,
                borderRadius: BorderRadius.circular(
                  ProfileStyles.menuBorderRadius,
                ),
                clipBehavior: Clip.antiAlias,
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
                    "Log Out",
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
          );
        }
      }