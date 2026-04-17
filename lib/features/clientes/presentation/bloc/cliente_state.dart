import 'package:equatable/equatable.dart';
import '../../domain/entities/cliente.dart';

abstract class ClienteState extends Equatable {
  const ClienteState();

  @override
  List<Object?> get props => [];
}

class ClienteInitial extends ClienteState {}

class ClienteLoading extends ClienteState {}

class ClienteLoaded extends ClienteState {
  final List<Cliente> clientes;
  const ClienteLoaded(this.clientes);

  @override
  List<Object?> get props => [clientes];
}

class ClienteSaving extends ClienteState {
  final List<Cliente>? clientes;
  const ClienteSaving({this.clientes});

  @override
  List<Object?> get props => [clientes];
}

class ClienteActionSuccess extends ClienteState {
  final List<Cliente> clientes;
  final String? message;
  const ClienteActionSuccess(this.clientes, {this.message});

  @override
  List<Object?> get props => [clientes, message];
}

class ClienteError extends ClienteState {
  final String message;
  const ClienteError(this.message);

  @override
  List<Object?> get props => [message];
}
