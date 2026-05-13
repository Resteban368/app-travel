import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/saldo_pendiente.dart';
import '../../domain/repositories/saldo_pendiente_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class SaldoPendienteDetailEvent extends Equatable {
  const SaldoPendienteDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadReservasPorTour extends SaldoPendienteDetailEvent {
  final int tourId;
  const LoadReservasPorTour(this.tourId);
  @override
  List<Object?> get props => [tourId];
}

class EnviarRecordatorioDetail extends SaldoPendienteDetailEvent {
  final int reservaId;
  final int? conversationId;

  const EnviarRecordatorioDetail({required this.reservaId, this.conversationId});

  @override
  List<Object?> get props => [reservaId, conversationId];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class SaldoPendienteDetailState extends Equatable {
  const SaldoPendienteDetailState();
  @override
  List<Object?> get props => [];
}

class SaldoPendienteDetailInitial extends SaldoPendienteDetailState {}

class SaldoPendienteDetailLoading extends SaldoPendienteDetailState {}

class SaldoPendienteDetailLoaded extends SaldoPendienteDetailState {
  final List<SaldoPendiente> reservas;
  const SaldoPendienteDetailLoaded(this.reservas);
  @override
  List<Object?> get props => [reservas];
}

class SaldoPendienteDetailError extends SaldoPendienteDetailState {
  final String message;
  const SaldoPendienteDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class RecordatorioEnviandoDetail extends SaldoPendienteDetailState {
  final List<SaldoPendiente> previousReservas;
  final int reservaId;
  const RecordatorioEnviandoDetail({
    required this.previousReservas,
    required this.reservaId,
  });
  @override
  List<Object?> get props => [previousReservas, reservaId];
}

class RecordatorioEnviadoDetail extends SaldoPendienteDetailState {
  final List<SaldoPendiente> previousReservas;
  final RecordatorioResult result;
  const RecordatorioEnviadoDetail({
    required this.previousReservas,
    required this.result,
  });
  @override
  List<Object?> get props => [previousReservas, result];
}

class RecordatorioFallidoDetail extends SaldoPendienteDetailState {
  final List<SaldoPendiente> previousReservas;
  final String message;
  const RecordatorioFallidoDetail({
    required this.previousReservas,
    required this.message,
  });
  @override
  List<Object?> get props => [previousReservas, message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class SaldoPendienteDetailBloc
    extends Bloc<SaldoPendienteDetailEvent, SaldoPendienteDetailState> {
  final SaldoPendienteRepository _repository;

  SaldoPendienteDetailBloc({required SaldoPendienteRepository repository})
      : _repository = repository,
        super(SaldoPendienteDetailInitial()) {
    on<LoadReservasPorTour>(_onLoadReservas);
    on<EnviarRecordatorioDetail>(_onEnviarRecordatorio);
  }

  Future<void> _onLoadReservas(
    LoadReservasPorTour event,
    Emitter<SaldoPendienteDetailState> emit,
  ) async {
    emit(SaldoPendienteDetailLoading());
    try {
      final reservas = await _repository.getReservasPorTour(event.tourId);
      emit(SaldoPendienteDetailLoaded(reservas));
    } catch (e) {
      emit(SaldoPendienteDetailError(e.toString()));
    }
  }

  Future<void> _onEnviarRecordatorio(
    EnviarRecordatorioDetail event,
    Emitter<SaldoPendienteDetailState> emit,
  ) async {
    final current = state;
    List<SaldoPendiente>? reservas;
    if (current is SaldoPendienteDetailLoaded) reservas = current.reservas;
    if (current is RecordatorioEnviandoDetail) reservas = current.previousReservas;
    if (current is RecordatorioEnviadoDetail) reservas = current.previousReservas;
    if (current is RecordatorioFallidoDetail) reservas = current.previousReservas;
    
    if (reservas == null) return;

    emit(RecordatorioEnviandoDetail(
      previousReservas: reservas,
      reservaId: event.reservaId,
    ));
    try {
      final result = await _repository.enviarRecordatorio(
        event.reservaId,
        conversationId: event.conversationId,
      );
      emit(RecordatorioEnviadoDetail(previousReservas: reservas, result: result));
      emit(SaldoPendienteDetailLoaded(reservas));
    } catch (e) {
      emit(RecordatorioFallidoDetail(previousReservas: reservas, message: e.toString()));
      emit(SaldoPendienteDetailLoaded(reservas));
    }
  }
}
