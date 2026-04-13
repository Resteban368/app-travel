import '../entities/reserva.dart';

abstract class ReservaRepository {
  Future<List<Reserva>> getReservas({DateTime? startDate, DateTime? endDate, String? status});
  Future<Reserva> getReservaById(String id);
  Future<void> createReserva(Reserva reserva);
  Future<void> updateReserva(Reserva reserva);
}
