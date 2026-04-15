import 'package:equatable/equatable.dart';
import '../../domain/entities/cliente.dart';

abstract class ClienteEvent extends Equatable {
  const ClienteEvent();

  @override
  List<Object?> get props => [];
}

class LoadClientes extends ClienteEvent {}

class CreateCliente extends ClienteEvent {
  final Cliente cliente;
  const CreateCliente(this.cliente);

  @override
  List<Object?> get props => [cliente];
}

class UpdateCliente extends ClienteEvent {
  final Cliente cliente;
  const UpdateCliente(this.cliente);

  @override
  List<Object?> get props => [cliente];
}

class DeleteCliente extends ClienteEvent {
  final int id;
  const DeleteCliente(this.id);

  @override
  List<Object?> get props => [id];
}
