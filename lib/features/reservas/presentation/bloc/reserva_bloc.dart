import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/reserva_repository.dart';
import '../../domain/entities/reserva.dart';
import 'reserva_event.dart';
import 'reserva_state.dart';

class ReservaBloc extends Bloc<ReservaEvent, ReservaState> {
  final ReservaRepository repository;

  ReservaBloc({required this.repository}) : super(ReservaInitial()) {
    on<LoadReservas>(_onLoadReservas);
    on<CreateReserva>(_onCreateReserva);
    on<UpdateReserva>(_onUpdateReserva);
  }

  Future<void> _onLoadReservas(
    LoadReservas event,
    Emitter<ReservaState> emit,
  ) async {
    final isFirstPage = event.page == 1;
    if (isFirstPage) {
      emit(ReservaLoading());
    }

    try {
      final result = await repository.getReservas(
        page: event.page,
        limit: event.limit,
        startDate: event.startDate,
        endDate: event.endDate,
        status: event.status,
        search: event.search,
      );

      final hasReachedMax = result.data.length < event.limit || result.page >= result.totalPages;

      if (isFirstPage) {
        emit(
          ReservaLoaded(
            result.data,
            page: result.page,
            totalPages: result.totalPages,
            total: result.total,
            limit: result.limit,
            hasReachedMax: hasReachedMax,
            filterSearch: event.search,
            filterStatus: event.status,
            filterStartDate: event.startDate,
            filterEndDate: event.endDate,
          ),
        );
      } else {
        if (state is ReservaLoaded) {
          final current = state as ReservaLoaded;
          emit(
            ReservaLoaded(
              List.from(current.reservas)..addAll(result.data),
              page: result.page,
              totalPages: result.totalPages,
              total: result.total,
              limit: result.limit,
              hasReachedMax: hasReachedMax,
              filterSearch: event.search,
              filterStatus: event.status,
              filterStartDate: event.startDate,
              filterEndDate: event.endDate,
            ),
          );
        }
      }
    } catch (e) {
      emit(ReservaError(e.toString()));
    }
  }

  Future<void> _onCreateReserva(
    CreateReserva event,
    Emitter<ReservaState> emit,
  ) async {
    final currentReservas = _getCurrentReservas();
    emit(ReservaSaving(reservas: currentReservas));
    try {
      final created = await repository.createReserva(event.reserva);
      final result = await repository.getReservas(page: 1, limit: 20);
      emit(ReservaActionSuccess(result.data, createdReserva: created));
    } catch (e) {
      emit(ReservaError(e.toString()));
    }
  }

  Future<void> _onUpdateReserva(
    UpdateReserva event,
    Emitter<ReservaState> emit,
  ) async {
    final currentReservas = _getCurrentReservas();
    emit(ReservaSaving(reservas: currentReservas));
    try {
      await repository.updateReserva(event.reserva);
      final result = await repository.getReservas(page: 1, limit: 20);
      emit(ReservaActionSuccess(result.data));
    } catch (e) {
      emit(ReservaError(e.toString()));
    }
  }

  List<Reserva> _getCurrentReservas() {
    if (state is ReservaLoaded) {
      return (state as ReservaLoaded).reservas;
    } else if (state is ReservaSaving) {
      return (state as ReservaSaving).reservas ?? [];
    } else if (state is ReservaActionSuccess) {
      return (state as ReservaActionSuccess).reservas;
    }
    return [];
  }
}
