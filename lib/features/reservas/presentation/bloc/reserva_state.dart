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

  const ReservaLoaded(
    this.reservas, {
    this.page = 1,
    this.totalPages = 1,
    this.total = 0,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [reservas, page, totalPages, total, limit];
}

class ReservaSaving extends ReservaState {
  final List<Reserva>? reservas;
  const ReservaSaving({this.reservas});

  @override
  List<Object?> get props => [reservas];
}

class ReservaActionSuccess extends ReservaState {
  final List<Reserva> reservas;
  const ReservaActionSuccess(this.reservas);

  @override
  List<Object?> get props => [reservas];
}

class ReservaError extends ReservaState {
  final String message;
  const ReservaError(this.message);

  @override
  List<Object?> get props => [message];
}
