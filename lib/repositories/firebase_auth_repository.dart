import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  UserModel _toUserModel(User user) {
    return UserModel(
      id: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      createdAt: user.metadata.creationTime ?? DateTime.now(),
    );
  }

  @override
  bool get isCloudAuth => true;

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map(
      (user) => user == null ? null : _toUserModel(user),
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    return user == null ? null : _toUserModel(user);
  }

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return _toUserModel(result.user!);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login failed.');
    }
  }

  @override
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await result.user!.updateDisplayName(name.trim());
      await result.user!.reload();

      return _toUserModel(_auth.currentUser!);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed.');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Could not send password reset email.');
    }
  }

  @override
  Future<UserModel> updateProfile(UserModel user) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('Please log in first.');
    }

    await currentUser.updateDisplayName(user.name);
    await currentUser.reload();

    return _toUserModel(_auth.currentUser!);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}