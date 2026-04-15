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

  const CotizacionLoaded(this.cotizaciones);

  @override
  List<Object?> get props => [cotizaciones];
}

class CotizacionSaving extends CotizacionState {}

class CotizacionSaved extends CotizacionState {}

class CotizacionError extends CotizacionState {
  final String message;

  const CotizacionError(this.message);

  @override
  List<Object?> get props => [message];
}
