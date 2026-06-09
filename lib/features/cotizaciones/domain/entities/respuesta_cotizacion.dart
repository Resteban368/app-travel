class EscalaVuelo {
  final int? aerolineaId;
  final String aerolinea;
  final String numeroVuelo;
  final String origen;
  final String destino;
  final String horaSalida;
  final String horaLlegada;
  final String tiempoConexion; // espera antes de este tramo

  const EscalaVuelo({
    this.aerolineaId,
    this.aerolinea = '',
    this.numeroVuelo = '',
    this.origen = '',
    this.destino = '',
    this.horaSalida = '',
    this.horaLlegada = '',
    this.tiempoConexion = '',
  });
}

class VueloItinerario {
  final String tipo; // 'ida' | 'vuelta'
  final int? aerolineaId;
  final String aerolinea;
  final String numeroVuelo;
  final String origen;
  final String destino;
  final String fecha;
  final String horaSalida;
  final String horaLlegada;
  final double costo;
  final int numeroPasajeros;
  final List<EscalaVuelo> escalas;

  const VueloItinerario({
    required this.tipo,
    this.aerolineaId,
    required this.aerolinea,
    required this.numeroVuelo,
    required this.origen,
    required this.destino,
    required this.fecha,
    required this.horaSalida,
    required this.horaLlegada,
    this.costo = 0,
    this.numeroPasajeros = 1,
    this.escalas = const [],
  });
}

class OpcionHotel {
  final String nombre;
  final String tipoHabitacion;
  final List<String> queIncluye;
  final String fechaEntrada;
  final String horaEntrada;
  final String fechaSalida;
  final String horaSalida;
  final double precioAdulto;
  final double precioMenor;
  final double precioTotal;
  final List<String> fotos;
  final String notas;

  const OpcionHotel({
    required this.nombre,
    required this.tipoHabitacion,
    required this.queIncluye,
    required this.fechaEntrada,
    this.horaEntrada = '',
    required this.fechaSalida,
    this.horaSalida = '',
    required this.precioAdulto,
    required this.precioMenor,
    required this.precioTotal,
    this.fotos = const [],
    this.notas = '',
  });
}

class AdicionalViaje {
  final String nombre;
  final String descripcion;
  final double precio;
  final bool esSeleccionable;

  const AdicionalViaje({
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.esSeleccionable = true,
  });
}

class VistaRespuesta {
  final int id;
  final int respuestaId;
  final String ip;
  final String userAgent;
  final DateTime createdAt;

  const VistaRespuesta({
    required this.id,
    required this.respuestaId,
    required this.ip,
    required this.userAgent,
    required this.createdAt,
  });
}

class RespuestaCotizacion {
  final int? id;
  final int? cotizacionId;
  final String? token;
  final String tituloViaje;
  final List<String> imagenesDestino;
  final List<String> itemsIncluidos;
  final List<String> itemsNoIncluidos;
  final List<VueloItinerario> vuelos;
  final List<OpcionHotel> opcionesHotel;
  final List<AdicionalViaje> adicionales;
  final String condicionesGenerales;
  final DateTime createdAt;

  final String? nombreCliente;
  final String? telefonoCliente;

  final int? creadoPorId;
  final String? creadoPorNombre;
  final bool anclada;
  final bool esPublica;

  // Estadísticas de vistas
  final int? totalVistas;
  final double? precioTotal;
  final DateTime? primeraVista;
  final DateTime? ultimaVista;
  final List<VistaRespuesta> vistas;

  const RespuestaCotizacion({
    this.id,
    this.cotizacionId,
    this.token,
    required this.tituloViaje,
    required this.imagenesDestino,
    required this.itemsIncluidos,
    this.itemsNoIncluidos = const [],
    required this.vuelos,
    required this.opcionesHotel,
    required this.adicionales,
    required this.condicionesGenerales,
    required this.createdAt,
    this.nombreCliente,
    this.telefonoCliente,
    this.creadoPorId,
    this.creadoPorNombre,
    this.anclada = false,
    this.esPublica = false,
    this.totalVistas,
    this.precioTotal,
    this.primeraVista,
    this.ultimaVista,
    this.vistas = const [],
  });

  RespuestaCotizacion copyWith({
    int? id,
    int? cotizacionId,
    bool? anclada,
    bool? esPublica,
    bool clearCotizacionId = false,
    List<VistaRespuesta>? vistas,
    int? totalVistas,
    double? precioTotal,
    DateTime? primeraVista,
    DateTime? ultimaVista,
  }) {
    return RespuestaCotizacion(
      id: id ?? this.id,
      cotizacionId: clearCotizacionId ? null : (cotizacionId ?? this.cotizacionId),
      token: token,
      tituloViaje: tituloViaje,
      imagenesDestino: imagenesDestino,
      itemsIncluidos: itemsIncluidos,
      itemsNoIncluidos: itemsNoIncluidos,
      vuelos: vuelos,
      opcionesHotel: opcionesHotel,
      adicionales: adicionales,
      condicionesGenerales: condicionesGenerales,
      createdAt: createdAt,
      nombreCliente: nombreCliente,
      telefonoCliente: telefonoCliente,
      creadoPorId: creadoPorId,
      creadoPorNombre: creadoPorNombre,
      anclada: anclada ?? this.anclada,
      esPublica: esPublica ?? this.esPublica,
      totalVistas: totalVistas ?? this.totalVistas,
      precioTotal: precioTotal ?? this.precioTotal,
      primeraVista: primeraVista ?? this.primeraVista,
      ultimaVista: ultimaVista ?? this.ultimaVista,
      vistas: vistas ?? this.vistas,
    );
  }
}
