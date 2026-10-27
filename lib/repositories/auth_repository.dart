import '../models/user_model.dart';

/// Abstract contract for authentication operations.
/// Implementations can be LocalAuthRepository (offline / dev)
/// or FirebaseAuthRepository (production cloud).
abstract class AuthRepository {
  /// Stream of user changes for real-time auth state synchronization
  Stream<UserModel?> get authStateChanges;

  /// Get current user or null
  Future<UserModel?> getCurrentUser();

  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  });

  /// Register new user with email and password
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  });

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Update user profile details
  Future<UserModel> updateProfile(UserModel user);

  /// Sign out current user
  Future<void> signOut();

  /// Whether real cloud authentication is enabled/configured
  bool get isCloudAuth;
}
