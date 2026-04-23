import 'package:equatable/equatable.dart';
import '../../domain/entities/hotel.dart';

abstract class HotelState extends Equatable {
  const HotelState();

  @override
  List<Object?> get props => [];
}

class HotelInitial extends HotelState {}

class HotelLoading extends HotelState {}

class HotelSaving extends HotelState {
  final List<Hotel>? hoteles;
  const HotelSaving([this.hoteles]);

  @override
  List<Object?> get props => [hoteles];
}

class HotelLoaded extends HotelState {
  final List<Hotel> hoteles;
  const HotelLoaded(this.hoteles);

  @override
  List<Object?> get props => [hoteles];
}

class HotelSaved extends HotelState {
  final List<Hotel>? hoteles;
  const HotelSaved([this.hoteles]);

  @override
  List<Object?> get props => [hoteles];
}

class HotelError extends HotelState {
  final String message;
  const HotelError(this.message);

  @override
  List<Object?> get props => [message];
}
