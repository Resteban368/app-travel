import 'package:equatable/equatable.dart';

class Hotel extends Equatable {
  final int? id;
  final String nombre;
  final String ciudad;
  final String telefono;
  final String direccion;
  final bool isActive;
  final DateTime? createdAt;

  const Hotel({
    this.id,
    required this.nombre,
    required this.ciudad,
    required this.telefono,
    required this.direccion,
    this.isActive = true,
    this.createdAt,
  });

  Hotel copyWith({
    int? id,
    String? nombre,
    String? ciudad,
    String? telefono,
    String? direccion,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Hotel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ciudad: ciudad ?? this.ciudad,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nombre,
    ciudad,
    telefono,
    direccion,
    isActive,
    createdAt,
  ];
}
