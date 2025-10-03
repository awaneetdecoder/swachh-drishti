import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'auth_screen.dart';
import 'screens/activity_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/reporter_screen.dart';
import 'theme_notifier.dart';
import 'widget/app_logo.dart';
import 'services/secure_storage_service.dart';
import 'api_config.dart';

/// The main shell of the application which handles the overall layout,
/// including the responsive navigation and the AppBar. It fetches and displays
/// the logged-in user's information.
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // State variables to hold the user's data for the drawer header.
  String _userName = 'Loading...';
  String _userEmail = 'Please wait';

  @override
  void initState() {
    super.initState();
    // When this screen loads for the first time, fetch the user's profile data.
    _fetchUserProfile();
  }

  /// Fetches the user's profile from the backend to display their name and email.
  Future<void> _fetchUserProfile() async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return; // Can't fetch if not logged in.

      final response = await http.get(
        Uri.parse(ApiConfig.getMe),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        // Update the state to rebuild the drawer with the real user data.
        setState(() {
          _userName = data['name'];
          _userEmail = data['email'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = 'Error';
          _userEmail = 'Could not load user data';
        });
      }
    }
  }

  /// Handles navigation when a tab is tapped.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.jumpToPage(index);
    });
  }

  /// Handles the secure logout process.
  Future<void> _handleLogout() async {
    // 1. Delete the user's saved token from the device's secure storage.
    await SecureStorageService.deleteToken();

    // 2. Navigate back to the login screen and remove all previous screens.
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder is the key to a responsive UI.
    return LayoutBuilder(
      builder: (context, constraints) {
        // --- WIDE SCREEN LAYOUT (WEB/TABLET) ---
        if (constraints.maxWidth > 600) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Swachh App'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: Icon(Provider.of<ThemeNotifier>(context).isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                  onPressed: () => Provider.of<ThemeNotifier>(context, listen: false).toggleTheme(),
                ),
                TextButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                  
                  // --- THIS IS THE FIX ---
                  // We check the theme's brightness to set the correct color.
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white // Use white color in Dark Mode
                        : Colors.black87, // Use a dark color in Light Mode
                  ),
                  // --- END OF FIX ---
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onItemTapped,
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: AppLogo(radius: 25, iconSize: 25)),
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: Text('Home')),
                    NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('Activity')),
                    NavigationRailDestination(icon: Icon(Icons.camera_alt_outlined), selectedIcon: Icon(Icons.camera_alt), label: Text('Report')),
                    NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _selectedIndex = index),
                    children: const [HomeScreen(), ActivityScreen(), GarbageReporterScreen(), ProfileScreen()],
                  ),
                ),
              ],
            ),
          );
        }
        // --- NARROW SCREEN LAYOUT (MOBILE) ---
        else {
          return Scaffold(
            appBar: AppBar(title: const Text('Swachh App')),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(_userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    accountEmail: Text(_userEmail),
                    currentAccountPicture: const CircleAvatar(
                      backgroundColor: Colors.white,
                      child: AppLogo(radius: 28, iconSize: 28),
                    ),
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary),
                  ),
                  ListTile(leading: const Icon(Icons.home_outlined), title: const Text('Home'), onTap: () { _onItemTapped(0); Navigator.pop(context); }),
                  ListTile(leading: const Icon(Icons.history_outlined), title: const Text('Activity'), onTap: () { _onItemTapped(1); Navigator.pop(context); }),
                  ListTile(leading: const Icon(Icons.camera_alt_outlined), title: const Text('Report Garbage'), onTap: () { _onItemTapped(2); Navigator.pop(context); }),
                  ListTile(leading: const Icon(Icons.person_outline), title: const Text('Profile'), onTap: () { _onItemTapped(3); Navigator.pop(context); }),
                  const Divider(),
                  ListTile(leading: const Icon(Icons.logout), title: const Text('Logout'), onTap: _handleLogout),
                ],
              ),
            ),
            body: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _selectedIndex = index),
              children: const [HomeScreen(), ActivityScreen(), GarbageReporterScreen(), ProfileScreen()],
            ),
            bottomNavigationBar: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Theme.of(context).colorScheme.surface,
              selectedItemColor: Theme.of(context).colorScheme.primary,
              unselectedItemColor: const Color.fromARGB(255, 154, 153, 153), // Fixes the unselected icon color
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Activity'),
                BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Report'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          );
        }
      },
    );
  }
}

