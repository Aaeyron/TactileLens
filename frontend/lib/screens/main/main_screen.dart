import 'package:flutter/material.dart';

import '../../styles/screens/main/main_screen_styles.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../materials/material_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  int previousIndex = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = <Widget>[
      HomeScreen(
        onScanPressed: () {
          _selectPage(2);
        },
        onMaterialsPressed: () {
          _selectPage(1);
        },
        onHistoryPressed: () {
          _selectPage(3);
        },
      ),
      MaterialsScreen(onBack: _returnToPreviousPage),
      ScanScreen(onBack: _returnToPreviousPage),
      HistoryScreen(onBack: _returnToPreviousPage),
      const ProfileScreen(),
    ];
  }

  void _selectPage(int index) {
    if (currentIndex == index) {
      return;
    }

    setState(() {
      previousIndex = currentIndex;
      currentIndex = index;
    });
  }

  void _returnToPreviousPage() {
    setState(() {
      currentIndex = previousIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    final bool shouldHideNavigation = currentIndex == 2 || isKeyboardVisible;

    return Scaffold(
      body: pages[currentIndex],
      floatingActionButton: shouldHideNavigation
          ? null
          : Transform.translate(
              offset: MainStyles.fabOffset,
              child: FloatingActionButton(
                shape: const CircleBorder(),
                backgroundColor: MainStyles.fabBackgroundColor,
                elevation: MainStyles.fabElevation,
                tooltip: MainStyles.scanTooltip,
                onPressed: () {
                  _selectPage(2);
                },
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: MainStyles.fabIconSize,
                  color: MainStyles.fabIconColor,
                ),
              ),
            ),
      floatingActionButtonLocation: MainStyles.fabLocation,
      bottomNavigationBar: shouldHideNavigation
          ? null
          : Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: MainStyles.navBorderColor,
                    width: MainStyles.navBorderWidth,
                  ),
                ),
              ),
              child: BottomAppBar(
                color: MainStyles.navBackgroundColor,
                elevation: MainStyles.navElevation,
                shape: MainStyles.bottomBarShape,
                notchMargin: MainStyles.fabMargin,
                padding: EdgeInsets.zero,
                child: SizedBox(
                  height: MainStyles.bottomBarHeight,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _MainNavigationItem(
                          icon: Icons.home_outlined,
                          selectedIcon: Icons.home_rounded,
                          label: MainStyles.homeLabel,
                          isSelected: currentIndex == 0,
                          onPressed: () {
                            _selectPage(0);
                          },
                        ),
                      ),
                      Expanded(
                        child: _MainNavigationItem(
                          icon: Icons.folder_outlined,
                          selectedIcon: Icons.folder_rounded,
                          label: MainStyles.materialsLabel,
                          isSelected: currentIndex == 1,
                          onPressed: () {
                            _selectPage(1);
                          },
                        ),
                      ),
                      const SizedBox(width: MainStyles.centerGapWidth),
                      Expanded(
                        child: _MainNavigationItem(
                          icon: Icons.history_outlined,
                          selectedIcon: Icons.history_rounded,
                          label: MainStyles.historyLabel,
                          isSelected: currentIndex == 3,
                          onPressed: () {
                            _selectPage(3);
                          },
                        ),
                      ),
                      Expanded(
                        child: _MainNavigationItem(
                          icon: Icons.person_outline_rounded,
                          selectedIcon: Icons.person_rounded,
                          label: MainStyles.profileLabel,
                          isSelected: currentIndex == 4,
                          onPressed: () {
                            _selectPage(4);
                          },
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

class _MainNavigationItem extends StatelessWidget {
  const _MainNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Color itemColor = isSelected
        ? MainStyles.selectedItemColor
        : MainStyles.unselectedItemColor;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Padding(
            padding: MainStyles.navigationItemPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: MainStyles.iconSize,
                  color: itemColor,
                ),
                const SizedBox(height: MainStyles.iconLabelSpacing),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: MainStyles.labelFontSize,
                    fontWeight: isSelected
                        ? MainStyles.selectedLabelWeight
                        : MainStyles.unselectedLabelWeight,
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
