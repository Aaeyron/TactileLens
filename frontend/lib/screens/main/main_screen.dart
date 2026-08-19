import 'package:flutter/material.dart';

import '../../styles/screens/main/main_styles.dart';
import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../materials/material_screen.dart';
import '../profile/profile_screen.dart';
import '../scan/scan_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
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
    return Scaffold(
      body: pages[currentIndex],
      floatingActionButton: currentIndex == 2
          ? null
          : Transform.translate(
              offset: MainStyles.fabOffset,
              child: FloatingActionButton(
                shape: const CircleBorder(),
                backgroundColor: MainStyles.fabBackgroundColor,
                elevation: MainStyles.fabElevation,
                onPressed: () {
                  _selectPage(2);
                },
                child: const Icon(
                  Icons.camera_alt,
                  size: MainStyles.fabIconSize,
                  color: MainStyles.fabIconColor,
                ),
              ),
            ),
      floatingActionButtonLocation: MainStyles.fabLocation,
      bottomNavigationBar: currentIndex == 2
          ? null
          : Container(
              decoration: BoxDecoration(
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
                child: SizedBox(
                  height: MainStyles.bottomBarHeight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          Icons.home,
                          size: MainStyles.iconSize,
                          color: currentIndex == 0
                              ? MainStyles.selectedItemColor
                              : MainStyles.unselectedItemColor,
                        ),
                        onPressed: () {
                          _selectPage(0);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.library_books,
                          size: MainStyles.iconSize,
                          color: currentIndex == 1
                              ? MainStyles.selectedItemColor
                              : MainStyles.unselectedItemColor,
                        ),
                        onPressed: () {
                          _selectPage(1);
                        },
                      ),
                      SizedBox(width: MainStyles.centerGapWidth),
                      IconButton(
                        icon: Icon(
                          Icons.history,
                          size: MainStyles.iconSize,
                          color: currentIndex == 3
                              ? MainStyles.selectedItemColor
                              : MainStyles.unselectedItemColor,
                        ),
                        onPressed: () {
                          _selectPage(3);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.person,
                          size: MainStyles.iconSize,
                          color: currentIndex == 4
                              ? MainStyles.selectedItemColor
                              : MainStyles.unselectedItemColor,
                        ),
                        onPressed: () {
                          _selectPage(4);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
