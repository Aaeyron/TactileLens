import 'package:flutter/material.dart';

import '../../styles/screens/main/main_screen_styles.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../materials/material_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_screen.dart';
import 'tab_data_cache.dart';

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

  // 1: the new tab enters from the right (higher index), -1: from the left.
  double _slideDirection = 1;

  // Lives as long as this session's MainScreen, so logging out (which
  // removes MainScreen) discards it.
  final TabDataCache _tabDataCache = TabDataCache();

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = <Widget>[
      HomeScreen(
        cache: _tabDataCache,
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
      MaterialsScreen(cache: _tabDataCache, onBack: _returnToPreviousPage),
      ScanScreen(onBack: _returnToPreviousPage),
      HistoryScreen(cache: _tabDataCache, onBack: _returnToPreviousPage),
      ProfileScreen(cache: _tabDataCache),
    ];
  }

  @override
  void dispose() {
    _tabDataCache.clear();
    super.dispose();
  }

  void _selectPage(int index) {
    if (currentIndex == index) {
      return;
    }

    setState(() {
      _slideDirection = index > currentIndex ? 1 : -1;
      previousIndex = currentIndex;
      currentIndex = index;
    });
  }

  void _returnToPreviousPage() {
    setState(() {
      _slideDirection = previousIndex > currentIndex ? 1 : -1;
      currentIndex = previousIndex;
    });
  }

  /// Slides the selected tab in horizontally while the previous one slides
  /// out the other way. The previous tab is disposed when its slide ends,
  /// so tabs still reload on return and the Scan tab still releases the
  /// camera when left. Reduced motion switches instantly.
  Widget _buildTabBody(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final Key currentKey = ValueKey<int>(currentIndex);

    return AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : MainStyles.tabSlideDuration,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(children: <Widget>[...previousChildren, ?currentChild]);
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        // The outgoing tab runs this animation in reverse, so it leaves
        // toward the side opposite to where the new tab comes from.
        final double startX = child.key == currentKey
            ? _slideDirection
            : -_slideDirection;

        return SlideTransition(
          position: Tween<Offset>(begin: Offset(startX, 0), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: animation,
                  curve: MainStyles.tabSlideCurve,
                ),
              ),
          child: child,
        );
      },
      child: KeyedSubtree(key: currentKey, child: pages[currentIndex]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;

    final bool shouldHideNavigation = currentIndex == 2 || isKeyboardVisible;

    return Scaffold(
      body: _buildTabBody(context),
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
