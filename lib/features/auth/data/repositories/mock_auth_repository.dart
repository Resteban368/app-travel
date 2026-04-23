import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Mock implementation with hardcoded credentials.
class MockAuthRepository implements AuthRepository {
  @override
  Future<User> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (username == 'admin' && password == 'admin123') {
      return const User(
        id: '1',
        username: 'admin',
        name: 'Administrador',
        role: 'admin',
      );
    }
    throw Exception('Credenciales incorrectas');
  }

  @override
  Future<User?> restoreSession() async => null;

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<User?> fetchMe() async => null;

  @override
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
