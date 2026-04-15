import '../entities/reserva.dart';
import '../entities/aerolinea.dart';
import '../../../../core/models/paged_result.dart';

abstract class ReservaRepository {
  Future<PagedResult<Reserva>> getReservas({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  });
  Future<Reserva> getReservaById(String id);
  Future<void> createReserva(Reserva reserva);
  Future<void> updateReserva(Reserva reserva);
  Future<List<Aerolinea>> getAerolineas();
}
