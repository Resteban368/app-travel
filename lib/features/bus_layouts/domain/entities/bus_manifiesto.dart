import 'package:equatable/equatable.dart';
import 'bus_layout.dart';

class TourInfoManifiesto extends Equatable {
  final int id;
  final String nombreTour;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? horaPartida;
  final String? llegada;
  final String? puntoPartida;
  final int? cupos;
  final bool esPromocion;
  final String? linkPdf;

  const TourInfoManifiesto({
    required this.id,
    required this.nombreTour,
    this.fechaInicio,
    this.fechaFin,
    this.horaPartida,
    this.llegada,
    this.puntoPartida,
    this.cupos,
    this.esPromocion = false,
    this.linkPdf,
  });

  @override
  List<Object?> get props => [id, nombreTour, fechaInicio, fechaFin];
}

class PersonaManifiesto extends Equatable {
  final String nombre;
  final String? tipoDocumento;
  final String? documento;
  final String? telefono;

  const PersonaManifiesto({
    required this.nombre,
    this.tipoDocumento,
    this.documento,
    this.telefono,
  });

  @override
  List<Object?> get props => [nombre, documento];
}

class ReservaManifiesto extends Equatable {
  final int id;
  final String idReserva;
  final String estado;
  final int? busLayoutId;
  final DateTime? fechaCreacion;
  final PersonaManifiesto? responsable;
  final List<PersonaManifiesto> integrantes;

  const ReservaManifiesto({
    required this.id,
    required this.idReserva,
    required this.estado,
    this.busLayoutId,
    this.fechaCreacion,
    this.responsable,
    this.integrantes = const [],
  });

  int get totalPersonas => 1 + integrantes.length;

  @override
  List<Object?> get props => [id, idReserva];
}

class AsientoManifiesto extends Equatable {
  final String numero;
  final int fila;
  final int columna;
  final ReservaManifiesto? reserva;

  const AsientoManifiesto({
    required this.numero,
    required this.fila,
    required this.columna,
    this.reserva,
  });

  bool get libre => reserva == null;

  @override
  List<Object?> get props => [numero, fila, columna];
}

class BusManifiestoData extends Equatable {
  final int busLayoutId;
  final String nombre;
  final int totalAsientosCliente;
  final int asientosOcupados;
  final int asientosDisponibles;
  final String? entrada;
  final BusConfiguracion configuracion;
  final List<AsientoManifiesto> asientos;

  const BusManifiestoData({
    required this.busLayoutId,
    required this.nombre,
    required this.totalAsientosCliente,
    required this.asientosOcupados,
    required this.asientosDisponibles,
    this.entrada,
    required this.configuracion,
    required this.asientos,
  });

  @override
  List<Object?> get props => [busLayoutId];
}

class BusManifiesto extends Equatable {
  final TourInfoManifiesto tour;
  final List<BusManifiestoData> buses;
  final List<ReservaManifiesto> reservasSinAsientos;

  const BusManifiesto({
    required this.tour,
    required this.buses,
    this.reservasSinAsientos = const [],
  });

  @override
  List<Object?> get props => [tour, buses];
}
