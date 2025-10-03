import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A service class for securely managing the user's authentication token.
class SecureStorageService {
  // Create an instance of the secure storage.
  static const _storage = FlutterSecureStorage();

  // The key we will use to identify our token in the storage.
  static const _tokenKey = 'authToken';

  /// Saves the user's authentication token to secure storage.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Reads the user's authentication token from secure storage.
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Deletes the user's authentication token from secure storage (for logout).
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}