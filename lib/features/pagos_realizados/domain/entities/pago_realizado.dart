import 'package:equatable/equatable.dart';

/// Represents a payment made by a user and recorded in the system.
class PagoRealizado extends Equatable {
  final int id;
  final String chatId;
  final String tipoDocumento;
  final double monto;
  final String proveedorComercio;
  final String nit;
  final String metodoPago;
  final String referencia;
  final String fechaDocumento;
  final bool isValidated;
  final bool isRechazado;
  final String? motivoRechazo;
  final String urlImagen;
  final int? reservaId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PagoRealizado({
    required this.id,
    required this.chatId,
    required this.tipoDocumento,
    required this.monto,
    required this.proveedorComercio,
    required this.nit,
    required this.metodoPago,
    required this.referencia,
    required this.fechaDocumento,
    this.isValidated = false,
    this.isRechazado = false,
    this.motivoRechazo,
    required this.urlImagen,
    this.reservaId,
    this.createdAt,
    this.updatedAt,
  });

  PagoRealizado copyWith({
    int? id,
    String? chatId,
    String? tipoDocumento,
    double? monto,
    String? proveedorComercio,
    String? nit,
    String? metodoPago,
    String? referencia,
    String? fechaDocumento,
    bool? isValidated,
    bool? isRechazado,
    String? motivoRechazo,
    String? urlImagen,
    int? reservaId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PagoRealizado(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      tipoDocumento: tipoDocumento ?? this.tipoDocumento,
      monto: monto ?? this.monto,
      proveedorComercio: proveedorComercio ?? this.proveedorComercio,
      nit: nit ?? this.nit,
      metodoPago: metodoPago ?? this.metodoPago,
      referencia: referencia ?? this.referencia,
      fechaDocumento: fechaDocumento ?? this.fechaDocumento,
      isValidated: isValidated ?? this.isValidated,
      isRechazado: isRechazado ?? this.isRechazado,
      motivoRechazo: motivoRechazo ?? this.motivoRechazo,
      urlImagen: urlImagen ?? this.urlImagen,
      reservaId: reservaId ?? this.reservaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    chatId,
    tipoDocumento,
    monto,
    proveedorComercio,
    nit,
    metodoPago,
    referencia,
    fechaDocumento,
    isValidated,
    isRechazado,
    motivoRechazo,
    urlImagen,
    reservaId,
    createdAt,
    updatedAt,
  ];
}
