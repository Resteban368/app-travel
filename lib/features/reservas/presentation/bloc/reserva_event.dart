import 'package:equatable/equatable.dart';
import '../../domain/entities/reserva.dart';

abstract class ReservaEvent extends Equatable {
  const ReservaEvent();

  @override
  List<Object?> get props => [];
}

class LoadReservas extends ReservaEvent {
  final int page;
  final int limit;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? status;

  const LoadReservas({
    this.page = 1,
    this.limit = 20,
    this.startDate,
    this.endDate,
    this.status,
  });

  @override
  List<Object?> get props => [page, limit, startDate, endDate, status];
}

class CreateReserva extends ReservaEvent {
  final Reserva reserva;
  const CreateReserva(this.reserva);

  @override
  List<Object?> get props => [reserva];
}

class UpdateReserva extends ReservaEvent {
  final Reserva reserva;
  const UpdateReserva(this.reserva);

  @override
  List<Object?> get props => [reserva];
}
