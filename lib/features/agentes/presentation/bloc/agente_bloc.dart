import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/agente_repository.dart';
import '../../domain/entities/agente.dart';
import 'agente_event.dart';
import 'agente_state.dart';

class AgenteBloc extends Bloc<AgenteEvent, AgenteState> {
  final AgenteRepository repository;

  AgenteBloc({required this.repository}) : super(AgenteInitial()) {
    on<LoadAgentes>(_onLoadAgentes);
    on<CreateAgente>(_onCreateAgente);
    on<UpdateAgente>(_onUpdateAgente);
    on<DeleteAgente>(_onDeleteAgente);
  }

  Future<void> _onLoadAgentes(
    LoadAgentes event,
    Emitter<AgenteState> emit,
  ) async {
    emit(AgenteLoading());
    try {
      final agentes = await repository.getAgentes();
      emit(AgenteLoaded(agentes));
    } catch (e) {
      emit(AgenteError(e.toString()));
    }
  }

  Future<void> _onCreateAgente(
    CreateAgente event,
    Emitter<AgenteState> emit,
  ) async {
    final currentAgentes = _getCurrentAgentes();
    emit(AgenteSaving(agentes: currentAgentes));
    try {
      await repository.createAgente(event.agente);
      final updatedAgentes = await repository.getAgentes();
      emit(AgenteActionSuccess(updatedAgentes));
    } catch (e) {
      emit(AgenteError(e.toString()));
    }
  }

  Future<void> _onUpdateAgente(
    UpdateAgente event,
    Emitter<AgenteState> emit,
  ) async {
    final currentAgentes = _getCurrentAgentes();
    emit(AgenteSaving(agentes: currentAgentes));
    try {
      await repository.updateAgente(event.agente);
      final updatedAgentes = await repository.getAgentes();
      emit(AgenteActionSuccess(updatedAgentes));
    } catch (e) {
      emit(AgenteError(e.toString()));
    }
  }

  Future<void> _onDeleteAgente(
    DeleteAgente event,
    Emitter<AgenteState> emit,
  ) async {
    final currentAgentes = _getCurrentAgentes();
    emit(AgenteSaving(agentes: currentAgentes));
    try {
      await repository.deleteAgente(event.id);
      final updatedAgentes = await repository.getAgentes();
      emit(AgenteActionSuccess(updatedAgentes));
    } catch (e) {
      emit(AgenteError(e.toString()));
    }
  }

  List<Agente> _getCurrentAgentes() {
    if (state is AgenteLoaded) {
      return (state as AgenteLoaded).agentes;
    } else if (state is AgenteSaving) {
      return (state as AgenteSaving).agentes ?? [];
    } else if (state is AgenteActionSuccess) {
      return (state as AgenteActionSuccess).agentes;
    }
    return [];
  }
}
