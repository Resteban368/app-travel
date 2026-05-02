import 'package:equatable/equatable.dart';

abstract class WhatsAppEvent extends Equatable {
  const WhatsAppEvent();
  @override
  List<Object?> get props => [];
}

class SendMessage extends WhatsAppEvent {
  final int conversationId;
  final String content;

  const SendMessage({required this.conversationId, required this.content});

  @override
  List<Object?> get props => [conversationId, content];
}

class ResetWhatsAppStatus extends WhatsAppEvent {}
