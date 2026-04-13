import '../entities/payment_method.dart';

/// Abstract contract for PaymentMethod CRUD operations.
abstract class PaymentMethodRepository {
  Future<List<PaymentMethod>> getPaymentMethods();
  Future<void> createPaymentMethod(PaymentMethod method);
  Future<void> updatePaymentMethod(PaymentMethod method);
  Future<void> deletePaymentMethod(int id);
}
