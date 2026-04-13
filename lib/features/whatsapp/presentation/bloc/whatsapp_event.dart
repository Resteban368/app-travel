import 'package:equatable/equatable.dart';

abstract class WhatsAppEvent extends Equatable {
  const WhatsAppEvent();
  @override
  List<Object?> get props => [];
}

class SendMessage extends WhatsAppEvent {
  final String to;
  final String body;

  const SendMessage({required this.to, required this.body});

  @override
  List<Object?> get props => [to, body];
}

class ResetWhatsAppStatus extends WhatsAppEvent {}
