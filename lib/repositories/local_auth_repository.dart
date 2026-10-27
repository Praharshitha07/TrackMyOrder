import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_repository.dart';

/// Local offline development implementation of AuthRepository.
/// Stores credentials securely for on-device testing and ensures graceful
/// fallback when Firebase Authentication is not yet configured.
class LocalAuthRepository implements AuthRepository {
  static const String _userKey = 'tmo_current_user_v2';
  static const String _credKey = 'tmo_credentials_v2';

  final StreamController<UserModel?> _authStateController =
      StreamController<UserModel?>.broadcast();

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  @override
  bool get isCloudAuth => false;

  @override
  Future<UserModel?> getCurrentUser() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final user = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      _authStateController.add(user);
      return user;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await _prefs;
    final credRaw = prefs.getString(_credKey);

    if (credRaw == null || credRaw.isEmpty) {
      throw Exception(
          'No account found with this email on this device. Please create an account.');
    }

    final creds = jsonDecode(credRaw) as Map<String, dynamic>;
    if (creds['email'] != normalizedEmail) {
      throw Exception('Incorrect email address or user not found.');
    }
    if (creds['password'] != password) {
      throw Exception('Incorrect password. Please verify your credentials.');
    }

    final userRaw = prefs.getString(_userKey);
    if (userRaw == null) {
      throw Exception('Account profile corrupted. Please register again.');
    }

    final user = UserModel.fromJson(jsonDecode(userRaw) as Map<String, dynamic>);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) throw Exception('Name cannot be empty.');
    if (!normalizedEmail.contains('@') || !normalizedEmail.contains('.')) {
      throw Exception('Please enter a valid email address.');
    }
    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters.');
    }

    final prefs = await _prefs;
    final credRaw = prefs.getString(_credKey);
    if (credRaw != null) {
      final creds = jsonDecode(credRaw) as Map<String, dynamic>;
      if (creds['email'] == normalizedEmail) {
        throw Exception(
            'An account with this email already exists on this device.');
      }
    }

    final user = UserModel(
      id: 'local_usr_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      email: normalizedEmail,
      createdAt: DateTime.now(),
    );

    await prefs.setString(
      _credKey,
      jsonEncode({'email': normalizedEmail, 'password': password}),
    );
    await prefs.setString(_userKey, jsonEncode(user.toJson()));

    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await _prefs;
    final credRaw = prefs.getString(_credKey);
    if (credRaw == null) {
      throw Exception('No account found for $normalizedEmail.');
    }
    final creds = jsonDecode(credRaw) as Map<String, dynamic>;
    if (creds['email'] != normalizedEmail) {
      throw Exception('No account found for $normalizedEmail.');
    }
    // In local dev mode, simulate successful password reset trigger
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final prefs = await _prefs;
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    final prefs = await _prefs;
    await prefs.remove(_userKey);
    _authStateController.add(null);
  }

  void dispose() {
    _authStateController.close();
  }
}
