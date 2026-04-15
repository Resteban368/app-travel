import '../entities/pago_realizado.dart';
import '../../../../core/models/paged_result.dart';

abstract class PagoRealizadoRepository {
  /// Fetches a paginated page of payments, optionally filtered by date range.
  Future<PagedResult<PagoRealizado>> getPagos({
    int page = 1,
    int limit = 20,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Fetches all payments linked to a specific reservation.
  Future<List<PagoRealizado>> getPagosByReserva(int reservaId);

  /// Fetches a specific payment by its unique ID.
  Future<PagoRealizado> getPagoById(int id);

  /// Records a new payment in the system.
  Future<void> createPago(PagoRealizado pago);

  /// Updates details of an existing payment (e.g., marks it as validated).
  Future<void> updatePago(PagoRealizado pago);

  /// Removes a payment record from the system.
  Future<void> deletePago(int id);
}
