import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auditoria_repository.dart';
import 'auditoria_general_event.dart';
import 'auditoria_general_state.dart';

class AuditoriaGeneralBloc
    extends Bloc<AuditoriaGeneralEvent, AuditoriaGeneralState> {
  final AuditoriaRepository repository;

  AuditoriaGeneralBloc({required this.repository})
      : super(AuditoriaGeneralInitial()) {
    on<LoadAuditoriaGeneral>(_onLoadAuditoriaGeneral);
  }

  Future<void> _onLoadAuditoriaGeneral(
    LoadAuditoriaGeneral event,
    Emitter<AuditoriaGeneralState> emit,
  ) async {
    emit(AuditoriaGeneralLoading());
    try {
      final auditoria = await repository.getAuditoriaGeneral();
      emit(AuditoriaGeneralLoaded(auditoria: auditoria));
    } catch (e) {
      emit(AuditoriaGeneralError(e.toString()));
    }
  }
}
