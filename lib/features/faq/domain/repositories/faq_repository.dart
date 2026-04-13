import '../entities/faq.dart';

abstract class FaqRepository {
  Future<List<Faq>> getFaqs();
  Future<void> createFaq(Faq faq);
  Future<void> updateFaq(Faq faq);
  Future<void> deleteFaq(int id);
}
