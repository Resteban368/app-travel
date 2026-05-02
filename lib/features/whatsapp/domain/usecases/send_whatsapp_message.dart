import '../repositories/whatsapp_repository.dart';

class SendWhatsAppMessage {
  final WhatsAppRepository repository;

  SendWhatsAppMessage(this.repository);

  Future<void> call({required int conversationId, required String content}) async {
    return await repository.sendMessage(conversationId: conversationId, content: content);
  }
}
