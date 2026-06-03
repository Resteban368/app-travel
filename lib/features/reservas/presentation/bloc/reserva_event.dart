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
  final String? search;

  const LoadReservas({
    this.page = 1,
    this.limit = 20,
    this.startDate,
    this.endDate,
    this.status,
    this.search,
  });

  @override
  List<Object?> get props => [page, limit, startDate, endDate, status, search];
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
class LoadReservaById extends ReservaEvent {
  final String id;
  const LoadReservaById(this.id);

  @override
  List<Object?> get props => [id];
}

class DeleteReserva extends ReservaEvent {
  final int id;
  const DeleteReserva(this.id);

  @override
  List<Object?> get props => [id];
}

class CancelReserva extends ReservaEvent {
  final String id;
  const CancelReserva(this.id);

  @override
  List<Object?> get props => [id];
}
