import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_screen.dart';
import 'main_shell.dart';
import 'services/secure_storage_service.dart';
import 'theme_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const SwachhApp(),
    ),
  );
}

class SwachhApp extends StatefulWidget {
  const SwachhApp({super.key});

  @override
  State<SwachhApp> createState() => _SwachhAppState();
}

class _SwachhAppState extends State<SwachhApp> {
  // A variable to hold the result of our login check.
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    // When the app first starts, immediately check if a token is saved.
    _isLoggedInFuture = _checkLoginStatus();
  }

  /// Checks secure storage for a saved token to determine login status.
  Future<bool> _checkLoginStatus() async {
    String? token = await SecureStorageService.getToken();
    // If the token is not null and not empty, the user is considered logged in.
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Swachh App',
          debugShowCheckedModeBanner: false,
          // Your existing light theme
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: const Color(0xFF2E7D32),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              secondary: Color(0xFF66BB6A),
              
              surface: Colors.white,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              unselectedItemColor: Colors.black87,
            )
          ),
          // Your existing dark theme
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: const Color(0xFF66BB6A),
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF66BB6A),
              secondary: Color(0xFF2E7D32),
              surface: Color(0xFF1E1E1E),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              unselectedItemColor: Colors.grey,
            ),
          ),
          themeMode: themeNotifier.themeMode,
          // Use a FutureBuilder to intelligently decide which page to show.
          home: FutureBuilder<bool>(
            future: _isLoggedInFuture,
            builder: (context, snapshot) {
              // While the app is checking for a token, show a loading spinner.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              // If the check is done and the result is 'true' (user is logged in).
              if (snapshot.hasData && snapshot.data == true) {
                // Go directly to the main app screen.
                return const MainShell();
              } else {
                // If the result is 'false' or an error, go to the login screen.
                return const AuthScreen();
              }
            },
          ),
        );
      },
    );
  }
}

