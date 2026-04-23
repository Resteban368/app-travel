class AnalyticsPago {
  final int idPago;
  final double monto;
  final String metodoPago;
  final String referencia;
  final String proveedorComercio;
  final int? reservaId;
  final DateTime fechaCreacion;

  AnalyticsPago({
    required this.idPago,
    required this.monto,
    required this.metodoPago,
    required this.referencia,
    required this.proveedorComercio,
    this.reservaId,
    required this.fechaCreacion,
  });

  factory AnalyticsPago.fromJson(Map<String, dynamic> j) => AnalyticsPago(
    idPago: j['id_pago'] as int,
    monto: (j['monto'] as num).toDouble(),
    metodoPago: j['metodo_pago'] as String? ?? '',
    referencia: j['referencia'] as String? ?? '',
    proveedorComercio: j['proveedor_comercio'] as String? ?? '',
    reservaId: j['reserva_id'] as int?,
    fechaCreacion: DateTime.parse(j['fecha_creacion'] as String),
  );
}

class AnalyticsReserva {
  final int id;
  final String idReserva;
  final String correo;
  final String estado;
  final double valorTotal;
  final int integrantesCount;
  final String? tourNombre;
  final DateTime fechaCreacion;

  AnalyticsReserva({
    required this.id,
    required this.idReserva,
    required this.correo,
    required this.estado,
    required this.valorTotal,
    required this.integrantesCount,
    this.tourNombre,
    required this.fechaCreacion,
  });

  factory AnalyticsReserva.fromJson(Map<String, dynamic> j) => AnalyticsReserva(
    id: j['id'] as int,
    idReserva: j['id_reserva'] as String? ?? '',
    correo: j['correo'] as String? ?? '',
    estado: j['estado'] as String? ?? '',
    valorTotal: (j['valor_total'] as num).toDouble(),
    integrantesCount: (j['integrantes_count'] as num?)?.toInt() ?? 1,
    tourNombre: j['tour_nombre'] as String?,
    fechaCreacion: DateTime.parse(j['fecha_creacion'] as String),
  );
}

class AnalyticsCotizacion {
  final int id;
  final String nombreCompleto;
  final String detallesPlan;
  final int numeroPasajeros;
  final String? origenDestino;
  final String estado;
  final bool isRead;
  final DateTime createdAt;

  AnalyticsCotizacion({
    required this.id,
    required this.nombreCompleto,
    required this.detallesPlan,
    required this.numeroPasajeros,
    this.origenDestino,
    required this.estado,
    required this.isRead,
    required this.createdAt,
  });

  factory AnalyticsCotizacion.fromJson(Map<String, dynamic> j) =>
      AnalyticsCotizacion(
        id: j['id'] as int,
        nombreCompleto: j['nombre_completo'] as String? ?? '',
        detallesPlan: j['detalles_plan'] as String? ?? '',
        numeroPasajeros: (j['numero_pasajeros'] as num?)?.toInt() ?? 1,
        origenDestino: j['origen_destino'] as String?,
        estado: j['estado'] as String? ?? '',
        isRead: j['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class VueloReservaItem {
  final int id;
  final String idReserva;
  final String correo;
  final String estado;
  final double valorTotal;
  final DateTime fechaCreacion;

  VueloReservaItem({
    required this.id,
    required this.idReserva,
    required this.correo,
    required this.estado,
    required this.valorTotal,
    required this.fechaCreacion,
  });

  factory VueloReservaItem.fromJson(Map<String, dynamic> j) => VueloReservaItem(
    id: j['id'] as int,
    idReserva: j['id_reserva'] as String? ?? '',
    correo: j['correo'] as String? ?? '',
    estado: j['estado'] as String? ?? '',
    valorTotal: (j['valor_total'] as num).toDouble(),
    fechaCreacion: DateTime.parse(j['fecha_creacion'] as String),
  );
}

class AgentGroup {
  final int? agenteId;
  final String agenteNombre;
  final int totalReservas;
  final List<VueloReservaItem> reservas;

  AgentGroup({
    this.agenteId,
    required this.agenteNombre,
    required this.totalReservas,
    required this.reservas,
  });

  factory AgentGroup.fromJson(Map<String, dynamic> j) => AgentGroup(
    agenteId: j['agente_id'] as int?,
    agenteNombre: j['agente_nombre'] as String? ?? 'Sin agente',
    totalReservas: (j['total_reservas'] as num).toInt(),
    reservas: (j['reservas'] as List<dynamic>)
        .map((r) => VueloReservaItem.fromJson(r as Map<String, dynamic>))
        .toList(),
  );
}

class AnalyticsData {
  final String periodo;
  final int pagosTotal;
  final double pagosMontoTotal;
  final List<AnalyticsPago> pagos;
  final int reservasTourTotal;
  final List<AnalyticsReserva> reservasTour;
  final int cotizacionesTotal;
  final List<AnalyticsCotizacion> cotizaciones;
  final List<AgentGroup> vuelosPorAgente;

  AnalyticsData({
    required this.periodo,
    required this.pagosTotal,
    required this.pagosMontoTotal,
    required this.pagos,
    required this.reservasTourTotal,
    required this.reservasTour,
    required this.cotizacionesTotal,
    required this.cotizaciones,
    required this.vuelosPorAgente,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> j) => AnalyticsData(
    periodo: j['periodo'] as String,
    pagosTotal: (j['pagos_validados']['total'] as num).toInt(),
    pagosMontoTotal: (j['pagos_validados']['monto_total'] as num).toDouble(),
    pagos: (j['pagos_validados']['items'] as List<dynamic>)
        .map((p) => AnalyticsPago.fromJson(p as Map<String, dynamic>))
        .toList(),
    reservasTourTotal: (j['reservas_tour']['total'] as num).toInt(),
    reservasTour: (j['reservas_tour']['items'] as List<dynamic>)
        .map((r) => AnalyticsReserva.fromJson(r as Map<String, dynamic>))
        .toList(),
    cotizacionesTotal: (j['cotizaciones']['total'] as num).toInt(),
    cotizaciones: (j['cotizaciones']['items'] as List<dynamic>)
        .map((c) => AnalyticsCotizacion.fromJson(c as Map<String, dynamic>))
        .toList(),
    vuelosPorAgente: (j['vuelos_por_agente'] as List<dynamic>)
        .map((a) => AgentGroup.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}
