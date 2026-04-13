import 'package:equatable/equatable.dart';

class Integrante extends Equatable {
  final String nombre;
  final String telefono;
  final DateTime? fechaNacimiento;
  final bool esResponsable;

  const Integrante({
    required this.nombre,
    required this.telefono,
    this.fechaNacimiento,
    this.esResponsable = false,
  });

  Integrante copyWith({
    String? nombre,
    String? telefono,
    DateTime? fechaNacimiento,
    bool? esResponsable,
  }) {
    return Integrante(
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      esResponsable: esResponsable ?? this.esResponsable,
    );
  }

  @override
  List<Object?> get props => [nombre, telefono, fechaNacimiento, esResponsable];
}
