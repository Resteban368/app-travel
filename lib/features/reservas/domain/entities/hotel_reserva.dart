import 'package:equatable/equatable.dart';
import 'package:agente_viajes/features/hoteles/domain/entities/hotel.dart';

class HotelReserva extends Equatable {
  final int? id;
  final int? hotelId;
  final Hotel? hotel;
  final String numeroReserva;
  final String fechaCheckin;  // 'yyyy-MM-dd'
  final String fechaCheckout; // 'yyyy-MM-dd'
  final double? valor;

  const HotelReserva({
    this.id,
    this.hotelId,
    this.hotel,
    required this.numeroReserva,
    required this.fechaCheckin,
    required this.fechaCheckout,
    this.valor,
  });

  @override
  List<Object?> get props =>
      [id, hotelId, hotel, numeroReserva, fechaCheckin, fechaCheckout, valor];
}
