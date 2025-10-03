import 'package:flutter/foundation.dart' show kIsWeb;

/// Provides the correct API endpoints for different platforms.
class ApiConfig {
  /// The base URL for the backend server.
  ///
  /// This intelligently switches between 'localhost' for web builds
  /// and the special '10.0.2.2' IP for the Android emulator.
  /// The port MUST match the one your Node.js server is using.
  static const String _baseUrl = 'https://swachh-drishti-backend.onrender.com';

  /// The endpoint for user login.
  static const String login = '$_baseUrl/api/auth/login';

  /// The endpoint for user signup.
  static const String signup = '$_baseUrl/api/auth/signup';

  /// The endpoint for submitting reports.
  static const String reports = '$_baseUrl/api/reports/';
  
  /// The endpoint for getting the current user's profile.
  static const String getMe = '$_baseUrl/api/auth/me';
  
  /// The endpoint for getting the user's own reports.
  static const String myReports = '$_baseUrl/api/reports/myreports';
}

