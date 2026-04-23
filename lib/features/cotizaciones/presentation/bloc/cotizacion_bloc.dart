import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/cotizacion_repository.dart';
import 'cotizacion_event.dart';
import 'cotizacion_state.dart';

class CotizacionBloc extends Bloc<CotizacionEvent, CotizacionState> {
  final CotizacionRepository repository;

  CotizacionBloc({required this.repository}) : super(CotizacionInitial()) {
    on<LoadCotizaciones>(_onLoadCotizaciones);
    on<MarkCotizacionAsRead>(_onMarkCotizacionAsRead);
    on<CreateCotizacion>(_onCreateCotizacion);
    on<UpdateEstadoCotizacion>(_onUpdateEstadoCotizacion);
    on<UpdateCotizacion>(_onUpdateCotizacion);
    on<DeleteCotizacion>(_onDeleteCotizacion);
  }

  Future<void> _onLoadCotizaciones(
    LoadCotizaciones event,
    Emitter<CotizacionState> emit,
  ) async {
    emit(CotizacionLoading());
    try {
      final result = await repository.getCotizaciones(
        page: event.page,
        limit: event.limit,
      );
      emit(
        CotizacionLoaded(
          result.data,
          page: result.page,
          totalPages: result.totalPages,
          total: result.total,
          limit: result.limit,
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

        // Update local state without re-fetching
        final updatedCotizaciones = currentState.cotizaciones.map((cotizacion) {
          if (cotizacion.id == event.id) {
            return cotizacion.copyWith(isRead: true);
          }
          return cotizacion;
        }).toList();

        emit(
          CotizacionLoaded(
            updatedCotizaciones,
            page: currentState.page,
            totalPages: currentState.totalPages,
            total: currentState.total,
            limit: currentState.limit,
          ),
        );
      } catch (e) {
        emit(CotizacionError(e.toString()));
        // Optionally, emit the loaded state again so UI can recover
        emit(
          CotizacionLoaded(
            currentState.cotizaciones,
            page: currentState.page,
            totalPages: currentState.totalPages,
            total: currentState.total,
            limit: currentState.limit,
          ),
        );
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
      // Recargar la lista después de crear
      final result = await repository.getCotizaciones(page: 1, limit: 20);
      emit(
        CotizacionLoaded(
          result.data,
          page: result.page,
          totalPages: result.totalPages,
          total: result.total,
          limit: result.limit,
        ),
      );
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

        final updatedCotizaciones = currentState.cotizaciones.map((cotizacion) {
          if (cotizacion.id == event.id) {
            return cotizacion.copyWith(estado: event.estado);
          }
          return cotizacion;
        }).toList();

        emit(
          CotizacionLoaded(
            updatedCotizaciones,
            page: currentState.page,
            totalPages: currentState.totalPages,
            total: currentState.total,
            limit: currentState.limit,
          ),
        );
      } catch (e) {
        emit(CotizacionError(e.toString()));
        emit(
          CotizacionLoaded(
            currentState.cotizaciones,
            page: currentState.page,
            totalPages: currentState.totalPages,
            total: currentState.total,
            limit: currentState.limit,
          ),
        );
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
      // Re-load list to get updated results
      add(const LoadCotizaciones(page: 1, limit: 20));
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
        final updatedList = currentState.cotizaciones
            .where((c) => c.id != event.id)
            .toList();
        emit(
          CotizacionLoaded(
            updatedList,
            page: currentState.page,
            totalPages: currentState.totalPages,
            total: currentState.total - 1,
            limit: currentState.limit,
          ),
        );
      } else {
        add(const LoadCotizaciones(page: 1, limit: 20));
      }
    } catch (e) {
      emit(CotizacionError(e.toString()));
    }
  }
}
