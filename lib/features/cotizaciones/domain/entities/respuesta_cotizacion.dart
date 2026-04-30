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
  });
}

class OpcionHotel {
  final String nombre;
  final String tipoHabitacion;
  final List<String> queIncluye;
  final String fechaEntrada;
  final String fechaSalida;
  final double precioAdulto;
  final double precioMenor;
  final double precioTotal;
  final List<String> fotos;

  const OpcionHotel({
    required this.nombre,
    required this.tipoHabitacion,
    required this.queIncluye,
    required this.fechaEntrada,
    required this.fechaSalida,
    required this.precioAdulto,
    required this.precioMenor,
    required this.precioTotal,
    this.fotos = const [],
  });
}

class AdicionalViaje {
  final String nombre;
  final String descripcion;
  final double precio;

  const AdicionalViaje({
    required this.nombre,
    required this.descripcion,
    required this.precio,
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
  });
}
