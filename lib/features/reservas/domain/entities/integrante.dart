import 'package:equatable/equatable.dart';

class Integrante extends Equatable {
  final String nombre;
  final String telefono;
  final DateTime? fechaNacimiento;
  final bool esResponsable;
  final String tipoDocumento;
  final String documento;
  final int? tourPrecioId;
  final double? precioAplicado;
  final bool ocupaAsiento;

  const Integrante({
    required this.nombre,
    required this.telefono,
    this.fechaNacimiento,
    this.esResponsable = false,
    this.tipoDocumento = 'CC',
    this.documento = '',
    this.tourPrecioId,
    this.precioAplicado,
    this.ocupaAsiento = true,
  });

  Integrante copyWith({
    String? nombre,
    String? telefono,
    DateTime? fechaNacimiento,
    bool? esResponsable,
    String? tipoDocumento,
    String? documento,
    int? tourPrecioId,
    double? precioAplicado,
    bool? ocupaAsiento,
  }) {
    return Integrante(
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      esResponsable: esResponsable ?? this.esResponsable,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      documento: documento ?? this.documento,
      tourPrecioId: tourPrecioId ?? this.tourPrecioId,
      precioAplicado: precioAplicado ?? this.precioAplicado,
      ocupaAsiento: ocupaAsiento ?? this.ocupaAsiento,
    );
  }

  @override
  List<Object?> get props => [
    nombre,
    telefono,
    fechaNacimiento,
    esResponsable,
    tipoDocumento,
    documento,
    tourPrecioId,
    precioAplicado,
    ocupaAsiento,
  ];
}
