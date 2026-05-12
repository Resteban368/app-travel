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
  final String? responsable;
  final String? idReserva;
  final bool? sinRecordatorioReciente;

  const LoadSaldosPendientes({
    this.tourId,
    this.responsable,
    this.idReserva,
    this.sinRecordatorioReciente,
  });

  @override
  List<Object?> get props =>
      [tourId, responsable, idReserva, sinRecordatorioReciente];
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
  final List<SaldoPendiente> items;
  final int total;
  final int currentPage;
  final bool hasMore;
  // Agrupados por nombre de tour para la UI
  final Map<String, List<SaldoPendiente>> byTour;
  final String? filterTourId;
  final String? filterResponsable;
  final String? filterIdReserva;
  final bool sinRecordatorioReciente;

  const SaldoPendienteLoaded({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.hasMore,
    required this.byTour,
    this.filterTourId,
    this.filterResponsable,
    this.filterIdReserva,
    this.sinRecordatorioReciente = false,
  });

  @override
  List<Object?> get props => [
        items,
        total,
        currentPage,
        hasMore,
        filterTourId,
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
  static const int _limit = 20;

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
        responsable: event.responsable,
        idReserva: event.idReserva,
        sinRecordatorioReciente: event.sinRecordatorioReciente ?? false,
      );
      final hasMore = result.items.length >= _limit &&
          result.items.length < result.total;
      emit(SaldoPendienteLoaded(
        items: result.items,
        total: result.total,
        currentPage: 1,
        hasMore: hasMore,
        byTour: _groupByTour(result.items),
        filterTourId: event.tourId,
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
        responsable: loaded.filterResponsable,
        idReserva: loaded.filterIdReserva,
        sinRecordatorioReciente: loaded.sinRecordatorioReciente,
      );
      final allItems = [...loaded.items, ...result.items];
      final hasMore =
          allItems.length < result.total && result.items.isNotEmpty;
      emit(SaldoPendienteLoaded(
        items: allItems,
        total: result.total,
        currentPage: nextPage,
        hasMore: hasMore,
        byTour: _groupByTour(allItems),
        filterTourId: loaded.filterTourId,
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

  Map<String, List<SaldoPendiente>> _groupByTour(List<SaldoPendiente> items) {
    final map = <String, List<SaldoPendiente>>{};
    for (final item in items) {
      final key = item.tour.nombre.isNotEmpty
          ? item.tour.nombre
          : 'Sin tour';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}
