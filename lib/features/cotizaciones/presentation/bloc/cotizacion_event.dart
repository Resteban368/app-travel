import 'package:equatable/equatable.dart';
import '../../domain/entities/cotizacion.dart';

abstract class CotizacionEvent extends Equatable {
  const CotizacionEvent();

  @override
  List<Object?> get props => [];
}

class LoadCotizaciones extends CotizacionEvent {}

class MarkCotizacionAsRead extends CotizacionEvent {
  final int id;

  const MarkCotizacionAsRead(this.id);

  @override
  List<Object> get props => [id];
}

class CreateCotizacion extends CotizacionEvent {
  final Cotizacion cotizacion;
  const CreateCotizacion(this.cotizacion);
  @override
  List<Object?> get props => [cotizacion];
}

class UpdateEstadoCotizacion extends CotizacionEvent {
  final int id;
  final String estado;

  const UpdateEstadoCotizacion(this.id, this.estado);

  @override
  List<Object?> get props => [id, estado];
}
