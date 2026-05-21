import 'package:equatable/equatable.dart';

class Proveedor extends Equatable {
  final int? id;
  final String nombre;
  final String tipo;
  final String? nit;
  final String? telefono;
  final String? email;
  final String? banco;
  final String? numeroCuenta;
  final String? notas;
  final bool isActive;
  final DateTime? createdAt;

  const Proveedor({
    this.id,
    required this.nombre,
    required this.tipo,
    this.nit,
    this.telefono,
    this.email,
    this.banco,
    this.numeroCuenta,
    this.notas,
    this.isActive = true,
    this.createdAt,
  });

  Proveedor copyWith({
    int? id,
    String? nombre,
    String? tipo,
    String? nit,
    String? telefono,
    String? email,
    String? banco,
    String? numeroCuenta,
    String? notas,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Proveedor(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipo: tipo ?? this.tipo,
      nit: nit ?? this.nit,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      banco: banco ?? this.banco,
      numeroCuenta: numeroCuenta ?? this.numeroCuenta,
      notas: notas ?? this.notas,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nombre,
    tipo,
    nit,
    telefono,
    email,
    banco,
    numeroCuenta,
    notas,
    isActive,
    createdAt,
  ];
}
