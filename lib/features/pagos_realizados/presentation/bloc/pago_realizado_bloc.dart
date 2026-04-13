import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/pago_realizado.dart';
import '../../domain/repositories/pago_realizado_repository.dart';

// ─── Events ──────────────────────────────────────────────

abstract class PagoRealizadoEvent extends Equatable {
  const PagoRealizadoEvent();
  @override
  List<Object?> get props => [];
}

class LoadPagos extends PagoRealizadoEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadPagos({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class CreatePago extends PagoRealizadoEvent {
  final PagoRealizado pago;
  const CreatePago(this.pago);
  @override
  List<Object?> get props => [pago];
}

class UpdatePago extends PagoRealizadoEvent {
  final PagoRealizado pago;
  const UpdatePago(this.pago);
  @override
  List<Object?> get props => [pago];
}

class DeletePago extends PagoRealizadoEvent {
  final int id;
  const DeletePago(this.id);
  @override
  List<Object?> get props => [id];
}

class TogglePagoValidation extends PagoRealizadoEvent {
  final PagoRealizado pago;
  const TogglePagoValidation(this.pago);
  @override
  List<Object?> get props => [pago];
}

// ─── States ──────────────────────────────────────────────

abstract class PagoRealizadoState extends Equatable {
  const PagoRealizadoState();
  @override
  List<Object?> get props => [];
}

class PagoRealizadoInitial extends PagoRealizadoState {}

class PagoRealizadoLoading extends PagoRealizadoState {}

class PagosRealizadosLoaded extends PagoRealizadoState {
  final List<PagoRealizado> pagos;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;

  const PagosRealizadosLoaded({
    required this.pagos,
    this.filterStartDate,
    this.filterEndDate,
  });

  @override
  List<Object?> get props => [pagos, filterStartDate, filterEndDate];
}

class PagoRealizadoSaving extends PagoRealizadoState {
  final List<PagoRealizado>? pagos;
  const PagoRealizadoSaving({this.pagos});
  @override
  List<Object?> get props => [pagos];
}

class PagoRealizadoSaved extends PagoRealizadoState {
  final List<PagoRealizado>? pagos;
  const PagoRealizadoSaved({this.pagos});
  @override
  List<Object?> get props => [pagos];
}

class PagoRealizadoError extends PagoRealizadoState {
  final String message;
  const PagoRealizadoError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────

class PagoRealizadoBloc extends Bloc<PagoRealizadoEvent, PagoRealizadoState> {
  final PagoRealizadoRepository _repository;

  PagoRealizadoBloc({required PagoRealizadoRepository repository})
    : _repository = repository,
      super(PagoRealizadoInitial()) {
    on<LoadPagos>(_onLoadPagos);
    on<CreatePago>(_onCreatePago);
    on<UpdatePago>(_onUpdatePago);
    on<DeletePago>(_onDeletePago);
    on<TogglePagoValidation>(_onTogglePagoValidation);
  }

  Future<void> _onLoadPagos(
    LoadPagos event,
    Emitter<PagoRealizadoState> emit,
  ) async {
    emit(PagoRealizadoLoading());
    try {
      final pagos = await _repository.getPagos(
        startDate: event.startDate,
        endDate: event.endDate,
      );
      emit(
        PagosRealizadosLoaded(
          pagos: pagos,
          filterStartDate: event.startDate,
          filterEndDate: event.endDate,
        ),
      );
    } catch (e) {
      emit(PagoRealizadoError(e.toString()));
    }
  }

  Future<void> _onCreatePago(
    CreatePago event,
    Emitter<PagoRealizadoState> emit,
  ) async {
    final currentState = state;
    final currentPagos =
        currentState is PagosRealizadosLoaded ? currentState.pagos : null;
    emit(PagoRealizadoSaving(pagos: currentPagos));
    try {
      await _repository.createPago(event.pago);
      final pagos = await _repository.getPagos();
      emit(PagoRealizadoSaved(pagos: pagos));
      emit(PagosRealizadosLoaded(pagos: pagos));
    } catch (e) {
      emit(PagoRealizadoError(e.toString()));
    }
  }

  Future<void> _onUpdatePago(
    UpdatePago event,
    Emitter<PagoRealizadoState> emit,
  ) async {
    final currentState = state;
    final currentPagos =
        currentState is PagosRealizadosLoaded ? currentState.pagos : null;
    emit(PagoRealizadoSaving(pagos: currentPagos));
    try {
      await _repository.updatePago(event.pago);
      final pagos = await _repository.getPagos();
      emit(PagoRealizadoSaved(pagos: pagos));
      emit(PagosRealizadosLoaded(pagos: pagos));
    } catch (e) {
      emit(PagoRealizadoError(e.toString()));
    }
  }

  Future<void> _onDeletePago(
    DeletePago event,
    Emitter<PagoRealizadoState> emit,
  ) async {
    final currentState = state;
    final currentPagos =
        currentState is PagosRealizadosLoaded ? currentState.pagos : null;
    emit(PagoRealizadoSaving(pagos: currentPagos));
    try {
      await _repository.deletePago(event.id);
      final pagos = await _repository.getPagos();
      emit(PagoRealizadoSaved(pagos: pagos));
      emit(PagosRealizadosLoaded(pagos: pagos));
    } catch (e) {
      emit(PagoRealizadoError(e.toString()));
    }
  }

  Future<void> _onTogglePagoValidation(
    TogglePagoValidation event,
    Emitter<PagoRealizadoState> emit,
  ) async {
    final currentState = state;
    final currentPagos =
        currentState is PagosRealizadosLoaded ? currentState.pagos : null;
    if (currentPagos != null) {
      emit(PagoRealizadoSaving(pagos: currentPagos));
      try {
        final updated = event.pago.copyWith(isValidated: !event.pago.isValidated);
        await _repository.updatePago(updated);
        final pagos = await _repository.getPagos();
        emit(PagoRealizadoSaved(pagos: pagos));
        emit(PagosRealizadosLoaded(pagos: pagos));
      } catch (e) {
        emit(PagoRealizadoError(e.toString()));
      }
    }
  }
}
