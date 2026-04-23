import 'package:equatable/equatable.dart';
import '../../../domain/entities/cliente_historial.dart';

abstract class ClienteHistorialState extends Equatable {
  const ClienteHistorialState();

  @override
  List<Object?> get props => [];
}

class ClienteHistorialInitial extends ClienteHistorialState {}

class ClienteHistorialLoading extends ClienteHistorialState {}

class ClienteHistorialLoaded extends ClienteHistorialState {
  final ClienteHistorial historial;
  const ClienteHistorialLoaded(this.historial);

  @override
  List<Object?> get props => [historial];
}

class ClienteHistorialError extends ClienteHistorialState {
  final String message;
  const ClienteHistorialError(this.message);

  @override
  List<Object?> get props => [message];
}
