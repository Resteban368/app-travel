import 'package:equatable/equatable.dart';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'package:agente_viajes/features/clientes/domain/entities/cliente.dart';
import 'integrante.dart';
import 'vuelo_reserva.dart';

class Reserva extends Equatable {
  final String? id;
  final String? idReserva; // ej. "RES-334C6BE2"
  final String tipoReserva; // 'tour' | 'vuelos'
  final String correo;
  final String estado; // 'al dia', 'pendiente', 'cancelado'
  final double? valorTotal;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String notas;
  final List<int> serviciosIds;
  final List<Integrante> integrantes;
  final List<VueloReserva> vuelos;
  final double? saldoPendiente;

  final int? idResponsable;
  final String? idTour;
  final Tour? tour;
  final Cliente? responsable;

  const Reserva({
    this.id,
    this.idReserva,
    this.tipoReserva = 'tour',
    required this.correo,
    required this.estado,
    this.valorTotal,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.notas,
    required this.serviciosIds,
    required this.integrantes,
    this.vuelos = const [],
    this.idResponsable,
    this.idTour,
    this.tour,
    this.responsable,
    this.saldoPendiente,
  });

  Reserva copyWith({
    String? id,
    String? idReserva,
    String? tipoReserva,
    String? correo,
    String? estado,
    double? valorTotal,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? notas,
    List<int>? serviciosIds,
    List<Integrante>? integrantes,
    List<VueloReserva>? vuelos,
    int? idResponsable,
    String? idTour,
    Tour? tour,
    Cliente? responsable,
    double? saldoPendiente,
  }) {
    return Reserva(
      id: id ?? this.id,
      idReserva: idReserva ?? this.idReserva,
      tipoReserva: tipoReserva ?? this.tipoReserva,
      correo: correo ?? this.correo,
      estado: estado ?? this.estado,
      valorTotal: valorTotal ?? this.valorTotal,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      notas: notas ?? this.notas,
      serviciosIds: serviciosIds ?? this.serviciosIds,
      integrantes: integrantes ?? this.integrantes,
      vuelos: vuelos ?? this.vuelos,
      idResponsable: idResponsable ?? this.idResponsable,
      idTour: idTour ?? this.idTour,
      tour: tour ?? this.tour,
      responsable: responsable ?? this.responsable,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
    );
  }

  @override
  List<Object?> get props => [
    id,
    idReserva,
    tipoReserva,
    correo,
    estado,
    valorTotal,
    fechaCreacion,
    fechaActualizacion,
    notas,
    serviciosIds,
    integrantes,
    vuelos,
    idResponsable,
    idTour,
    tour,
    responsable,
    saldoPendiente,
  ];
}
