import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/hotel.dart';
import '../../domain/repositories/hotel_repository.dart';
import 'hotel_event.dart';
import 'hotel_state.dart';

class HotelBloc extends Bloc<HotelEvent, HotelState> {
  final HotelRepository repository;

  HotelBloc({required this.repository}) : super(HotelInitial()) {
    on<LoadHoteles>(_onLoad);
    on<CreateHotel>(_onCreate);
    on<UpdateHotel>(_onUpdate);
    on<DeleteHotel>(_onDelete);
  }

  Future<void> _onLoad(LoadHoteles event, Emitter<HotelState> emit) async {
    emit(HotelLoading());
    try {
      final hoteles = await repository.getHoteles();
      emit(HotelLoaded(hoteles));
    } catch (e) {
      emit(HotelError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateHotel event, Emitter<HotelState> emit) async {
    final current = state is HotelLoaded ? (state as HotelLoaded).hoteles : null;
    emit(HotelSaving(current));
    try {
      await repository.createHotel(event.hotel);
      final hoteles = await repository.getHoteles();
      emit(HotelSaved(hoteles));
      emit(HotelLoaded(hoteles));
    } catch (e) {
      emit(HotelError(e.toString()));
    }
  }

  Future<void> _onUpdate(UpdateHotel event, Emitter<HotelState> emit) async {
    final currentState = state;
    if (currentState is HotelLoaded) {
      final list = List<Hotel>.from(currentState.hoteles);
      emit(HotelSaving(list));
      try {
        await repository.updateHotel(event.hotel);
        final idx = list.indexWhere((h) => h.id == event.hotel.id);
        if (idx != -1) list[idx] = event.hotel;
        emit(HotelSaved(list));
        emit(HotelLoaded(list));
      } catch (e) {
        emit(HotelError(e.toString()));
      }
    }
  }

  Future<void> _onDelete(DeleteHotel event, Emitter<HotelState> emit) async {
    final currentState = state;
    if (currentState is HotelLoaded) {
      final list = List<Hotel>.from(currentState.hoteles);
      try {
        await repository.deleteHotel(event.id);
        list.removeWhere((h) => h.id == event.id);
        emit(HotelLoaded(list));
      } catch (e) {
        emit(HotelError(e.toString()));
      }
    }
  }
}
