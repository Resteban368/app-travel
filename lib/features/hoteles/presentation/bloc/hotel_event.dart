import 'package:equatable/equatable.dart';
import '../../domain/entities/hotel.dart';

abstract class HotelEvent extends Equatable {
  const HotelEvent();

  @override
  List<Object?> get props => [];
}

class LoadHoteles extends HotelEvent {
  const LoadHoteles();
}

class CreateHotel extends HotelEvent {
  final Hotel hotel;
  const CreateHotel(this.hotel);

  @override
  List<Object?> get props => [hotel];
}

class UpdateHotel extends HotelEvent {
  final Hotel hotel;
  const UpdateHotel(this.hotel);

  @override
  List<Object?> get props => [hotel];
}

class DeleteHotel extends HotelEvent {
  final int id;
  const DeleteHotel(this.id);

  @override
  List<Object?> get props => [id];
}
