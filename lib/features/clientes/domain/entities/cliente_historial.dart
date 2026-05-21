import 'package:equatable/equatable.dart';
import 'package:agente_viajes/features/clientes/domain/entities/cliente.dart';
import 'package:agente_viajes/features/reservas/domain/entities/reserva.dart';
import 'package:agente_viajes/features/pagos_realizados/domain/entities/pago_realizado.dart';

class ClienteHistorial extends Equatable {
  final Cliente cliente;
  final int totalViajes;
  final List<Reserva> reservas;
  final List<PagoRealizado> pagos;
  final int totalPagos;
  final double totalPagado;

  const ClienteHistorial({
    required this.cliente,
    required this.totalViajes,
    required this.reservas,
    this.pagos = const [],
    this.totalPagos = 0,
    this.totalPagado = 0,
  });

  @override
  List<Object?> get props => [cliente, totalViajes, reservas, pagos, totalPagos, totalPagado];
}
