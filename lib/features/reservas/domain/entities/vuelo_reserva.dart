import 'package:equatable/equatable.dart';
import 'aerolinea.dart';

class VueloReserva extends Equatable {
  final int? id;
  final Aerolinea? aerolinea;
  final int? aerolineaId;
  final String numeroVuelo;
  final String origen;
  final String destino;
  final String fechaSalida;
  final String fechaLlegada;
  final String horaSalida;
  final String horaLlegada;
  final String clase;
  final double? precio;
  final String reservaVuelo;
  final String tipoVuelo; // 'ida' | 'vuelta'

  const VueloReserva({
    this.id,
    this.aerolinea,
    this.aerolineaId,
    required this.numeroVuelo,
    required this.origen,
    required this.destino,
    required this.fechaSalida,
    required this.fechaLlegada,
    required this.horaSalida,
    required this.horaLlegada,
    required this.clase,
    this.precio,
    this.reservaVuelo = '',
    this.tipoVuelo = 'ida',
  });

  VueloReserva copyWith({
    int? id,
    Aerolinea? aerolinea,
    int? aerolineaId,
    String? numeroVuelo,
    String? origen,
    String? destino,
    String? fechaSalida,
    String? fechaLlegada,
    String? horaSalida,
    String? horaLlegada,
    String? clase,
    double? precio,
    String? reservaVuelo,
    String? tipoVuelo,
  }) {
    return VueloReserva(
      id: id ?? this.id,
      aerolinea: aerolinea ?? this.aerolinea,
      aerolineaId: aerolineaId ?? this.aerolineaId,
      numeroVuelo: numeroVuelo ?? this.numeroVuelo,
      origen: origen ?? this.origen,
      destino: destino ?? this.destino,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      fechaLlegada: fechaLlegada ?? this.fechaLlegada,
      horaSalida: horaSalida ?? this.horaSalida,
      horaLlegada: horaLlegada ?? this.horaLlegada,
      clase: clase ?? this.clase,
      precio: precio ?? this.precio,
      reservaVuelo: reservaVuelo ?? this.reservaVuelo,
      tipoVuelo: tipoVuelo ?? this.tipoVuelo,
    );
  }

  @override
  List<Object?> get props => [
    id,
    aerolinea,
    aerolineaId,
    numeroVuelo,
    origen,
    destino,
    fechaSalida,
    fechaLlegada,
    horaSalida,
    horaLlegada,
    clase,
    precio,
    reservaVuelo,
    tipoVuelo,
  ];
}
