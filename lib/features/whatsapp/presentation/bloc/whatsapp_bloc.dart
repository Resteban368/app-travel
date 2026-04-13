import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/send_whatsapp_message.dart';
import 'whatsapp_event.dart';
import 'whatsapp_state.dart';

class WhatsAppBloc extends Bloc<WhatsAppEvent, WhatsAppState> {
  final SendWhatsAppMessage sendWhatsAppMessage;

  WhatsAppBloc({required this.sendWhatsAppMessage}) : super(WhatsAppInitial()) {
    on<SendMessage>(_onSendMessage);
    on<ResetWhatsAppStatus>(_onResetStatus);
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<WhatsAppState> emit,
  ) async {
    emit(WhatsAppSending());
    try {
      await sendWhatsAppMessage(to: event.to, body: event.body);
      emit(WhatsAppSent());
    } catch (e) {
      emit(WhatsAppError(e.toString()));
    }
  }

  void _onResetStatus(ResetWhatsAppStatus event, Emitter<WhatsAppState> emit) {
    emit(WhatsAppInitial());
  }
}
