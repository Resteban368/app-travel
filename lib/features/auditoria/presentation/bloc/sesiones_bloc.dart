import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auditoria_repository.dart';
import 'sesiones_event.dart';
import 'sesiones_state.dart';

class SesionesBloc extends Bloc<SesionesEvent, SesionesState> {
  final AuditoriaRepository repository;

  SesionesBloc({required this.repository}) : super(SesionesInitial()) {
    on<LoadSesiones>(_onLoadSesiones);
  }

  Future<void> _onLoadSesiones(
    LoadSesiones event,
    Emitter<SesionesState> emit,
  ) async {
    emit(SesionesLoading());
    try {
      final fecha = event.fecha ?? DateTime.now();
      final sesiones = await repository.getSesiones(fecha: fecha);
      emit(SesionesLoaded(sesiones: sesiones, fecha: fecha));
    } catch (e) {
      emit(SesionesError(e.toString()));
    }
  }
}
