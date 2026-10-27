import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/opinion.dart';
import '../../domain/repositories/opinion_repository.dart';
import 'opinion_event.dart';
import 'opinion_state.dart';

class OpinionBloc extends Bloc<OpinionEvent, OpinionState> {
  final OpinionRepository _repository;

  OpinionBloc({required OpinionRepository repository})
    : _repository = repository,
      super(OpinionInitial()) {
    on<LoadOpiniones>(_onLoad);
    on<SetOpinionAprobada>(_onSetAprobada);
    on<DeleteOpinion>(_onDelete);
  }

  List<Opinion>? get _current => switch (state) {
    OpinionesLoaded(:final opiniones) => opiniones,
    OpinionSaving(:final opiniones) => opiniones,
    OpinionSaved(:final opiniones) => opiniones,
    _ => null,
  };

  Future<void> _onLoad(LoadOpiniones event, Emitter<OpinionState> emit) async {
    if (_current == null) emit(OpinionLoading());
    try {
      emit(OpinionesLoaded(await _repository.getOpiniones()));
    } catch (e) {
      emit(OpinionError(e.toString()));
    }
  }

  Future<void> _onSetAprobada(
    SetOpinionAprobada event,
    Emitter<OpinionState> emit,
  ) async {
    final current = _current;
    emit(OpinionSaving(current));
    try {
      await _repository.setAprobada(event.id, event.aprobada);
      emit(
        OpinionSaved(
          event.aprobada
              ? 'Opinión publicada en la web'
              : 'Opinión retirada de la web',
          current,
        ),
      );
      add(LoadOpiniones());
    } catch (e) {
      emit(OpinionError(e.toString()));
      add(LoadOpiniones());
    }
  }

  Future<void> _onDelete(
    DeleteOpinion event,
    Emitter<OpinionState> emit,
  ) async {
    final current = _current;
    emit(OpinionSaving(current));
    try {
      await _repository.deleteOpinion(event.id);
      emit(OpinionSaved('Opinión eliminada', current));
      add(LoadOpiniones());
    } catch (e) {
      emit(OpinionError(e.toString()));
      add(LoadOpiniones());
    }
  }
}
