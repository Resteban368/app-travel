import 'package:equatable/equatable.dart';
import '../../domain/entities/reserva.dart';

abstract class ReservaState extends Equatable {
  const ReservaState();

  @override
  List<Object?> get props => [];
}

class ReservaInitial extends ReservaState {}

class ReservaLoading extends ReservaState {}

class ReservaLoaded extends ReservaState {
  final List<Reserva> reservas;
  final int page;
  final int totalPages;
  final int total;
  final int limit;
  final bool hasReachedMax;
  final String? filterSearch;
  final String? filterStatus;
  final DateTime? filterStartDate;
  final DateTime? filterEndDate;

  const ReservaLoaded(
    this.reservas, {
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.limit = 20,
    this.hasReachedMax = false,
    this.filterSearch,
    this.filterStatus,
    this.filterStartDate,
    this.filterEndDate,
  });

  @override
  List<Object?> get props => [
        reservas,
        page,
        totalPages,
        total,
        limit,
        hasReachedMax,
        filterSearch,
        filterStatus,
        filterStartDate,
        filterEndDate,
      ];
}

class ReservaSaving extends ReservaState {
  final List<Reserva>? reservas;
  const ReservaSaving({this.reservas});

  @override
  List<Object?> get props => [reservas];
}

class ReservaActionSuccess extends ReservaState {
  final List<Reserva> reservas;
  final Reserva? createdReserva;
  const ReservaActionSuccess(this.reservas, {this.createdReserva});

  @override
  List<Object?> get props => [reservas, createdReserva];
}

class ReservaError extends ReservaState {
  final String message;
  const ReservaError(this.message);

  @override
  List<Object?> get props => [message];
}
