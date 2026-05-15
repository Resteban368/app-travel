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
    on<LoadMoreMisRespuestas>(_onLoadMoreMisRespuestas);
    on<LoadMorePlantillas>(_onLoadMorePlantillas);
    on<MarkCotizacionAsRead>(_onMarkCotizacionAsRead);
    on<CreateCotizacion>(_onCreateCotizacion);
    on<UpdateEstadoCotizacion>(_onUpdateEstadoCotizacion);
    on<UpdateCotizacion>(_onUpdateCotizacion);
    on<DeleteCotizacion>(_onDeleteCotizacion);
    on<DeleteRespuestaCotizacion>(_onDeleteRespuestaCotizacion);
    on<ToggleAncladaRespuesta>(_onToggleAncladaRespuesta);
  }

  Future<void> _onLoadPendingCotizaciones(
    LoadPendingCotizaciones event,
    Emitter<CotizacionState> emit,
  ) async {
    add(const LoadAllData());
  }

  Future<void> _onLoadAttendedCotizaciones(
    LoadAttendedCotizaciones event,
    Emitter<CotizacionState> emit,
  ) async {
    add(const LoadAllData());
  }

  Future<void> _onLoadStandaloneRespuestas(
    LoadStandaloneRespuestas event,
    Emitter<CotizacionState> emit,
  ) async {
    add(const LoadAllData());
  }

  Future<void> _onLoadAllData(
    LoadAllData event,
    Emitter<CotizacionState> emit,
  ) async {
    emit(CotizacionLoading());
    try {
      // Start all three in parallel
      final cotizacionesFuture = repository.getCotizaciones(page: 1, limit: 100);
      final misRespuestasFuture = respuestaRepository.getRespuestas(page: 1, limit: 20);
      final plantillasFuture = respuestaRepository.getPlantillas(page: 1, limit: 20);

      final allResult = await cotizacionesFuture;
      final misRespuestasResult = await misRespuestasFuture;
      final plantillasResult = await plantillasFuture;

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
          misRespuestas: misRespuestasResult.data,
          misRespuestasPage: misRespuestasResult.page,
          misRespuestasTotalPages: misRespuestasResult.totalPages,
          misRespuestasTotal: misRespuestasResult.total,
          plantillas: plantillasResult.data,
          plantillasPage: plantillasResult.page,
          plantillasTotalPages: plantillasResult.totalPages,
          plantillasTotal: plantillasResult.total,
        ),
      );
    } catch (e) {
      emit(CotizacionError(e.toString()));
    }
  }

  Future<void> _onLoadMoreMisRespuestas(
    LoadMoreMisRespuestas event,
    Emitter<CotizacionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CotizacionLoaded) return;
    if (!currentState.hasMoreMisRespuestas || currentState.misRespuestasLoading) return;

    emit(currentState.copyWith(misRespuestasLoading: true));
    try {
      final nextPage = currentState.misRespuestasPage + 1;
      final result = await respuestaRepository.getRespuestas(
        page: nextPage,
        limit: currentState.limit,
      );
      emit(currentState.copyWith(
        misRespuestas: [...currentState.misRespuestas, ...result.data],
        misRespuestasPage: result.page,
        misRespuestasTotalPages: result.totalPages,
        misRespuestasTotal: result.total,
        misRespuestasLoading: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(misRespuestasLoading: false));
    }
  }

  Future<void> _onLoadMorePlantillas(
    LoadMorePlantillas event,
    Emitter<CotizacionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CotizacionLoaded) return;
    if (!currentState.hasMorePlantillas || currentState.plantillasLoading) return;

    emit(currentState.copyWith(plantillasLoading: true));
    try {
      final nextPage = currentState.plantillasPage + 1;
      final result = await respuestaRepository.getPlantillas(
        page: nextPage,
        limit: currentState.limit,
      );
      emit(currentState.copyWith(
        plantillas: [...currentState.plantillas, ...result.data],
        plantillasPage: result.page,
        plantillasTotalPages: result.totalPages,
        plantillasTotal: result.total,
        plantillasLoading: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(plantillasLoading: false));
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
    emit(CotizacionDeleting());
    try {
      await repository.deleteCotizacion(event.id);
      emit(const CotizacionDeleteSuccess('Cotización eliminada correctamente'));
      add(const LoadAllData());
    } catch (e) {
      emit(CotizacionError(e.toString()));
      if (currentState is CotizacionLoaded) emit(currentState);
    }
  }

  Future<void> _onToggleAncladaRespuesta(
    ToggleAncladaRespuesta event,
    Emitter<CotizacionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CotizacionLoaded) return;

    // Optimistic update — both lists, re-sort mis respuestas so anchored float up
    final updatedMis = currentState.misRespuestas.map((r) {
      return r.id == event.id ? r.copyWith(anclada: event.anclada) : r;
    }).toList()
      ..sort((a, b) {
        if (a.anclada != b.anclada) return a.anclada ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    final updatedPlantillas = currentState.plantillas.map((r) {
      return r.id == event.id ? r.copyWith(anclada: event.anclada) : r;
    }).toList()
      ..sort((a, b) {
        if (a.anclada != b.anclada) return a.anclada ? -1 : 1;
        return b.createdAt.compareTo(a.createdAt);
      });

    emit(currentState.copyWith(
      misRespuestas: updatedMis,
      plantillas: updatedPlantillas,
    ));

    try {
      await respuestaRepository.toggleAnclada(event.id, anclada: event.anclada);
    } catch (e) {
      // Revert on error
      emit(currentState);
    }
  }

  Future<void> _onDeleteRespuestaCotizacion(
    DeleteRespuestaCotizacion event,
    Emitter<CotizacionState> emit,
  ) async {
    final currentState = state;
    emit(CotizacionDeleting());
    try {
      await respuestaRepository.deleteRespuesta(event.id);
      emit(const CotizacionDeleteSuccess('Respuesta eliminada correctamente'));
      add(const LoadAllData());
    } catch (e) {
      emit(CotizacionError(e.toString()));
      if (currentState is CotizacionLoaded) emit(currentState);
    }
  }
}
