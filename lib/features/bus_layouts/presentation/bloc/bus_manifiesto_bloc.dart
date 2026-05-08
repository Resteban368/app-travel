import 'package:agente_viajes/features/bus_layouts/domain/entities/bus_manifiesto.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/bus_manifiesto_repository.dart';
import 'bus_manifiesto_event.dart';
import 'bus_manifiesto_state.dart';

class BusManifiestoBloc extends Bloc<BusManifiestoEvent, BusManifiestoState> {
  final BusManifiestoRepository repository;

  BusManifiestoBloc({required this.repository})
    : super(BusManifiestoInitial()) {
    on<LoadBusManifiesto>(_onLoad);
    on<AutoAsignarAsientos>(_onAutoAsignar);
    on<LiberarAsiento>(_onLiberar);
    on<MoverAsiento>(_onMover);
  }

  Future<void> _onLoad(
    LoadBusManifiesto event,
    Emitter<BusManifiestoState> emit,
  ) async {
    emit(BusManifiestoLoading());
    try {
      final manifiesto = await repository.getBusManifiesto(event.tourId);
      emit(BusManifiestoLoaded(manifiesto));
    } catch (e) {
      emit(BusManifiestoError(e.toString()));
    }
  }

  BusManifiesto? _manifiestoActual() {
    final s = state;
    if (s is BusManifiestoLoaded) return s.manifiesto;
    if (s is BusManifiestoOperacionExito) return s.manifiesto;
    if (s is BusManifiestoOperacionError) return s.manifiesto;
    if (s is BusManifiestoAsignando) return s.manifiesto;
    if (s is BusManifiestoOperando) return s.manifiesto;
    return null;
  }

  Future<void> _onAutoAsignar(
    AutoAsignarAsientos event,
    Emitter<BusManifiestoState> emit,
  ) async {
    final current = _manifiestoActual();
    if (current == null) return;
    emit(BusManifiestoAsignando(current));
    try {
      await repository.autoAsignarAsientos(event.tourId);
      final manifiesto = await repository.getBusManifiesto(event.tourId);
      emit(BusManifiestoLoaded(manifiesto));
    } catch (e) {
      emit(BusManifiestoLoaded(current));
    }
  }

  Future<void> _onLiberar(
    LiberarAsiento event,
    Emitter<BusManifiestoState> emit,
  ) async {
    final current = _manifiestoActual();
    if (current == null) return;
    emit(BusManifiestoOperando(current));
    try {
      await repository.liberarAsiento(
        tourId: event.tourId,
        reservaId: event.reservaId,
        numeroAsiento: event.numeroAsiento,
      );
      final manifiesto = await repository.getBusManifiesto(event.tourId);
      emit(BusManifiestoOperacionExito(manifiesto));
    } catch (e) {
      emit(BusManifiestoOperacionError(current, e.toString()));
    }
  }

  Future<void> _onMover(
    MoverAsiento event,
    Emitter<BusManifiestoState> emit,
  ) async {
    final current = _manifiestoActual();
    if (current == null) return;
    emit(BusManifiestoOperando(current));
    try {
      await repository.moverAsiento(
        tourId: event.tourId,
        busLayoutId: event.busLayoutId,
        reservaIdOrigen: event.reservaIdOrigen,
        asientoOrigen: event.asientoOrigen,
        asientoDestino: event.asientoDestino,
      );
      final manifiesto = await repository.getBusManifiesto(event.tourId);
      emit(BusManifiestoOperacionExito(manifiesto));
    } catch (e) {
      emit(BusManifiestoOperacionError(current, e.toString()));
    }
  }
}
