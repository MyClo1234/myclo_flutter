import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_helper.dart';
import 'home_screen.dart';
import 'wardrobe_screen.dart';
import 'profile_screen.dart';
import '../widgets/custom_navbar.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const WardrobeScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWeb = ResponsiveHelper.isWeb(context);

    return Scaffold(
      body: Row(
        children: [
          if (isWeb)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() => _currentIndex = index);
              },
              backgroundColor: AppTheme.bgDark,
              indicatorColor: AppTheme.primary.withOpacity(0.1),
              selectedIconTheme: const IconThemeData(color: AppTheme.primary),
              unselectedIconTheme: const IconThemeData(
                color: AppTheme.textMuted,
              ),
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(LucideIcons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.shirt),
                  label: Text('Wardrobe'),
                ),
                NavigationRailDestination(
                  icon: Icon(LucideIcons.user),
                  label: Text('Profile'),
                ),
              ],
            ),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: isWeb
          ? null
          : CustomNavbar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
    );
  }
}
