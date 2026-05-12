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

class AnalyticsResponsable {
  final int id;
  final String nombre;
  final String? telefono;
  final String? documento;

  AnalyticsResponsable({
    required this.id,
    required this.nombre,
    this.telefono,
    this.documento,
  });

  factory AnalyticsResponsable.fromJson(Map<String, dynamic> j) =>
      AnalyticsResponsable(
        id: j['id'] as int,
        nombre: j['nombre'] as String? ?? '',
        telefono: j['telefono'] as String?,
        documento: j['documento'] as String?,
      );
}

class AnalyticsReserva {
  final int id;
  final String idReserva;
  final String correo;
  final String estado;
  final double valorTotal;
  final double totalPagado;
  final double saldo;
  final AnalyticsResponsable? responsable;
  final int integrantesCount;
  final String? tourNombre;
  final DateTime fechaCreacion;

  AnalyticsReserva({
    required this.id,
    required this.idReserva,
    required this.correo,
    required this.estado,
    required this.valorTotal,
    required this.totalPagado,
    required this.saldo,
    this.responsable,
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
    totalPagado: (j['total_pagado'] as num? ?? 0).toDouble(),
    saldo: (j['saldo'] as num? ?? 0).toDouble(),
    responsable: j['responsable'] != null
        ? AnalyticsResponsable.fromJson(
            j['responsable'] as Map<String, dynamic>)
        : null,
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

// ── Nuevas entidades ──────────────────────────────────────────────────────────

class RendimientoAgente {
  final int agenteId;
  final String agenteNombre;
  final int reservasTour;
  final int reservasVuelo;
  final int totalReservas;
  final int respuestasCotizacion;
  final double montoGestionado;

  RendimientoAgente({
    required this.agenteId,
    required this.agenteNombre,
    required this.reservasTour,
    required this.reservasVuelo,
    required this.totalReservas,
    required this.respuestasCotizacion,
    required this.montoGestionado,
  });

  factory RendimientoAgente.fromJson(Map<String, dynamic> j) => RendimientoAgente(
    agenteId: j['agente_id'] as int? ?? 0,
    agenteNombre: j['agente_nombre'] as String? ?? 'Sin agente',
    reservasTour: (j['reservas_tour'] as num).toInt(),
    reservasVuelo: (j['reservas_vuelo'] as num).toInt(),
    totalReservas: (j['total_reservas'] as num).toInt(),
    respuestasCotizacion: (j['respuestas_cotizacion'] as num? ?? 0).toInt(),
    montoGestionado: (j['monto_gestionado'] as num).toDouble(),
  );
}

class IngresoTour {
  final int tourId;
  final String tourNombre;
  final int totalReservas;
  final double montoRecaudado;

  IngresoTour({
    required this.tourId,
    required this.tourNombre,
    required this.totalReservas,
    required this.montoRecaudado,
  });

  factory IngresoTour.fromJson(Map<String, dynamic> j) => IngresoTour(
    tourId: j['tour_id'] as int,
    tourNombre: j['tour_nombre'] as String? ?? '',
    totalReservas: (j['total_reservas'] as num).toInt(),
    montoRecaudado: (j['monto_recaudado'] as num).toDouble(),
  );
}

class TourVendido {
  final int tourId;
  final String tourNombre;
  final int totalReservas;
  final int totalPasajeros;
  final double valorTotalGenerado;

  TourVendido({
    required this.tourId,
    required this.tourNombre,
    required this.totalReservas,
    required this.totalPasajeros,
    required this.valorTotalGenerado,
  });

  factory TourVendido.fromJson(Map<String, dynamic> j) => TourVendido(
    tourId: j['tour_id'] as int,
    tourNombre: j['tour_nombre'] as String? ?? '',
    totalReservas: (j['total_reservas'] as num).toInt(),
    totalPasajeros: (j['total_pasajeros'] as num).toInt(),
    valorTotalGenerado: (j['valor_total_generado'] as num).toDouble(),
  );
}

class DestinoSolicitado {
  final String destino;
  final int total;

  DestinoSolicitado({required this.destino, required this.total});

  factory DestinoSolicitado.fromJson(Map<String, dynamic> j) => DestinoSolicitado(
    destino: j['destino'] as String,
    total: (j['total'] as num).toInt(),
  );
}

class ServicioContratado {
  final int servicioId;
  final String nombre;
  final int vecesContratado;
  final double ingresoTotal;

  ServicioContratado({
    required this.servicioId,
    required this.nombre,
    required this.vecesContratado,
    required this.ingresoTotal,
  });

  factory ServicioContratado.fromJson(Map<String, dynamic> j) => ServicioContratado(
    servicioId: j['servicio_id'] as int,
    nombre: j['nombre'] as String? ?? '',
    vecesContratado: (j['veces_contratado'] as num).toInt(),
    ingresoTotal: (j['ingreso_total'] as num).toDouble(),
  );
}

class OcupacionTour {
  final int tourId;
  final String tourNombre;
  final String? fechaInicio;
  final String? fechaFin;
  final int cuposTotales;
  final int cuposOcupados;
  final int cuposDisponibles;
  final int porcentajeOcupacion;

  OcupacionTour({
    required this.tourId,
    required this.tourNombre,
    this.fechaInicio,
    this.fechaFin,
    required this.cuposTotales,
    required this.cuposOcupados,
    required this.cuposDisponibles,
    required this.porcentajeOcupacion,
  });

  factory OcupacionTour.fromJson(Map<String, dynamic> j) => OcupacionTour(
    tourId: j['tour_id'] as int,
    tourNombre: j['tour_nombre'] as String? ?? '',
    fechaInicio: j['fecha_inicio'] as String?,
    fechaFin: j['fecha_fin'] as String?,
    cuposTotales: (j['cupos_totales'] as num).toInt(),
    cuposOcupados: (j['cupos_ocupados'] as num).toInt(),
    cuposDisponibles: (j['cupos_disponibles'] as num).toInt(),
    porcentajeOcupacion: (j['porcentaje_ocupacion'] as num).toInt(),
  );
}

class EvolucionDia {
  final String fecha;
  final int total;

  EvolucionDia({required this.fecha, required this.total});

  factory EvolucionDia.fromJson(Map<String, dynamic> j) => EvolucionDia(
    fecha: j['fecha'] as String,
    total: (j['total'] as num).toInt(),
  );
}

class EvolucionPagoDia {
  final String fecha;
  final double monto;

  EvolucionPagoDia({required this.fecha, required this.monto});

  factory EvolucionPagoDia.fromJson(Map<String, dynamic> j) => EvolucionPagoDia(
    fecha: j['fecha'] as String,
    monto: (j['monto'] as num).toDouble(),
  );
}

class CotizacionDiaSemana {
  final String dia;
  final int diaIndex;
  final int total;

  CotizacionDiaSemana({
    required this.dia,
    required this.diaIndex,
    required this.total,
  });

  factory CotizacionDiaSemana.fromJson(Map<String, dynamic> j) =>
      CotizacionDiaSemana(
        dia: j['dia'] as String,
        diaIndex: (j['dia_index'] as num).toInt(),
        total: (j['total'] as num).toInt(),
      );
}

class TourProximo {
  final int tourId;
  final String tourNombre;
  final String? fechaInicio;
  final String? fechaFin;
  final int diasRestantes;
  final int cuposTotales;
  final int cuposOcupados;
  final int cuposDisponibles;
  final int porcentajeOcupacion;

  TourProximo({
    required this.tourId,
    required this.tourNombre,
    this.fechaInicio,
    this.fechaFin,
    required this.diasRestantes,
    required this.cuposTotales,
    required this.cuposOcupados,
    required this.cuposDisponibles,
    required this.porcentajeOcupacion,
  });

  factory TourProximo.fromJson(Map<String, dynamic> j) => TourProximo(
    tourId: j['tour_id'] as int,
    tourNombre: j['tour_nombre'] as String? ?? '',
    fechaInicio: j['fecha_inicio'] as String?,
    fechaFin: j['fecha_fin'] as String?,
    diasRestantes: (j['dias_restantes'] as num).toInt(),
    cuposTotales: (j['cupos_totales'] as num).toInt(),
    cuposOcupados: (j['cupos_ocupados'] as num).toInt(),
    cuposDisponibles: (j['cupos_disponibles'] as num).toInt(),
    porcentajeOcupacion: (j['porcentaje_ocupacion'] as num).toInt(),
  );
}

// ── AnalyticsData ─────────────────────────────────────────────────────────────

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
  // Nuevos
  final List<RendimientoAgente> rendimientoPorAgente;
  final List<IngresoTour> ingresosPorTour;
  final List<TourVendido> toursMasVendidos;
  final List<DestinoSolicitado> destinosMasSolicitados;
  final List<ServicioContratado> serviciosMasContratados;
  final List<OcupacionTour> ocupacionPorTour;
  final List<EvolucionDia> evolucionReservas;
  final List<EvolucionPagoDia> evolucionPagos;
  final List<CotizacionDiaSemana> cotizacionesPorDia;
  final List<TourProximo> toursProximos;
  final List<OcupacionTour> toursCuposCriticos;

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
    required this.rendimientoPorAgente,
    required this.ingresosPorTour,
    required this.toursMasVendidos,
    required this.destinosMasSolicitados,
    required this.serviciosMasContratados,
    required this.ocupacionPorTour,
    required this.evolucionReservas,
    required this.evolucionPagos,
    required this.cotizacionesPorDia,
    required this.toursProximos,
    required this.toursCuposCriticos,
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
    rendimientoPorAgente:
        ((j['rendimiento_por_agente'] as List<dynamic>?) ?? [])
            .map((a) => RendimientoAgente.fromJson(a as Map<String, dynamic>))
            .toList(),
    ingresosPorTour: ((j['ingresos_por_tour'] as List<dynamic>?) ?? [])
        .map((a) => IngresoTour.fromJson(a as Map<String, dynamic>))
        .toList(),
    toursMasVendidos: ((j['tours_mas_vendidos'] as List<dynamic>?) ?? [])
        .map((a) => TourVendido.fromJson(a as Map<String, dynamic>))
        .toList(),
    destinosMasSolicitados:
        ((j['destinos_mas_solicitados'] as List<dynamic>?) ?? [])
            .map((a) => DestinoSolicitado.fromJson(a as Map<String, dynamic>))
            .toList(),
    serviciosMasContratados:
        ((j['servicios_mas_contratados'] as List<dynamic>?) ?? [])
            .map((a) =>
                ServicioContratado.fromJson(a as Map<String, dynamic>))
            .toList(),
    ocupacionPorTour: ((j['ocupacion_por_tour'] as List<dynamic>?) ?? [])
        .map((a) => OcupacionTour.fromJson(a as Map<String, dynamic>))
        .toList(),
    evolucionReservas: ((j['evolucion_reservas'] as List<dynamic>?) ?? [])
        .map((a) => EvolucionDia.fromJson(a as Map<String, dynamic>))
        .toList(),
    evolucionPagos: ((j['evolucion_pagos'] as List<dynamic>?) ?? [])
        .map((a) => EvolucionPagoDia.fromJson(a as Map<String, dynamic>))
        .toList(),
    cotizacionesPorDia: ((j['cotizaciones_por_dia'] as List<dynamic>?) ?? [])
        .map((a) => CotizacionDiaSemana.fromJson(a as Map<String, dynamic>))
        .toList(),
    toursProximos: ((j['tours_proximos'] as List<dynamic>?) ?? [])
        .map((a) => TourProximo.fromJson(a as Map<String, dynamic>))
        .toList(),
    toursCuposCriticos: ((j['tours_cupos_criticos'] as List<dynamic>?) ?? [])
        .map((a) => OcupacionTour.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}
