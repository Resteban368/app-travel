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
  // Tab 1: Sin Respuesta (estado != 'atendida')
  final List<Cotizacion> pendingCotizaciones;
  final int pendingPage;
  final int pendingTotalPages;
  final int pendingTotal;

  // Tab 2: Con Respuesta (estado == 'atendida')
  final List<Cotizacion> attendedCotizaciones;
  final int attendedPage;
  final int attendedTotalPages;
  final int attendedTotal;

  // Tab 2: Todas las Respuestas
  final List<RespuestaCotizacion> allRespuestas;

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
    required this.allRespuestas,
    this.limit = 20,
  });

  CotizacionLoaded copyWith({
    List<Cotizacion>? pendingCotizaciones,
    int? pendingPage,
    int? pendingTotalPages,
    int? pendingTotal,
    List<Cotizacion>? attendedCotizaciones,
    int? attendedPage,
    int? attendedTotalPages,
    int? attendedTotal,
    List<RespuestaCotizacion>? allRespuestas,
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
      allRespuestas: allRespuestas ?? this.allRespuestas,
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
        allRespuestas,
        limit,
      ];
}

class CotizacionSaving extends CotizacionState {}

class CotizacionSaved extends CotizacionState {}

class CotizacionError extends CotizacionState {
  final String message;

  const CotizacionError(this.message);

  @override
  List<Object?> get props => [message];
}
