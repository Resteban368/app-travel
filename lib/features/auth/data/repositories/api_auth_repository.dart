import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final FlutterSecureStorage _storage;
  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/auth';

  ApiAuthRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<User> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        // Guardar tokens de forma segura
        await _storage.write(key: 'access_token', value: accessToken);
        if (refreshToken != null) {
          await _storage.write(key: 'refresh_token', value: refreshToken);
        }

        // Obtener datos de usuario
        final userResponse = await http.get(
          Uri.parse('$_baseUrl/me'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );

        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);

          await _storage.write(key: 'user_data', value: jsonEncode(userData));

          final permisosRaw =
              (userData['permisos'] as Map<String, dynamic>?) ?? {};
          final permisos = permisosRaw.map((k, v) => MapEntry(k, v.toString()));

          return User(
            id: userData['id_usuario']?.toString() ?? '0',
            username: userData['email'] ?? '',
            name: userData['nombre'] ?? 'Usuario',
            role: userData['rol'] ?? 'admin',
            permisos: permisos,
          );
        } else {
          throw Exception('No se pudo obtener la información del usuario');
        }
      } else {
        throw Exception('Credenciales incorrectas');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Credenciales')) {
        rethrow;
      }
      throw Exception('Error al iniciar sesión. Verifique su conexión y credenciales.');
    }
  }

  @override
  Future<User?> restoreSession() async {
    final token = await _storage.read(key: 'access_token');
    final userJson = await _storage.read(key: 'user_data');
    if (token == null || userJson == null) return null;

    final userData = jsonDecode(userJson);
    final permisosRaw =
        (userData['permisos'] as Map<String, dynamic>?) ?? {};
    final permisos = permisosRaw.map((k, v) => MapEntry(k, v.toString()));
    return User(
      id: userData['id_usuario']?.toString() ?? '0',
      username: userData['email'] ?? '',
      name: userData['nombre'] ?? 'Usuario',
      role: userData['rol'] ?? 'admin',
      permisos: permisos,
    );
  }

  @override
  Future<User?> fetchMe() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$_baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);
      await _storage.write(key: 'user_data', value: jsonEncode(userData));

      final permisosRaw =
          (userData['permisos'] as Map<String, dynamic>?) ?? {};
      final permisos = permisosRaw.map((k, v) => MapEntry(k, v.toString()));

      return User(
        id: userData['id_usuario']?.toString() ?? '0',
        username: userData['email'] ?? '',
        name: userData['nombre'] ?? 'Usuario',
        role: userData['rol'] ?? 'admin',
        permisos: permisos,
      );
    }
    return null;
  }

  @override
  Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) throw Exception('token_expired');

    final response = await http.patch(
      Uri.parse('$_baseUrl/change-password'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode == 200) return;
    if (response.statusCode == 400) throw Exception('wrong_password');
    if (response.statusCode == 401) throw Exception('token_expired');
    throw Exception('Error al cambiar la contraseña: ${response.statusCode}');
  }

  @override
  Future<void> logout() async {
    final accessToken = await _storage.read(key: 'access_token');
    
    if (accessToken != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
      } catch (e) {
        // Ignoramos errores de red al cerrar sesión, igual borramos los datos locales
      }
    }

    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_data');
  }

}
