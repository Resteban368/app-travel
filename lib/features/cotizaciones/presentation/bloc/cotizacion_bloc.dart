import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/cotizacion_repository.dart';
import '../../domain/repositories/respuesta_cotizacion_repository.dart';
import 'cotizacion_event.dart';
import 'cotizacion_state.dart';

class CotizacionBloc extends Bloc<CotizacionEvent, CotizacionState> {
  final CotizacionRepository repository;
  final RespuestaCotizacionRepository respuestaRepository;

  CotizacionBloc({
    required this.repository,
    required this.respuestaRepository,
  }) : super(CotizacionInitial()) {
    on<LoadPendingCotizaciones>(_onLoadPendingCotizaciones);
    on<LoadAttendedCotizaciones>(_onLoadAttendedCotizaciones);
    on<LoadStandaloneRespuestas>(_onLoadStandaloneRespuestas);
    on<LoadAllData>(_onLoadAllData);
    on<MarkCotizacionAsRead>(_onMarkCotizacionAsRead);
    on<CreateCotizacion>(_onCreateCotizacion);
    on<UpdateEstadoCotizacion>(_onUpdateEstadoCotizacion);
    on<UpdateCotizacion>(_onUpdateCotizacion);
    on<DeleteCotizacion>(_onDeleteCotizacion);
  }

  Future<void> _onLoadPendingCotizaciones(
    LoadPendingCotizaciones event,
    Emitter<CotizacionState> emit,
  ) async {
    // Reload all data since the backend doesn't support server-side filtering
    add(const LoadAllData());
  }

  Future<void> _onLoadAttendedCotizaciones(
    LoadAttendedCotizaciones event,
    Emitter<CotizacionState> emit,
  ) async {
    // Reload all data since the backend doesn't support server-side filtering
    add(const LoadAllData());
  }

  Future<void> _onLoadStandaloneRespuestas(
    LoadStandaloneRespuestas event,
    Emitter<CotizacionState> emit,
  ) async {
    final currentState = state is CotizacionLoaded ? state as CotizacionLoaded : null;
    emit(CotizacionLoading());
    try {
      final respuestas = await respuestaRepository.getRespuestas(sinCotizacion: false);
      emit(
        currentState != null
            ? currentState.copyWith(allRespuestas: respuestas)
            : CotizacionLoaded(
                pendingCotizaciones: const [],
                attendedCotizaciones: const [],
                allRespuestas: respuestas,
              ),
      );
    } catch (e) {
      emit(CotizacionError(e.toString()));
    }
  }

  Future<void> _onLoadAllData(
    LoadAllData event,
    Emitter<CotizacionState> emit,
  ) async {
    emit(CotizacionLoading());
    try {
      final allResult = await repository.getCotizaciones(page: 1, limit: 100);
      final respuestasResult = await respuestaRepository.getRespuestas(sinCotizacion: false);

      // Split client-side: pending = sin respuesta_cotizacion_id, attended = con respuesta_cotizacion_id
      final pending = allResult.data.where((c) => c.respuestaCotizacionId == null).toList();
      final attended = allResult.data.where((c) => c.respuestaCotizacionId != null).toList();

      emit(
        CotizacionLoaded(
          pendingCotizaciones: pending,
          pendingPage: 1,
          pendingTotalPages: 1,
          pendingTotal: pending.length,
          attendedCotizaciones: attended,
          attendedPage: 1,
          attendedTotalPages: 1,
          attendedTotal: attended.length,
          allRespuestas: respuestasResult,
        ),
      );
    } catch (e) {
      emit(CotizacionError(e.toString()));
    }
  }

  Future<void> _onMarkCotizacionAsRead(
    MarkCotizacionAsRead event,
    Emitter<CotizacionState> emit,
  ) async {
    if (state is CotizacionLoaded) {
      final currentState = state as CotizacionLoaded;
      try {
        await repository.markAsRead(event.id);

        final pendingUpdated = currentState.pendingCotizaciones.map((c) => c.id == event.id ? c.copyWith(isRead: true) : c).toList();
        final attendedUpdated = currentState.attendedCotizaciones.map((c) => c.id == event.id ? c.copyWith(isRead: true) : c).toList();

        emit(currentState.copyWith(
          pendingCotizaciones: pendingUpdated,
          attendedCotizaciones: attendedUpdated,
        ));
      } catch (e) {
        emit(CotizacionError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> _onCreateCotizacion(
    CreateCotizacion event,
    Emitter<CotizacionState> emit,
  ) async {
    emit(CotizacionSaving());
    try {
      await repository.createCotizacion(event.cotizacion);
      emit(CotizacionSaved());
      add(const LoadAllData());
    } catch (e) {
      emit(CotizacionError(e.toString()));
    }
  }

  Future<void> _onUpdateEstadoCotizacion(
    UpdateEstadoCotizacion event,
    Emitter<CotizacionState> emit,
  ) async {
    if (state is CotizacionLoaded) {
      final currentState = state as CotizacionLoaded;
      try {
        await repository.updateEstado(event.id, event.estado);
        add(const LoadAllData());
      } catch (e) {
        emit(CotizacionError(e.toString()));
        emit(currentState);
      }
    }
  }

  Future<void> _onUpdateCotizacion(
    UpdateCotizacion event,
    Emitter<CotizacionState> emit,
  ) async {
    emit(CotizacionSaving());
    try {
      await repository.updateCotizacion(event.cotizacion);
      emit(CotizacionSaved());
      add(const LoadAllData());
    } catch (e) {
      emit(CotizacionError(e.toString()));
    }
  }

  Future<void> _onDeleteCotizacion(
    DeleteCotizacion event,
    Emitter<CotizacionState> emit,
  ) async {
    final currentState = state;
    try {
      await repository.deleteCotizacion(event.id);
      if (currentState is CotizacionLoaded) {
        final pendingUpdated = currentState.pendingCotizaciones.where((c) => c.id != event.id).toList();
        final attendedUpdated = currentState.attendedCotizaciones.where((c) => c.id != event.id).toList();

        emit(currentState.copyWith(
          pendingCotizaciones: pendingUpdated,
          pendingTotal: pendingUpdated.length < currentState.pendingCotizaciones.length ? currentState.pendingTotal - 1 : currentState.pendingTotal,
          attendedCotizaciones: attendedUpdated,
          attendedTotal: attendedUpdated.length < currentState.attendedCotizaciones.length ? currentState.attendedTotal - 1 : currentState.attendedTotal,
        ));
      } else {
        add(const LoadAllData());
      }
    } catch (e) {
      emit(CotizacionError(e.toString()));
    }
  }
}
