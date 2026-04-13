import 'package:equatable/equatable.dart';

abstract class CotizacionEvent extends Equatable {
  const CotizacionEvent();

  @override
  List<Object> get props => [];
}

class LoadCotizaciones extends CotizacionEvent {}

class MarkCotizacionAsRead extends CotizacionEvent {
  final int id;

  const MarkCotizacionAsRead(this.id);

  @override
  List<Object> get props => [id];
}
