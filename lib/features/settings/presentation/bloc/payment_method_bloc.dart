import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_method_repository.dart';

// ─── Events ──────────────────────────────────────────────

abstract class PaymentMethodEvent extends Equatable {
  const PaymentMethodEvent();
  @override
  List<Object?> get props => [];
}

class LoadPaymentMethods extends PaymentMethodEvent {}

class CreatePaymentMethod extends PaymentMethodEvent {
  final PaymentMethod method;
  const CreatePaymentMethod(this.method);
  @override
  List<Object?> get props => [method];
}

class UpdatePaymentMethod extends PaymentMethodEvent {
  final PaymentMethod method;
  const UpdatePaymentMethod(this.method);
  @override
  List<Object?> get props => [method];
}

class DeletePaymentMethod extends PaymentMethodEvent {
  final int id;
  const DeletePaymentMethod(this.id);
  @override
  List<Object?> get props => [id];
}

class TogglePaymentMethodActive extends PaymentMethodEvent {
  final int id;
  const TogglePaymentMethodActive(this.id);
  @override
  List<Object?> get props => [id];
}

// ─── States ──────────────────────────────────────────────

abstract class PaymentMethodState extends Equatable {
  const PaymentMethodState();
  @override
  List<Object?> get props => [];
}

class PaymentMethodInitial extends PaymentMethodState {}

class PaymentMethodLoading extends PaymentMethodState {}

class PaymentMethodsLoaded extends PaymentMethodState {
  final List<PaymentMethod> methods;
  const PaymentMethodsLoaded(this.methods);
  @override
  List<Object?> get props => [methods];
}

class PaymentMethodError extends PaymentMethodState {
  final String message;
  const PaymentMethodError(this.message);
  @override
  List<Object?> get props => [message];
}

class PaymentMethodSaving extends PaymentMethodState {
  final List<PaymentMethod>? methods;
  const PaymentMethodSaving([this.methods]);
  @override
  List<Object?> get props => [methods];
}

class PaymentMethodSaved extends PaymentMethodState {
  final List<PaymentMethod>? methods;
  const PaymentMethodSaved([this.methods]);
  @override
  List<Object?> get props => [methods];
}

// ─── BLoC ────────────────────────────────────────────────

class PaymentMethodBloc extends Bloc<PaymentMethodEvent, PaymentMethodState> {
  final PaymentMethodRepository _paymentMethodRepository;

  PaymentMethodBloc({required PaymentMethodRepository paymentMethodRepository})
    : _paymentMethodRepository = paymentMethodRepository,
      super(PaymentMethodInitial()) {
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    on<CreatePaymentMethod>(_onCreatePaymentMethod);
    on<UpdatePaymentMethod>(_onUpdatePaymentMethod);
    on<DeletePaymentMethod>(_onDeletePaymentMethod);
    on<TogglePaymentMethodActive>(_onTogglePaymentMethodActive);
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<PaymentMethodState> emit,
  ) async {
    emit(PaymentMethodLoading());
    try {
      final methods = await _paymentMethodRepository.getPaymentMethods();
      emit(PaymentMethodsLoaded(methods));
    } catch (e) {
      emit(PaymentMethodError(e.toString()));
    }
  }

  Future<void> _onCreatePaymentMethod(
    CreatePaymentMethod event,
    Emitter<PaymentMethodState> emit,
  ) async {
    final currentMethods =
        state is PaymentMethodsLoaded
            ? (state as PaymentMethodsLoaded).methods
            : null;
    emit(PaymentMethodSaving(currentMethods));
    try {
      await _paymentMethodRepository.createPaymentMethod(event.method);
      emit(PaymentMethodSaved(currentMethods));
      add(LoadPaymentMethods());
    } catch (e) {
      emit(PaymentMethodError(e.toString()));
    }
  }

  Future<void> _onUpdatePaymentMethod(
    UpdatePaymentMethod event,
    Emitter<PaymentMethodState> emit,
  ) async {
    final currentMethods =
        state is PaymentMethodsLoaded
            ? (state as PaymentMethodsLoaded).methods
            : null;
    emit(PaymentMethodSaving(currentMethods));
    try {
      await _paymentMethodRepository.updatePaymentMethod(event.method);
      emit(PaymentMethodSaved(currentMethods));
      add(LoadPaymentMethods());
    } catch (e) {
      emit(PaymentMethodError(e.toString()));
    }
  }

  Future<void> _onDeletePaymentMethod(
    DeletePaymentMethod event,
    Emitter<PaymentMethodState> emit,
  ) async {
    final currentMethods =
        state is PaymentMethodsLoaded
            ? (state as PaymentMethodsLoaded).methods
            : null;
    emit(PaymentMethodSaving(currentMethods));
    try {
      await _paymentMethodRepository.deletePaymentMethod(event.id);
      emit(PaymentMethodSaved(currentMethods));
      add(LoadPaymentMethods());
    } catch (e) {
      emit(PaymentMethodError(e.toString()));
    }
  }

  Future<void> _onTogglePaymentMethodActive(
    TogglePaymentMethodActive event,
    Emitter<PaymentMethodState> emit,
  ) async {
    final currentState = state;
    if (currentState is PaymentMethodsLoaded) {
      final currentMethods = currentState.methods;
      emit(PaymentMethodSaving(currentMethods));
      try {
        final method = currentMethods.firstWhere((m) => m.id == event.id);
        final updated = method.copyWith(isActive: !method.isActive);
        await _paymentMethodRepository.updatePaymentMethod(updated);
        emit(PaymentMethodSaved(currentMethods));
        add(LoadPaymentMethods());
      } catch (e) {
        emit(PaymentMethodError(e.toString()));
      }
    }
  }
}
