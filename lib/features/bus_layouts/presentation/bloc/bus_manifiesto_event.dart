import 'package:equatable/equatable.dart';

abstract class BusManifiestoEvent extends Equatable {
  const BusManifiestoEvent();
  @override
  List<Object?> get props => [];
}

class LoadBusManifiesto extends BusManifiestoEvent {
  final int tourId;
  const LoadBusManifiesto(this.tourId);
  @override
  List<Object?> get props => [tourId];
}

class AutoAsignarAsientos extends BusManifiestoEvent {
  final int tourId;
  const AutoAsignarAsientos(this.tourId);
  @override
  List<Object?> get props => [tourId];
}

class LiberarAsiento extends BusManifiestoEvent {
  final int tourId;
  final int reservaId;
  final String numeroAsiento;
  const LiberarAsiento({required this.tourId, required this.reservaId, required this.numeroAsiento});
  @override
  List<Object?> get props => [tourId, reservaId, numeroAsiento];
}

class MoverAsiento extends BusManifiestoEvent {
  final int tourId;
  final int busLayoutId;
  final int reservaIdOrigen;
  final String asientoOrigen;
  final String asientoDestino;
  const MoverAsiento({
    required this.tourId,
    required this.busLayoutId,
    required this.reservaIdOrigen,
    required this.asientoOrigen,
    required this.asientoDestino,
  });
  @override
  List<Object?> get props => [tourId, reservaIdOrigen, asientoOrigen, asientoDestino];
}

class AsignarAsientoManual extends BusManifiestoEvent {
  final int tourId;
  final int busLayoutId;
  final int reservaId;
  final List<String> asientos;
  const AsignarAsientoManual({
    required this.tourId,
    required this.busLayoutId,
    required this.reservaId,
    required this.asientos,
  });
  @override
  List<Object?> get props => [tourId, busLayoutId, reservaId, asientos];
}
