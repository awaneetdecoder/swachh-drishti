import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:page_transition/page_transition.dart';
import 'main_shell.dart';
import 'signup_screen.dart';
import 'widget/app_logo.dart';
import 'api_config.dart';
import 'services/secure_storage_service.dart'; // Import the secure storage service

/// The initial screen for user authentication (Login).
///
/// This screen provides a form for users to enter their email and password.
/// It communicates with the backend to verify credentials, securely saves the
/// returned token, and navigates the user to the home page upon success.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final String _apiUrl = ApiConfig.login;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the entire login process from validation to navigation.
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) { // 200 is the standard success code for login.
        final responseData = jsonDecode(response.body);
        final token = responseData['token'];

        // --- THIS IS THE KEY PROFESSIONAL FEATURE ---
        // Securely save the user's token to the device's storage.
        await SecureStorageService.saveToken(token);
        // --- END OF FEATURE ---

        _navigateToHome();
      } else {
        // Handle server errors like "Invalid Credentials".
        final errorData = jsonDecode(response.body);
        _showErrorSnackbar(errorData['msg'] ?? 'Login failed. Please check your credentials.');
      }
    } catch (e) {
      _showErrorSnackbar('Could not connect to the server. Please check your connection.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Navigates to the main app screen after a successful login.
  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      PageTransition(
        type: PageTransitionType.scale,
        alignment: Alignment.bottomCenter,
        duration: const Duration(milliseconds: 600),
        child: const MainShell(),
      ),
       (route) => false, // This removes the login screen from history.
    );
  }

  /// Displays a red error message at the bottom of the screen.
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 80),
                      const AppLogo(radius: 50, iconSize: 50),
                      const SizedBox(height: 16),
                      Text('Welcome to Swachh', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                           if (value == null || value.isEmpty) return 'Please enter an email';
                           if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Please enter a valid email';
                           return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                         validator: (value) => value!.isEmpty ? 'Please enter a password' : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                        onPressed: _isLoading ? null : _signInWithEmail,
                        child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('Login', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.surface,
                            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey.withOpacity(0.5))),
                        icon: Image.asset('assets/google_logo.png', height: 24),
                        onPressed: _isLoading ? null : () { /* TODO: Implement Google Sign-In with Node.js backend */ },
                        label: const Text('Sign in with Google'),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(onPressed: _isLoading ? null : () {}, child: const Text('Forgot Password?')),
                          TextButton(
                            onPressed: _isLoading ? null : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const SignupScreen()),
                              );
                            },
                            child: const Text('Create Account'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

