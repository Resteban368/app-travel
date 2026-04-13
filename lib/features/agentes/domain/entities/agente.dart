import 'package:equatable/equatable.dart';

class Agente extends Equatable {
  final int? id;
  final String nombre;
  final String correo;
  final String? password; // Only used for create/update
  final Map<String, String> permisos;
  final bool isActive;

  const Agente({
    this.id,
    required this.nombre,
    required this.correo,
    this.password,
    this.permisos = const {},
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, nombre, correo, password, permisos, isActive];
}
