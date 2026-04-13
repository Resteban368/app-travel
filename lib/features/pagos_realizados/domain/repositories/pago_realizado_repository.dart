import '../entities/pago_realizado.dart';

abstract class PagoRealizadoRepository {
  /// Fetches all payments, optionally filtered by the given date range.
  Future<List<PagoRealizado>> getPagos({DateTime? startDate, DateTime? endDate});

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
