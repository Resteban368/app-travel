import 'package:equatable/equatable.dart';

abstract class WhatsAppState extends Equatable {
  const WhatsAppState();
  @override
  List<Object?> get props => [];
}

class WhatsAppInitial extends WhatsAppState {}

class WhatsAppSending extends WhatsAppState {}

class WhatsAppSent extends WhatsAppState {}

class WhatsAppError extends WhatsAppState {
  final String message;
  const WhatsAppError(this.message);
  @override
  List<Object?> get props => [message];
}
