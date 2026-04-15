import '../entities/user.dart';

/// Abstract contract for authentication operations.
abstract class AuthRepository {
  Future<User> login(String username, String password);
  Future<void> logout();
  Future<User?> restoreSession();
  Future<User?> fetchMe();
  Future<void> changePassword(String currentPassword, String newPassword);
}
