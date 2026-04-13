import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/politica_reserva.dart';
import '../../domain/repositories/politica_reserva_repository.dart';
import 'politica_reserva_event.dart';
import 'politica_reserva_state.dart';

class PoliticaReservaBloc
    extends Bloc<PoliticaReservaEvent, PoliticaReservaState> {
  final PoliticaReservaRepository repository;

  PoliticaReservaBloc({required this.repository}) : super(PoliticaInitial()) {
    on<LoadPoliticas>(_onLoadPoliticas);
    on<CreatePolitica>(_onCreatePolitica);
    on<UpdatePolitica>(_onUpdatePolitica);
    on<DeletePolitica>(_onDeletePolitica);
    on<TogglePoliticaActive>(_onTogglePoliticaActive);
  }

  Future<void> _onLoadPoliticas(
    LoadPoliticas event,
    Emitter<PoliticaReservaState> emit,
  ) async {
    emit(PoliticaLoading());
    try {
      final politicas = await repository.getPoliticas();
      emit(PoliticaLoaded(politicas));
    } catch (e) {
      emit(PoliticaError(e.toString()));
    }
  }

  Future<void> _onCreatePolitica(
    CreatePolitica event,
    Emitter<PoliticaReservaState> emit,
  ) async {
    final List<PoliticaReserva> currentPoliticas = state is PoliticaLoaded
        ? (state as PoliticaLoaded).politicas
        : state is PoliticaSaving
            ? ((state as PoliticaSaving).politicas ?? <PoliticaReserva>[])
            : state is PoliticaSaved
                ? (state as PoliticaSaved).politicas
                : <PoliticaReserva>[];

    emit(PoliticaSaving(politicas: currentPoliticas));
    try {
      await repository.createPolitica(event.politica);
      final updatedPoliticas = await repository.getPoliticas();
      emit(PoliticaSaved(updatedPoliticas));
    } catch (e) {
      emit(PoliticaError(e.toString()));
    }
  }

  Future<void> _onUpdatePolitica(
    UpdatePolitica event,
    Emitter<PoliticaReservaState> emit,
  ) async {
    final List<PoliticaReserva> currentPoliticas = state is PoliticaLoaded
        ? (state as PoliticaLoaded).politicas
        : state is PoliticaSaving
            ? ((state as PoliticaSaving).politicas ?? <PoliticaReserva>[])
            : state is PoliticaSaved
                ? (state as PoliticaSaved).politicas
                : <PoliticaReserva>[];

    emit(PoliticaSaving(politicas: currentPoliticas));
    try {
      await repository.updatePolitica(event.politica);
      final updatedPoliticas = await repository.getPoliticas();
      emit(PoliticaSaved(updatedPoliticas));
    } catch (e) {
      emit(PoliticaError(e.toString()));
    }
  }

  Future<void> _onDeletePolitica(
    DeletePolitica event,
    Emitter<PoliticaReservaState> emit,
  ) async {
    final List<PoliticaReserva> currentPoliticas = state is PoliticaLoaded
        ? (state as PoliticaLoaded).politicas
        : state is PoliticaSaving
            ? ((state as PoliticaSaving).politicas ?? <PoliticaReserva>[])
            : state is PoliticaSaved
                ? (state as PoliticaSaved).politicas
                : <PoliticaReserva>[];

    emit(PoliticaSaving(politicas: currentPoliticas));
    try {
      await repository.deletePolitica(event.id);
      final updatedPoliticas = await repository.getPoliticas();
      emit(PoliticaSaved(updatedPoliticas));
    } catch (e) {
      emit(PoliticaError(e.toString()));
    }
  }

  Future<void> _onTogglePoliticaActive(
    TogglePoliticaActive event,
    Emitter<PoliticaReservaState> emit,
  ) async {
    final List<PoliticaReserva> currentPoliticas = state is PoliticaLoaded
        ? (state as PoliticaLoaded).politicas
        : state is PoliticaSaving
            ? ((state as PoliticaSaving).politicas ?? <PoliticaReserva>[])
            : state is PoliticaSaved
                ? (state as PoliticaSaved).politicas
                : <PoliticaReserva>[];

    emit(PoliticaSaving(politicas: currentPoliticas));
    try {
      final politica = currentPoliticas.firstWhere((p) => p.id == event.id);
      await repository.updatePolitica(
        politica.copyWith(activo: !politica.activo),
      );
      final updatedPoliticas = await repository.getPoliticas();
      emit(PoliticaSaved(updatedPoliticas));
    } catch (e) {
      emit(PoliticaError(e.toString()));
    }
  }
}
