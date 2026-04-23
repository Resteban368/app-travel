import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/sede.dart';
import '../../domain/repositories/sede_repository.dart';

// ─── Events ──────────────────────────────────────────────

abstract class SedeEvent extends Equatable {
  const SedeEvent();
  @override
  List<Object?> get props => [];
}

class LoadSedes extends SedeEvent {}

class CreateSede extends SedeEvent {
  final Sede sede;
  const CreateSede(this.sede);
  @override
  List<Object?> get props => [sede];
}

class UpdateSede extends SedeEvent {
  final Sede sede;
  const UpdateSede(this.sede);
  @override
  List<Object?> get props => [sede];
}

class DeleteSede extends SedeEvent {
  final String id;
  const DeleteSede(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleSedeActive extends SedeEvent {
  final String id;
  const ToggleSedeActive(this.id);
  @override
  List<Object?> get props => [id];
}

// ─── States ──────────────────────────────────────────────

abstract class SedeState extends Equatable {
  const SedeState();
  @override
  List<Object?> get props => [];
}

class SedeInitial extends SedeState {}

class SedeLoading extends SedeState {}

class SedesLoaded extends SedeState {
  final List<Sede> sedes;
  const SedesLoaded(this.sedes);
  @override
  List<Object?> get props => [sedes];
}

class SedeError extends SedeState {
  final String message;
  const SedeError(this.message);
  @override
  List<Object?> get props => [message];
}

class SedeSaving extends SedeState {
  final List<Sede>? sedes;
  const SedeSaving({this.sedes});
  @override
  List<Object?> get props => [sedes];
}

class SedeSaved extends SedeState {
  final List<Sede>? sedes;
  const SedeSaved({this.sedes});
  @override
  List<Object?> get props => [sedes];
}

// ─── BLoC ────────────────────────────────────────────────

class SedeBloc extends Bloc<SedeEvent, SedeState> {
  final SedeRepository _sedeRepository;

  SedeBloc({required SedeRepository sedeRepository})
    : _sedeRepository = sedeRepository,
      super(SedeInitial()) {
    on<LoadSedes>(_onLoadSedes);
    on<CreateSede>(_onCreateSede);
    on<UpdateSede>(_onUpdateSede);
    on<DeleteSede>(_onDeleteSede);
    on<ToggleSedeActive>(_onToggleSedeActive);
  }

  Future<void> _onLoadSedes(LoadSedes event, Emitter<SedeState> emit) async {
    emit(SedeLoading());
    try {
      final sedes = await _sedeRepository.getSedes();
      emit(SedesLoaded(sedes));
    } catch (e, s) {
      debugPrint('❌ [SedeBloc] Error loading sedes: $e $s');
      emit(SedeError(e.toString()));
    }
  }

  Future<void> _onCreateSede(CreateSede event, Emitter<SedeState> emit) async {
    final currentState = state;
    final currentSedes = currentState is SedesLoaded
        ? currentState.sedes
        : null;
    emit(SedeSaving(sedes: currentSedes));
    try {
      await _sedeRepository.createSede(event.sede);
      final updated = await _sedeRepository.getSedes();
      emit(SedeSaved(sedes: updated));
      emit(SedesLoaded(updated));
    } catch (e) {
      emit(SedeError(e.toString()));
    }
  }

  Future<void> _onUpdateSede(UpdateSede event, Emitter<SedeState> emit) async {
    final currentState = state;
    final currentSedes = currentState is SedesLoaded
        ? currentState.sedes
        : null;
    emit(SedeSaving(sedes: currentSedes));
    try {
      await _sedeRepository.updateSede(event.sede);
      final updated = await _sedeRepository.getSedes();
      emit(SedeSaved(sedes: updated));
      emit(SedesLoaded(updated));
    } catch (e) {
      emit(SedeError(e.toString()));
    }
  }

  Future<void> _onDeleteSede(DeleteSede event, Emitter<SedeState> emit) async {
    final currentState = state;
    final currentSedes = currentState is SedesLoaded
        ? currentState.sedes
        : null;
    emit(SedeSaving(sedes: currentSedes));
    try {
      await _sedeRepository.deleteSede(event.id);
      final updated = await _sedeRepository.getSedes();
      emit(SedeSaved(sedes: updated));
      emit(SedesLoaded(updated));
    } catch (e) {
      emit(SedeError(e.toString()));
    }
  }

  Future<void> _onToggleSedeActive(
    ToggleSedeActive event,
    Emitter<SedeState> emit,
  ) async {
    final currentState = state;
    if (currentState is SedesLoaded ||
        currentState is SedeSaving ||
        currentState is SedeSaved) {
      List<Sede>? currentSedes;
      if (currentState is SedesLoaded) currentSedes = currentState.sedes;
      if (currentState is SedeSaving) currentSedes = currentState.sedes;
      if (currentState is SedeSaved) currentSedes = currentState.sedes;

      if (currentSedes != null) {
        emit(SedeSaving(sedes: currentSedes));
        try {
          final sede = currentSedes.firstWhere((s) => s.id == event.id);
          final updatedSede = sede.copyWith(isActive: !sede.isActive);
          await _sedeRepository.updateSede(updatedSede);
          final updatedList = await _sedeRepository.getSedes();
          emit(SedeSaved(sedes: updatedList));
          emit(SedesLoaded(updatedList));
        } catch (e) {
          emit(SedeError(e.toString()));
        }
      }
    }
  }
}
