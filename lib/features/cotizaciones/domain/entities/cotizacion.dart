import 'package:equatable/equatable.dart';

class Cotizacion extends Equatable {
  final int id;
  final String chatId;
  final String nombreCompleto;
  final String? correoElectronico;
  final String detallesPlan;
  final int numeroPasajeros;
  final String? fechaSalida;
  final String? fechaRegreso;
  final String? origenDestino;
  final String? edadesMenuores;
  final String? especificaciones;
  final DateTime createdAt;
  final int? respuestaCotizacionId;

  const Cotizacion({
    required this.id,
    required this.chatId,
    required this.nombreCompleto,
    this.correoElectronico,
    required this.detallesPlan,
    required this.numeroPasajeros,
    this.fechaSalida,
    this.fechaRegreso,
    this.origenDestino,
    this.edadesMenuores,
    this.especificaciones,
    required this.createdAt,
    this.respuestaCotizacionId,
  });

  Cotizacion copyWith({
    int? id,
    String? chatId,
    String? nombreCompleto,
    String? correoElectronico,
    String? detallesPlan,
    int? numeroPasajeros,
    String? fechaSalida,
    String? fechaRegreso,
    String? origenDestino,
    String? edadesMenuores,
    String? especificaciones,
    String? estado,
    bool? isRead,
    DateTime? createdAt,
    int? respuestaCotizacionId,
  }) {
    return Cotizacion(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      nombreCompleto: nombreCompleto ?? this.nombreCompleto,
      correoElectronico: correoElectronico ?? this.correoElectronico,
      detallesPlan: detallesPlan ?? this.detallesPlan,
      numeroPasajeros: numeroPasajeros ?? this.numeroPasajeros,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      fechaRegreso: fechaRegreso ?? this.fechaRegreso,
      origenDestino: origenDestino ?? this.origenDestino,
      edadesMenuores: edadesMenuores ?? this.edadesMenuores,
      especificaciones: especificaciones ?? this.especificaciones,
      createdAt: createdAt ?? this.createdAt,
      respuestaCotizacionId:
          respuestaCotizacionId ?? this.respuestaCotizacionId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    chatId,
    nombreCompleto,
    correoElectronico,
    detallesPlan,
    numeroPasajeros,
    fechaSalida,
    fechaRegreso,
    origenDestino,
    edadesMenuores,
    especificaciones,
    createdAt,
    respuestaCotizacionId,
  ];
}
