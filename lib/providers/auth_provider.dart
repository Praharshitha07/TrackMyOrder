import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

enum AuthState { unknown, authenticated, unauthenticated }

/// Provider for managing authentication state across the application.
/// Connects to Firebase Authentication and exposes reactive state.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  StreamSubscription<UserModel?>? _authSubscription;

  AuthProvider(this._authRepository) {
    _authSubscription = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _user = user;
        _state = AuthState.authenticated;
      } else if (_state == AuthState.authenticated) {
        _user = null;
        _state = AuthState.unauthenticated;
      }
      notifyListeners();
    });
  }

  AuthState _state = AuthState.unknown;
  UserModel? _user;
  String? _error;
  bool _loading = false;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _loading;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isCloudAuth => _authRepository.isCloudAuth;

  bool get canAccessApp => _state == AuthState.authenticated;

  String get effectiveUserId {
    final userId = _user?.id;
    if (!isAuthenticated || userId == null) {
      throw StateError('A signed-in Firebase user is required.');
    }
    return userId;
  }

  Future<void> initialize() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser != null) {
        _user = currentUser;
        _state = AuthState.authenticated;
      } else {
        _user = null;
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _state = AuthState.unauthenticated;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      _user = user;
      _state = AuthState.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      _user = user;
      _state = AuthState.authenticated;
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authRepository.sendPasswordResetEmail(email);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authRepository.signOut();
      _user = null;
      _state = AuthState.unauthenticated;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserModel updated) async {
    _user = await _authRepository.updateProfile(updated);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
