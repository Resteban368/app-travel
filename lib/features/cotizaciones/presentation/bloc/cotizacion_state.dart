import 'package:equatable/equatable.dart';
import '../../domain/entities/cotizacion.dart';

abstract class CotizacionState extends Equatable {
  const CotizacionState();

  @override
  List<Object?> get props => [];
}

class CotizacionInitial extends CotizacionState {}

class CotizacionLoading extends CotizacionState {}

class CotizacionLoaded extends CotizacionState {
  final List<Cotizacion> cotizaciones;
  final int page;
  final int totalPages;
  final int total;
  final int limit;

  const CotizacionLoaded(
    this.cotizaciones, {
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [cotizaciones, page, totalPages, total, limit];
}

class CotizacionSaving extends CotizacionState {}

class CotizacionSaved extends CotizacionState {}

class CotizacionError extends CotizacionState {
  final String message;

  const CotizacionError(this.message);

  @override
  List<Object?> get props => [message];
}
