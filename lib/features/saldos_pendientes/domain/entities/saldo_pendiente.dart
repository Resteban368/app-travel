class PagoSaldo {
  final int idPago;
  final double monto;
  final String metodoPago;
  final bool isValidated;
  final bool isRechazado;
  final String referencia;
  final String? fechaDocumento;
  final String? fechaCreacion;
  final String telefono;
  final String chatId;
  final String proveedorComercio;
  final String motivoRechazo;
  final String? urlImagen;

  const PagoSaldo({
    required this.idPago,
    required this.monto,
    required this.metodoPago,
    required this.isValidated,
    required this.isRechazado,
    required this.referencia,
    this.fechaDocumento,
    this.fechaCreacion,
    required this.telefono,
    required this.chatId,
    required this.proveedorComercio,
    required this.motivoRechazo,
    this.urlImagen,
  });

  factory PagoSaldo.fromJson(Map<String, dynamic> j) => PagoSaldo(
        idPago: j['id_pago'] as int? ?? 0,
        monto: (j['monto'] as num?)?.toDouble() ?? 0,
        metodoPago: j['metodo_pago'] as String? ?? '',
        isValidated: j['is_validated'] as bool? ?? false,
        isRechazado: j['is_rechazado'] as bool? ?? false,
        referencia: j['referencia'] as String? ?? '',
        fechaDocumento: j['fecha_documento'] as String?,
        fechaCreacion: j['fecha_creacion'] as String?,
        telefono: j['telefono'] as String? ?? '',
        chatId: j['chat_id'] as String? ?? '',
        proveedorComercio: j['proveedor_comercio'] as String? ?? '',
        motivoRechazo: j['motivo_rechazo'] as String? ?? '',
        urlImagen: j['url_imagen'] as String?,
      );
}

class ResponsableSaldo {
  final int id;
  final String nombre;
  final String documento;
  final String tipoDocumento;
  final String telefono;
  final String correo;

  const ResponsableSaldo({
    required this.id,
    required this.nombre,
    required this.documento,
    required this.tipoDocumento,
    required this.telefono,
    required this.correo,
  });

  factory ResponsableSaldo.fromJson(Map<String, dynamic> j) => ResponsableSaldo(
        id: j['id'] as int? ?? 0,
        nombre: j['nombre'] as String? ?? '',
        documento: j['documento'] as String? ?? '',
        tipoDocumento: j['tipo_documento'] as String? ?? '',
        telefono: j['telefono'] as String? ?? '',
        correo: j['correo'] as String? ?? '',
      );
}

class TourSaldo {
  final int id;
  final String nombre;

  const TourSaldo({required this.id, required this.nombre});

  factory TourSaldo.fromJson(Map<String, dynamic> j) => TourSaldo(
        id: j['id'] as int? ?? 0,
        nombre: j['nombre'] as String? ?? '',
      );
}

/// Represents a tour group returned by the paginated API.
/// The API paginates by tour (limit = tours per page).
class TourConSaldo {
  final int tourId;
  final String tourNombre;
  final double saldoTotalTour;
  final int totalReservas;
  final List<SaldoPendiente> reservas;

  const TourConSaldo({
    required this.tourId,
    required this.tourNombre,
    required this.saldoTotalTour,
    required this.totalReservas,
    required this.reservas,
  });

  factory TourConSaldo.fromJson(Map<String, dynamic> j) => TourConSaldo(
        tourId: j['tour_id'] as int? ?? 0,
        tourNombre: j['tour_nombre'] as String? ?? '',
        saldoTotalTour: (j['saldo_total_tour'] as num?)?.toDouble() ?? 0,
        totalReservas: j['total_reservas'] as int? ?? 0,
        reservas: (j['reservas'] as List<dynamic>? ?? [])
            .map((r) => SaldoPendiente.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
}

class SaldoPendiente {
  final int reservaId;
  final String idReserva;
  final String tipoReserva;
  final String estado;
  final String? fechaCreacion;
  final double valorTotal;
  final double totalPagado;
  final double saldoPendiente;
  final String? ultimaFechaPago;
  final String? ultimoRecordatorio;
  final int totalRecordatorios;
  final TourSaldo tour;
  final ResponsableSaldo responsable;
  final List<PagoSaldo> pagos;

  const SaldoPendiente({
    required this.reservaId,
    required this.idReserva,
    required this.tipoReserva,
    required this.estado,
    this.fechaCreacion,
    required this.valorTotal,
    required this.totalPagado,
    required this.saldoPendiente,
    this.ultimaFechaPago,
    this.ultimoRecordatorio,
    required this.totalRecordatorios,
    required this.tour,
    required this.responsable,
    required this.pagos,
  });

  factory SaldoPendiente.fromJson(Map<String, dynamic> j) => SaldoPendiente(
        reservaId: j['reserva_id'] as int? ?? 0,
        idReserva: j['id_reserva'] as String? ?? '',
        tipoReserva: j['tipo_reserva'] as String? ?? '',
        estado: j['estado'] as String? ?? '',
        fechaCreacion: j['fecha_creacion'] as String?,
        valorTotal: (j['valor_total'] as num?)?.toDouble() ?? 0,
        totalPagado: (j['total_pagado'] as num?)?.toDouble() ?? 0,
        saldoPendiente: (j['saldo_pendiente'] as num?)?.toDouble() ?? 0,
        ultimaFechaPago: j['ultima_fecha_pago'] as String?,
        ultimoRecordatorio: j['ultimo_recordatorio'] as String?,
        totalRecordatorios: j['total_recordatorios'] as int? ?? 0,
        tour: TourSaldo.fromJson(j['tour'] as Map<String, dynamic>? ?? {}),
        responsable: ResponsableSaldo.fromJson(
            j['responsable'] as Map<String, dynamic>? ?? {}),
        pagos: (j['pagos'] as List<dynamic>? ?? [])
            .map((p) => PagoSaldo.fromJson(p as Map<String, dynamic>))
            .toList(),
      );
}
