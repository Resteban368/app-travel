import 'package:equatable/equatable.dart';
import '../../domain/entities/cotizacion.dart';
import '../../domain/entities/respuesta_cotizacion.dart';

abstract class CotizacionState extends Equatable {
  const CotizacionState();

  @override
  List<Object?> get props => [];
}

class CotizacionInitial extends CotizacionState {}

class CotizacionLoading extends CotizacionState {}

class CotizacionLoaded extends CotizacionState {
  // Tab 1: Sin Respuesta
  final List<Cotizacion> pendingCotizaciones;
  final int pendingPage;
  final int pendingTotalPages;
  final int pendingTotal;

  // Tab 2: Con Respuesta
  final List<Cotizacion> attendedCotizaciones;
  final int attendedPage;
  final int attendedTotalPages;
  final int attendedTotal;

  // Tab 2: Mis Respuestas (paginated, cumulative for infinite scroll)
  final List<RespuestaCotizacion> misRespuestas;
  final int misRespuestasPage;
  final int misRespuestasTotalPages;
  final int misRespuestasTotal;
  final bool misRespuestasLoading;

  // Tab 3: Plantillas (paginated, cumulative for infinite scroll)
  final List<RespuestaCotizacion> plantillas;
  final int plantillasPage;
  final int plantillasTotalPages;
  final int plantillasTotal;
  final bool plantillasLoading;

  final int limit;

  const CotizacionLoaded({
    required this.pendingCotizaciones,
    this.pendingPage = 1,
    this.pendingTotalPages = 1,
    this.pendingTotal = 0,
    required this.attendedCotizaciones,
    this.attendedPage = 1,
    this.attendedTotalPages = 1,
    this.attendedTotal = 0,
    required this.misRespuestas,
    this.misRespuestasPage = 1,
    this.misRespuestasTotalPages = 1,
    this.misRespuestasTotal = 0,
    this.misRespuestasLoading = false,
    required this.plantillas,
    this.plantillasPage = 1,
    this.plantillasTotalPages = 1,
    this.plantillasTotal = 0,
    this.plantillasLoading = false,
    this.limit = 20,
  });

  bool get hasMoreMisRespuestas => misRespuestasPage < misRespuestasTotalPages;
  bool get hasMorePlantillas => plantillasPage < plantillasTotalPages;

  CotizacionLoaded copyWith({
    List<Cotizacion>? pendingCotizaciones,
    int? pendingPage,
    int? pendingTotalPages,
    int? pendingTotal,
    List<Cotizacion>? attendedCotizaciones,
    int? attendedPage,
    int? attendedTotalPages,
    int? attendedTotal,
    List<RespuestaCotizacion>? misRespuestas,
    int? misRespuestasPage,
    int? misRespuestasTotalPages,
    int? misRespuestasTotal,
    bool? misRespuestasLoading,
    List<RespuestaCotizacion>? plantillas,
    int? plantillasPage,
    int? plantillasTotalPages,
    int? plantillasTotal,
    bool? plantillasLoading,
    int? limit,
  }) {
    return CotizacionLoaded(
      pendingCotizaciones: pendingCotizaciones ?? this.pendingCotizaciones,
      pendingPage: pendingPage ?? this.pendingPage,
      pendingTotalPages: pendingTotalPages ?? this.pendingTotalPages,
      pendingTotal: pendingTotal ?? this.pendingTotal,
      attendedCotizaciones: attendedCotizaciones ?? this.attendedCotizaciones,
      attendedPage: attendedPage ?? this.attendedPage,
      attendedTotalPages: attendedTotalPages ?? this.attendedTotalPages,
      attendedTotal: attendedTotal ?? this.attendedTotal,
      misRespuestas: misRespuestas ?? this.misRespuestas,
      misRespuestasPage: misRespuestasPage ?? this.misRespuestasPage,
      misRespuestasTotalPages: misRespuestasTotalPages ?? this.misRespuestasTotalPages,
      misRespuestasTotal: misRespuestasTotal ?? this.misRespuestasTotal,
      misRespuestasLoading: misRespuestasLoading ?? this.misRespuestasLoading,
      plantillas: plantillas ?? this.plantillas,
      plantillasPage: plantillasPage ?? this.plantillasPage,
      plantillasTotalPages: plantillasTotalPages ?? this.plantillasTotalPages,
      plantillasTotal: plantillasTotal ?? this.plantillasTotal,
      plantillasLoading: plantillasLoading ?? this.plantillasLoading,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
        pendingCotizaciones,
        pendingPage,
        pendingTotalPages,
        pendingTotal,
        attendedCotizaciones,
        attendedPage,
        attendedTotalPages,
        attendedTotal,
        misRespuestas,
        misRespuestasPage,
        misRespuestasTotalPages,
        misRespuestasTotal,
        misRespuestasLoading,
        plantillas,
        plantillasPage,
        plantillasTotalPages,
        plantillasTotal,
        plantillasLoading,
        limit,
      ];
}

class CotizacionSaving extends CotizacionState {}

class CotizacionSaved extends CotizacionState {}

class CotizacionDeleting extends CotizacionState {}

class CotizacionDeleteSuccess extends CotizacionState {
  final String message;
  const CotizacionDeleteSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CotizacionError extends CotizacionState {
  final String message;

  const CotizacionError(this.message);

  @override
  List<Object?> get props => [message];
}
