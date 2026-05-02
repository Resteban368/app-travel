import 'package:equatable/equatable.dart';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'package:agente_viajes/features/clientes/domain/entities/cliente.dart';
import 'package:agente_viajes/features/agentes/domain/entities/agente.dart';
import 'package:agente_viajes/features/pagos_realizados/domain/entities/pago_realizado.dart';
import 'integrante.dart';
import 'vuelo_reserva.dart';
import 'hotel_reserva.dart';

class Reserva extends Equatable {
  final String? id;
  final String? idReserva; // ej. "RES-334C6BE2"
  final String tipoReserva; // 'tour' | 'vuelos'
  final String correo;
  final String estado; // 'al dia', 'pendiente', 'cancelado'
  final double? descuentoPorPersona;
  final double? valorSinDescuento;
  final double? valorTotal;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String notas;
  final List<int> serviciosIds;
  final List<Integrante> integrantes;
  final List<VueloReserva> vuelos;
  final List<HotelReserva> hoteles;
  final double? saldoPendiente;
  final double? utilidad;
  final List<PagoRealizado>? pagosValidados;
  final int? totalPersonas;
  final double? valorPersonas;

  final int? idResponsable;
  final String? idTour;
  final Tour? tour;
  final Cliente? responsable;
  final Agente? agente;
  final int? precioResponsableId;
  final double? precioResponsableAplicado;

  const Reserva({
    this.id,
    this.idReserva,
    this.tipoReserva = 'tour',
    required this.correo,
    required this.estado,
    this.descuentoPorPersona,
    this.valorSinDescuento,
    this.valorTotal,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.notas,
    required this.serviciosIds,
    required this.integrantes,
    this.vuelos = const [],
    this.hoteles = const [],
    this.utilidad,
    this.idResponsable,
    this.idTour,
    this.tour,
    this.responsable,
    this.agente,
    this.saldoPendiente,
    this.pagosValidados,
    this.totalPersonas,
    this.valorPersonas,
    this.precioResponsableId,
    this.precioResponsableAplicado,
  });

  Reserva copyWith({
    String? id,
    String? idReserva,
    String? tipoReserva,
    String? correo,
    String? estado,
    double? descuentoPorPersona,
    double? valorSinDescuento,
    double? valorTotal,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? notas,
    List<int>? serviciosIds,
    List<Integrante>? integrantes,
    List<VueloReserva>? vuelos,
    List<HotelReserva>? hoteles,
    double? utilidad,
    int? idResponsable,
    String? idTour,
    Tour? tour,
    Cliente? responsable,
    Agente? agente,
    double? saldoPendiente,
    List<PagoRealizado>? pagosValidados,
    int? totalPersonas,
    double? valorPersonas,
    int? precioResponsableId,
    double? precioResponsableAplicado,
  }) {
    return Reserva(
      id: id ?? this.id,
      idReserva: idReserva ?? this.idReserva,
      tipoReserva: tipoReserva ?? this.tipoReserva,
      correo: correo ?? this.correo,
      estado: estado ?? this.estado,
      descuentoPorPersona: descuentoPorPersona ?? this.descuentoPorPersona,
      valorSinDescuento: valorSinDescuento ?? this.valorSinDescuento,
      valorTotal: valorTotal ?? this.valorTotal,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      notas: notas ?? this.notas,
      serviciosIds: serviciosIds ?? this.serviciosIds,
      integrantes: integrantes ?? this.integrantes,
      vuelos: vuelos ?? this.vuelos,
      hoteles: hoteles ?? this.hoteles,
      utilidad: utilidad ?? this.utilidad,
      idResponsable: idResponsable ?? this.idResponsable,
      idTour: idTour ?? this.idTour,
      tour: tour ?? this.tour,
      responsable: responsable ?? this.responsable,
      agente: agente ?? this.agente,
      saldoPendiente: saldoPendiente ?? this.saldoPendiente,
      pagosValidados: pagosValidados ?? this.pagosValidados,
      totalPersonas: totalPersonas ?? this.totalPersonas,
      valorPersonas: valorPersonas ?? this.valorPersonas,
      precioResponsableId: precioResponsableId ?? this.precioResponsableId,
      precioResponsableAplicado:
          precioResponsableAplicado ?? this.precioResponsableAplicado,
    );
  }

  @override
  List<Object?> get props => [
    id,
    idReserva,
    tipoReserva,
    correo,
    estado,
    descuentoPorPersona,
    valorSinDescuento,
    valorTotal,
    fechaCreacion,
    fechaActualizacion,
    notas,
    serviciosIds,
    integrantes,
    vuelos,
    hoteles,
    utilidad,
    idResponsable,
    idTour,
    tour,
    responsable,
    agente,
    saldoPendiente,
    pagosValidados,
    totalPersonas,
    valorPersonas,
    precioResponsableId,
    precioResponsableAplicado,
  ];
}
