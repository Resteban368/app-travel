import 'package:equatable/equatable.dart';

class Integrante extends Equatable {
  final String nombre;
  final String telefono;
  final DateTime? fechaNacimiento;
  final bool esResponsable;
  final String tipoDocumento;
  final String documento;

  const Integrante({
    required this.nombre,
    required this.telefono,
    this.fechaNacimiento,
    this.esResponsable = false,
    this.tipoDocumento = 'cedula',
    this.documento = '',
  });

  Integrante copyWith({
    String? nombre,
    String? telefono,
    DateTime? fechaNacimiento,
    bool? esResponsable,
    String? tipoDocumento,
    String? documento,
  }) {
    return Integrante(
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      esResponsable: esResponsable ?? this.esResponsable,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      documento: documento ?? this.documento,
    );
  }

  @override
  List<Object?> get props => [nombre, telefono, fechaNacimiento, esResponsable, tipoDocumento, documento];
}
