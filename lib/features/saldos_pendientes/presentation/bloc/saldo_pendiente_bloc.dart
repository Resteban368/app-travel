import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/saldo_pendiente.dart';
import '../../domain/repositories/saldo_pendiente_repository.dart';

export '../../domain/repositories/saldo_pendiente_repository.dart'
    show RecordatorioResult;

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class SaldoPendienteEvent extends Equatable {
  const SaldoPendienteEvent();
  @override
  List<Object?> get props => [];
}

class LoadSaldosPendientes extends SaldoPendienteEvent {
  final String? tourId;
  final String? tourNombre;
  final String? responsable;
  final String? idReserva;
  final bool? sinRecordatorioReciente;

  const LoadSaldosPendientes({
    this.tourId,
    this.tourNombre,
    this.responsable,
    this.idReserva,
    this.sinRecordatorioReciente,
  });

  @override
  List<Object?> get props =>
      [tourId, tourNombre, responsable, idReserva, sinRecordatorioReciente];
}

class LoadMoreSaldosPendientes extends SaldoPendienteEvent {
  const LoadMoreSaldosPendientes();
}

class EnviarRecordatorio extends SaldoPendienteEvent {
  final int reservaId;
  final int? conversationId;

  const EnviarRecordatorio({required this.reservaId, this.conversationId});

  @override
  List<Object?> get props => [reservaId, conversationId];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class SaldoPendienteState extends Equatable {
  const SaldoPendienteState();
  @override
  List<Object?> get props => [];
}

class SaldoPendienteInitial extends SaldoPendienteState {}

class SaldoPendienteLoading extends SaldoPendienteState {}

class SaldoPendienteLoaded extends SaldoPendienteState {
  final List<TourConSaldo> tours;
  final int totalTours;
  final int currentPage;
  final int limit;
  final bool hasMore;
  final String? filterTourId;
  final String? filterTourNombre;
  final String? filterResponsable;
  final String? filterIdReserva;
  final bool sinRecordatorioReciente;

  const SaldoPendienteLoaded({
    required this.tours,
    required this.totalTours,
    required this.currentPage,
    required this.limit,
    required this.hasMore,
    this.filterTourId,
    this.filterTourNombre,
    this.filterResponsable,
    this.filterIdReserva,
    this.sinRecordatorioReciente = false,
  });

  int get totalPages => (totalTours / limit).ceil();

