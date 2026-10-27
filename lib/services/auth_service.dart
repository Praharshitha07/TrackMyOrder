import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

/// Simple local auth service — stores credentials in SharedPreferences.
/// This is a DEVELOPMENT-ONLY implementation.
/// Replace with Firebase Auth for production.
class AuthService {
  static const String _userKey = 'tmo_current_user';
  static const String _credKey = 'tmo_credentials';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Returns the currently signed-in user, or null.
  Future<UserModel?> getCurrentUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_userKey);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Sign in with email + password.
  Future<UserModel> signIn(String email, String password) async {
    final prefs = await _prefs;
    final credRaw = prefs.getString(_credKey);
    if (credRaw == null) {
      throw Exception('No account found. Please register first.');
    }
    final creds = jsonDecode(credRaw) as Map<String, dynamic>;
    if (creds['email'] != email.trim().toLowerCase()) {
      throw Exception('No account found for this email address.');
    }
    if (creds['password'] != password) {
      throw Exception('Incorrect password. Please try again.');
    }
    final userRaw = prefs.getString(_userKey);
    if (userRaw == null) throw Exception('Account data missing. Please register again.');
    return UserModel.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
  }

  /// Register a new account.
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (name.trim().isEmpty) throw Exception('Name is required.');
    if (!email.contains('@')) throw Exception('Enter a valid email address.');
    if (password.length < 6) throw Exception('Password must be at least 6 characters.');

    final prefs = await _prefs;
    final credRaw = prefs.getString(_credKey);
    if (credRaw != null) {
      final creds = jsonDecode(credRaw) as Map<String, dynamic>;
      if (creds['email'] == email.trim().toLowerCase()) {
        throw Exception('An account with this email already exists. Please sign in.');
      }
    }

    final user = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim().toLowerCase(),
      createdAt: DateTime.now(),
    );
    await prefs.setString(
      _credKey,
      jsonEncode({'email': email.trim().toLowerCase(), 'password': password}),
    );
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    return user;
  }

  /// Update user profile.
  Future<UserModel> updateProfile(UserModel user) async {
    final prefs = await _prefs;
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    return user;
  }

  /// Sign out.
  Future<void> signOut() async {
    final prefs = await _prefs;
    await prefs.remove(_userKey);
  }

  /// Check if any account exists on this device.
  Future<bool> hasAccount() async {
    final prefs = await _prefs;
    return prefs.containsKey(_credKey);
  }
}
