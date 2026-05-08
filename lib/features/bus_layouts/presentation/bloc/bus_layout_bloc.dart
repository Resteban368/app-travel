import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/bus_layout.dart';
import '../../domain/repositories/bus_layout_repository.dart';
import 'bus_layout_event.dart';
import 'bus_layout_state.dart';

class BusLayoutBloc extends Bloc<BusLayoutEvent, BusLayoutState> {
  final BusLayoutRepository repository;

  BusLayoutBloc({required this.repository}) : super(BusLayoutInitial()) {
    on<LoadBusLayouts>(_onLoad);
    on<LoadBusLayout>(_onLoadOne);
    on<CreateBusLayout>(_onCreate);
    on<UpdateBusLayout>(_onUpdate);
    on<DeleteBusLayout>(_onDelete);
  }

  Future<void> _onLoad(
    LoadBusLayouts event,
    Emitter<BusLayoutState> emit,
  ) async {
    emit(BusLayoutLoading());
    try {
      final layouts = await repository.getBusLayouts();
      emit(BusLayoutLoaded(layouts));
    } catch (e) {
      emit(BusLayoutError(e.toString()));
    }
  }

  Future<void> _onLoadOne(
    LoadBusLayout event,
    Emitter<BusLayoutState> emit,
  ) async {
    emit(BusLayoutLoading());
    try {
      final layout = await repository.getBusLayout(event.id);
      emit(BusLayoutDetailLoaded(layout));
    } catch (e) {
      emit(BusLayoutError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateBusLayout event,
    Emitter<BusLayoutState> emit,
  ) async {
    final current = state is BusLayoutLoaded
        ? (state as BusLayoutLoaded).layouts
        : null;
    emit(BusLayoutSaving(current));
    try {
      await repository.createBusLayout(event.layout);
      final layouts = await repository.getBusLayouts();
      emit(BusLayoutSaved(layouts));
      emit(BusLayoutLoaded(layouts));
    } catch (e) {
      emit(BusLayoutError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateBusLayout event,
    Emitter<BusLayoutState> emit,
  ) async {
    final currentState = state;
    final List<BusLayout>? list = currentState is BusLayoutLoaded
        ? List<BusLayout>.from(currentState.layouts)
        : null;
    emit(BusLayoutSaving(list));
    try {
      await repository.updateBusLayout(event.layout);
      final layouts = await repository.getBusLayouts();
      emit(BusLayoutSaved(layouts));
      emit(BusLayoutLoaded(layouts));
    } catch (e) {
      emit(BusLayoutError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteBusLayout event,
    Emitter<BusLayoutState> emit,
  ) async {
    final currentState = state;
    if (currentState is BusLayoutLoaded) {
      final list = List<BusLayout>.from(currentState.layouts);
      try {
        await repository.deleteBusLayout(event.id);
        list.removeWhere((l) => l.id == event.id);
        emit(BusLayoutLoaded(list));
      } catch (e) {
        emit(BusLayoutError(e.toString()));
      }
    }
  }
}
