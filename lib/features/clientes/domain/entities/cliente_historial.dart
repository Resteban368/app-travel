import 'package:equatable/equatable.dart';
import 'package:agente_viajes/features/clientes/domain/entities/cliente.dart';
import 'package:agente_viajes/features/reservas/domain/entities/reserva.dart';

class ClienteHistorial extends Equatable {
  final Cliente cliente;
  final int totalViajes;
  final List<Reserva> reservas;

  const ClienteHistorial({
    required this.cliente,
    required this.totalViajes,
    required this.reservas,
  });

  @override
  List<Object?> get props => [cliente, totalViajes, reservas];
}
