import 'package:equatable/equatable.dart';

class Cotizacion extends Equatable {
  final int id;
  final String chatId;
  final String nombreCompleto;
  final String? correoElectronico;
  final String? telefono;
  final String detallesPlan;
  final int numeroPasajeros;
  final String? fechaSalida;
  final String? fechaRegreso;
  final String? origen;
  final String? destino;
  final String? edadesMenores;
  final String? especificaciones;
  final DateTime createdAt;
  final int? respuestaCotizacionId;

  const Cotizacion({
    required this.id,
    required this.chatId,
    required this.nombreCompleto,
    this.correoElectronico,
    this.telefono,
    required this.detallesPlan,
    required this.numeroPasajeros,
    this.fechaSalida,
    this.fechaRegreso,
    this.origen,
    this.destino,
    this.edadesMenores,
    this.especificaciones,
    required this.createdAt,
    this.respuestaCotizacionId,
  });

  Cotizacion copyWith({
    int? id,
    String? chatId,
    String? nombreCompleto,
    String? correoElectronico,
    String? telefono,
    String? detallesPlan,
    int? numeroPasajeros,
    String? fechaSalida,
    String? fechaRegreso,
    String? origen,
    String? destino,
    String? edadesMenores,
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
      telefono: telefono ?? this.telefono,
      detallesPlan: detallesPlan ?? this.detallesPlan,
      numeroPasajeros: numeroPasajeros ?? this.numeroPasajeros,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      fechaRegreso: fechaRegreso ?? this.fechaRegreso,
      origen: origen ?? this.origen,
      destino: destino ?? this.destino,
      edadesMenores: edadesMenores ?? this.edadesMenores,
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
    telefono,
    detallesPlan,
    numeroPasajeros,
    fechaSalida,
    fechaRegreso,
    origen,
    destino,
    edadesMenores,
    especificaciones,
    createdAt,
    respuestaCotizacionId,
  ];
}
