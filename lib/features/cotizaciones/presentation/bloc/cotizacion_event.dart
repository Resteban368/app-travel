import 'package:equatable/equatable.dart';
import '../../domain/entities/cotizacion.dart';

abstract class CotizacionEvent extends Equatable {
  const CotizacionEvent();

  @override
  List<Object?> get props => [];
}

class LoadCotizaciones extends CotizacionEvent {
  final int page;
  final int limit;
  const LoadCotizaciones({this.page = 1, this.limit = 20});

  @override
  List<Object?> get props => [page, limit];
}

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

class UpdateCotizacion extends CotizacionEvent {
  final Cotizacion cotizacion;
  const UpdateCotizacion(this.cotizacion);
  @override
  List<Object?> get props => [cotizacion];
}

class DeleteCotizacion extends CotizacionEvent {
  final int id;
  const DeleteCotizacion(this.id);
  @override
  List<Object?> get props => [id];
}

class UpdateEstadoCotizacion extends CotizacionEvent {
  final int id;
  final String estado;

  const UpdateEstadoCotizacion(this.id, this.estado);

  @override
  List<Object?> get props => [id, estado];
}
