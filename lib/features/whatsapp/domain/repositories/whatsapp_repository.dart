abstract class WhatsAppRepository {
  Future<void> sendMessage({required int conversationId, required String content});
}
