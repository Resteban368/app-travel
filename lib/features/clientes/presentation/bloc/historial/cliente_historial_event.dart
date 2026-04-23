import 'package:equatable/equatable.dart';

abstract class ClienteHistorialEvent extends Equatable {
  const ClienteHistorialEvent();

  @override
  List<Object?> get props => [];
}

class LoadClienteHistorial extends ClienteHistorialEvent {
  final int clienteId;
  const LoadClienteHistorial(this.clienteId);

  @override
  List<Object?> get props => [clienteId];
}
