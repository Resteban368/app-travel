import 'package:equatable/equatable.dart';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'integrante.dart';

class Reserva extends Equatable {
  final String? id;
  final String? idReserva; // ej. "RES-334C6BE2"
  final String correo;
  final String estado; // 'al dia', 'pendiente', 'cancelado'
  final double? valorTotal;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final String notas;
  final List<int> serviciosIds;
  final List<Integrante> integrantes;

  // Responsable de la reserva
  final String? responsableNombre;
  final String? responsableTelefono;
  final String? responsableCedula;
  final DateTime? responsableFechaNacimiento;

  final String idTour;
  final Tour? tour;

  const Reserva({
    this.id,
    this.idReserva,
    required this.correo,
    required this.estado,
    this.valorTotal,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.notas,
    required this.serviciosIds,
    required this.integrantes,
    this.responsableNombre,
    this.responsableTelefono,
    this.responsableCedula,
    this.responsableFechaNacimiento,
    required this.idTour,
    this.tour,
  });

  Reserva copyWith({
    String? id,
    String? idReserva,
    String? correo,
    String? estado,
    double? valorTotal,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    String? notas,
    List<int>? serviciosIds,
    List<Integrante>? integrantes,
    String? responsableNombre,
    String? responsableTelefono,
    String? responsableCedula,
    DateTime? responsableFechaNacimiento,
    String? idTour,
    Tour? tour,
  }) {
    return Reserva(
      id: id ?? this.id,
      idReserva: idReserva ?? this.idReserva,
      correo: correo ?? this.correo,
      estado: estado ?? this.estado,
      valorTotal: valorTotal ?? this.valorTotal,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      notas: notas ?? this.notas,
      serviciosIds: serviciosIds ?? this.serviciosIds,
      integrantes: integrantes ?? this.integrantes,
      responsableNombre: responsableNombre ?? this.responsableNombre,
      responsableTelefono: responsableTelefono ?? this.responsableTelefono,
      responsableCedula: responsableCedula ?? this.responsableCedula,
      responsableFechaNacimiento: responsableFechaNacimiento ?? this.responsableFechaNacimiento,
      idTour: idTour ?? this.idTour,
      tour: tour ?? this.tour,
    );
  }

  @override
  List<Object?> get props => [
        id,
        idReserva,
        correo,
        estado,
        valorTotal,
        fechaCreacion,
        fechaActualizacion,
        notas,
        serviciosIds,
        integrantes,
        responsableNombre,
        responsableTelefono,
        responsableCedula,
        responsableFechaNacimiento,
        idTour,
        tour,
      ];
}
