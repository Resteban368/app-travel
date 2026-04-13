import '../repositories/whatsapp_repository.dart';

class SendWhatsAppMessage {
  final WhatsAppRepository repository;

  SendWhatsAppMessage(this.repository);

  Future<void> call({required String to, required String body}) async {
    return await repository.sendMessage(to: to, body: body);
  }
}
