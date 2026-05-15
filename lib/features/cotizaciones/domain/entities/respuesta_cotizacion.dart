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
  final bool tieneEscala;
  final String ciudadEscala;
  final String tiempoEscala;

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
    this.tieneEscala = false,
    this.ciudadEscala = '',
    this.tiempoEscala = '',
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

  //creado_por_id
  final int? creadoPorId;
  //creado_por_nombre
  final String? creadoPorNombre;
  final bool anclada;
  final bool esPublica;

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
  });

  RespuestaCotizacion copyWith({
    int? id,
    int? cotizacionId,
    bool? anclada,
    bool? esPublica,
    bool clearCotizacionId = false,
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
    );
  }
}
