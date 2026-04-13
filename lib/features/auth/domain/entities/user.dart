import 'package:equatable/equatable.dart';

/// Represents an admin user.
class User extends Equatable {
  final String id;
  final String username;
  final String name;
  final String role;
  final Map<String, String> permisos;

  const User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.permisos = const {},
  });

  bool get isAdmin => role == 'admin';

  /// Returns true if the user can access the given permission key.
  /// An empty key means the item is always visible (e.g. profile).
  /// Admins have access to everything. Agents only see explicitly assigned modules.
  bool hasPermission(String key) {
    if (key.isEmpty) return true;
    if (isAdmin) return true;
    return permisos.containsKey(key);
  }

  /// Returns true if the user has write access (completo) for the given key.
  bool canWrite(String key) => permisos[key] == 'completo';

  @override
  List<Object?> get props => [id, username, name, role, permisos];
}
