import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../api_config.dart';
import '../services/secure_storage_service.dart';
import '../theme_notifier.dart';
import '../widget/app_logo.dart';

// A simple model to hold user data
class UserModel {
  final String name;
  final String email;
  UserModel({required this.name, required this.email});
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<UserModel?>? _userFuture;

  @override
  void initState() {
    super.initState();
    // When the screen loads, fetch the user's profile data
    _userFuture = _fetchUserProfile();
  }

  /// Fetches the logged-in user's profile from the backend.
  Future<UserModel?> _fetchUserProfile() async {
    try {
      final token = await SecureStorageService.getToken();
      if (token == null) return null; // Not logged in

      final response = await http.get(
        Uri.parse(ApiConfig.getMe), // The new endpoint we created
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return UserModel(name: data['name'], email: data['email']);
      } else {
        // Handle error
        return null;
      }
    } catch (e) {
      // Handle error
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          // While fetching data, show a loading spinner
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // If there was an error or no user data
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Could not load profile.'));
          }

          // Once data is fetched, display it
          final user = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const AppLogo(radius: 50, iconSize: 50),
                const SizedBox(height: 12),
                // --- DYNAMIC DATA ---
                Text(user.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text(user.email, style: TextStyle(fontSize: 16, color: Colors.grey[400])),
                // --- END OF DYNAMIC DATA ---
                const SizedBox(height: 32),
                Card(
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text("Your Swachh-Coin Balance", style: TextStyle(fontSize: 18, color: Theme.of(context).textTheme.bodySmall?.color)),
                        const SizedBox(height: 12),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.monetization_on, color: Colors.amber, size: 40),
                            SizedBox(width: 12),
                            Text("150", style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        // ... rest of the card ...
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 20),
                Card(
                  child: SwitchListTile(
                    title: const Text("Dark Mode"),
                    secondary: Icon(Provider.of<ThemeNotifier>(context).isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                    value: Provider.of<ThemeNotifier>(context).isDarkMode,
                    onChanged: (value) {
                      Provider.of<ThemeNotifier>(context, listen: false).toggleTheme();
                    },
                  ),
                ),
                // ... rest of your UI ...
              ],
            ),
          );
        },
      ),
    );
  }
}

