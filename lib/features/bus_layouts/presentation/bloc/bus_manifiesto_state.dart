import 'package:equatable/equatable.dart';
import '../../domain/entities/bus_manifiesto.dart';

abstract class BusManifiestoState extends Equatable {
  const BusManifiestoState();
  @override
  List<Object?> get props => [];
}

class BusManifiestoInitial extends BusManifiestoState {}

class BusManifiestoLoading extends BusManifiestoState {}

class BusManifiestoLoaded extends BusManifiestoState {
  final BusManifiesto manifiesto;
  const BusManifiestoLoaded(this.manifiesto);
  @override
  List<Object?> get props => [manifiesto];
}

class BusManifiestoError extends BusManifiestoState {
  final String message;
  const BusManifiestoError(this.message);
  @override
  List<Object?> get props => [message];
}

class BusManifiestoAsignando extends BusManifiestoState {
  final BusManifiesto manifiesto;
  const BusManifiestoAsignando(this.manifiesto);
  @override
  List<Object?> get props => [manifiesto];
}

// Para liberar/mover: muestra diálogo de carga
class BusManifiestoOperando extends BusManifiestoState {
  final BusManifiesto manifiesto;
  const BusManifiestoOperando(this.manifiesto);
  @override
  List<Object?> get props => [manifiesto];
}

class BusManifiestoOperacionExito extends BusManifiestoState {
  final BusManifiesto manifiesto;
  const BusManifiestoOperacionExito(this.manifiesto);
  @override
  List<Object?> get props => [manifiesto];
}

class BusManifiestoOperacionError extends BusManifiestoState {
  final BusManifiesto manifiesto;
  final String mensaje;
  const BusManifiestoOperacionError(this.manifiesto, this.mensaje);
  @override
  List<Object?> get props => [manifiesto, mensaje];
}