  @override
  List<Object?> get props => [
        tours,
        totalTours,
        currentPage,
        hasMore,
        filterTourId,
        filterTourNombre,
        filterResponsable,
        filterIdReserva,
        sinRecordatorioReciente,
      ];
}

class SaldoPendienteLoadingMore extends SaldoPendienteState {
  final SaldoPendienteLoaded previous;
  const SaldoPendienteLoadingMore(this.previous);
  @override
  List<Object?> get props => [previous];
}

class SaldoPendienteError extends SaldoPendienteState {
  final String message;
  const SaldoPendienteError(this.message);
  @override
  List<Object?> get props => [message];
}

/// Emitted while the reminder API call is in flight.
/// Preserves [previous] so the list stays visible.
class RecordatorioEnviando extends SaldoPendienteState {
  final SaldoPendienteLoaded previous;
  final int reservaId;
  const RecordatorioEnviando({required this.previous, required this.reservaId});
  @override
  List<Object?> get props => [previous, reservaId];
}

/// Emitted after a successful reminder send.
class RecordatorioEnviado extends SaldoPendienteState {
  final SaldoPendienteLoaded previous;
  final RecordatorioResult result;
  const RecordatorioEnviado({required this.previous, required this.result});
  @override
  List<Object?> get props => [previous, result];
}

/// Emitted when the reminder API call fails.
class RecordatorioFallido extends SaldoPendienteState {
  final SaldoPendienteLoaded previous;
  final String message;
  const RecordatorioFallido({required this.previous, required this.message});
  @override
  List<Object?> get props => [previous, message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class SaldoPendienteBloc
    extends Bloc<SaldoPendienteEvent, SaldoPendienteState> {
  final SaldoPendienteRepository _repository;
  static const int _limit = 20; // tours per page

  SaldoPendienteBloc({required SaldoPendienteRepository repository})
      : _repository = repository,
        super(SaldoPendienteInitial()) {
    on<LoadSaldosPendientes>(_onLoad);
    on<LoadMoreSaldosPendientes>(_onLoadMore);
    on<EnviarRecordatorio>(_onEnviarRecordatorio);
  }

  Future<void> _onLoad(
    LoadSaldosPendientes event,
    Emitter<SaldoPendienteState> emit,
  ) async {
    emit(SaldoPendienteLoading());
    try {
      final result = await _repository.getSaldosPendientes(
        page: 1,
        limit: _limit,
        tourId: event.tourId,
        tourNombre: event.tourNombre,
        responsable: event.responsable,
        idReserva: event.idReserva,
        sinRecordatorioReciente: event.sinRecordatorioReciente ?? false,
      );
      final hasMore = result.tours.length < result.totalTours;
      emit(SaldoPendienteLoaded(
        tours: result.tours,
        totalTours: result.totalTours,
        currentPage: 1,
        limit: result.limit,
        hasMore: hasMore,
        filterTourId: event.tourId,
        filterTourNombre: event.tourNombre,
        filterResponsable: event.responsable,
        filterIdReserva: event.idReserva,
        sinRecordatorioReciente: event.sinRecordatorioReciente ?? false,
      ));
    } catch (e) {
      emit(SaldoPendienteError(e.toString()));
    }
  }

  Future<void> _onLoadMore(
    LoadMoreSaldosPendientes event,
    Emitter<SaldoPendienteState> emit,
  ) async {
    final current = state;
    SaldoPendienteLoaded? loaded;
    if (current is SaldoPendienteLoaded) loaded = current;
    if (current is SaldoPendienteLoadingMore) loaded = current.previous;
    if (loaded == null || !loaded.hasMore) return;

    emit(SaldoPendienteLoadingMore(loaded));
    try {
      final nextPage = loaded.currentPage + 1;
      final result = await _repository.getSaldosPendientes(
        page: nextPage,
        limit: _limit,
        tourId: loaded.filterTourId,
        tourNombre: loaded.filterTourNombre,
        responsable: loaded.filterResponsable,
        idReserva: loaded.filterIdReserva,
        sinRecordatorioReciente: loaded.sinRecordatorioReciente,
      );
      final allTours = [...loaded.tours, ...result.tours];
      final hasMore = allTours.length < result.totalTours;
      emit(SaldoPendienteLoaded(
        tours: allTours,
        totalTours: result.totalTours,
        currentPage: nextPage,
        limit: result.limit,
        hasMore: hasMore,
        filterTourId: loaded.filterTourId,
        filterTourNombre: loaded.filterTourNombre,
        filterResponsable: loaded.filterResponsable,
        filterIdReserva: loaded.filterIdReserva,
        sinRecordatorioReciente: loaded.sinRecordatorioReciente,
      ));
    } catch (e) {
      emit(SaldoPendienteError(e.toString()));
    }
  }

  Future<void> _onEnviarRecordatorio(
    EnviarRecordatorio event,
    Emitter<SaldoPendienteState> emit,
  ) async {
    final current = state;
    SaldoPendienteLoaded? loaded;
    if (current is SaldoPendienteLoaded) loaded = current;
    if (current is RecordatorioEnviando) loaded = current.previous;
    if (current is RecordatorioEnviado) loaded = current.previous;
    if (current is RecordatorioFallido) loaded = current.previous;
    if (loaded == null) return;

    emit(RecordatorioEnviando(previous: loaded, reservaId: event.reservaId));
    try {
      final result = await _repository.enviarRecordatorio(
        event.reservaId,
        conversationId: event.conversationId,
      );
      emit(RecordatorioEnviado(previous: loaded, result: result));
      emit(loaded); // restore list view
    } catch (e) {
      emit(RecordatorioFallido(previous: loaded, message: e.toString()));
      emit(loaded); // restore list view
    }
  }

}
