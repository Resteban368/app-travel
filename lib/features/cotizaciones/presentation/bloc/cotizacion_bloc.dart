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
  }

  Future<void> _onLoadCotizaciones(
    LoadCotizaciones event,
    Emitter<CotizacionState> emit,
  ) async {
    emit(CotizacionLoading());
    try {
      final cotizaciones = await repository.getCotizaciones();
      emit(CotizacionLoaded(cotizaciones));
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

        emit(CotizacionLoaded(updatedCotizaciones));
      } catch (e) {
        emit(CotizacionError(e.toString()));
        // Optionally, emit the loaded state again so UI can recover
        emit(CotizacionLoaded(currentState.cotizaciones));
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
      final cotizaciones = await repository.getCotizaciones();
      emit(CotizacionLoaded(cotizaciones));
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

        emit(CotizacionLoaded(updatedCotizaciones));
      } catch (e) {
        emit(CotizacionError(e.toString()));
        emit(CotizacionLoaded(currentState.cotizaciones));
      }
    }
  }
}
