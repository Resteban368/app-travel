import 'package:equatable/equatable.dart';
import 'package:agente_viajes/features/hoteles/domain/entities/hotel.dart';

class HabitacionReserva extends Equatable {
  final String tipoCama;
  final int cantidad;
  final double precioUnitario;

  const HabitacionReserva({
    required this.tipoCama,
    required this.cantidad,
    required this.precioUnitario,
  });

  @override
  List<Object?> get props => [tipoCama, cantidad, precioUnitario];
}

class HotelReserva extends Equatable {
  final int? id;
  final int? hotelId;
  final Hotel? hotel;
  final String numeroReserva;
  final String fechaCheckin; // 'yyyy-MM-dd'
  final String fechaCheckout; // 'yyyy-MM-dd'
  final double? valor;
  final List<HabitacionReserva> habitaciones;

  const HotelReserva({
    this.id,
    this.hotelId,
    this.hotel,
    required this.numeroReserva,
    required this.fechaCheckin,
    required this.fechaCheckout,
    this.valor,
    this.habitaciones = const [],
  });

  @override
  List<Object?> get props => [
    id,
    hotelId,
    hotel,
    numeroReserva,
    fechaCheckin,
    fechaCheckout,
    valor,
    habitaciones,
  ];
}
