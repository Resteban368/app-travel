import 'package:equatable/equatable.dart';

class Cliente extends Equatable {
  final int? id;
  final String nombre;
  final String correo;
  final String telefono;
  final String tipoDocumento;
  final dynamic documento;
  final DateTime? fechaNacimiento;
  final String notas;

  const Cliente({
    this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.tipoDocumento,
    required this.documento,
    this.fechaNacimiento,
    this.notas = '',
  });

  Cliente copyWith({
    int? id,
    String? nombre,
    String? correo,
    String? telefono,
    String? tipoDocumento,
    String? numeroDocumento,
    DateTime? fechaNacimiento,
    String? notas,
  }) {
    return Cliente(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      documento: documento ?? this.documento,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      notas: notas ?? this.notas,
    );
  }

  @override
  List<Object?> get props => [
    id,
    nombre,
    correo,
    telefono,
    tipoDocumento,
    documento,
    fechaNacimiento,
    notas,
  ];
}
