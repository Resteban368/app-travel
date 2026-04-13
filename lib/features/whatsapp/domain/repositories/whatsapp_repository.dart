abstract class WhatsAppRepository {
  Future<void> sendMessage({required String to, required String body});
}
