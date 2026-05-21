import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/proveedor.dart';
import '../../domain/repositories/proveedor_repository.dart';
import 'proveedor_event.dart';
import 'proveedor_state.dart';

class ProveedorBloc extends Bloc<ProveedorEvent, ProveedorState> {
  final ProveedorRepository repository;

  ProveedorBloc({required this.repository}) : super(ProveedorInitial()) {
    on<LoadProveedores>(_onLoad);
    on<CreateProveedor>(_onCreate);
    on<UpdateProveedor>(_onUpdate);
    on<DeleteProveedor>(_onDelete);
  }

  Future<void> _onLoad(
    LoadProveedores event,
    Emitter<ProveedorState> emit,
  ) async {
    emit(ProveedorLoading());
    try {
      final proveedores = await repository.getProveedores(search: event.search);
      emit(ProveedorLoaded(proveedores));
    } catch (e) {
      emit(ProveedorError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateProveedor event,
    Emitter<ProveedorState> emit,
  ) async {
    final current =
        state is ProveedorLoaded ? (state as ProveedorLoaded).proveedores : null;
    emit(ProveedorSaving(current));
    try {
      await repository.createProveedor(event.proveedor);
      final proveedores = await repository.getProveedores();
      emit(ProveedorSaved(proveedores));
      emit(ProveedorLoaded(proveedores));
    } catch (e) {
      emit(ProveedorError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateProveedor event,
    Emitter<ProveedorState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProveedorLoaded) {
      final list = List<Proveedor>.from(currentState.proveedores);
      emit(ProveedorSaving(list));
      try {
        await repository.updateProveedor(event.proveedor);
        final idx = list.indexWhere((p) => p.id == event.proveedor.id);
        if (idx != -1) list[idx] = event.proveedor;
        emit(ProveedorSaved(list));
        emit(ProveedorLoaded(list));
      } catch (e) {
        emit(ProveedorError(e.toString()));
      }
    }
  }

  Future<void> _onDelete(
    DeleteProveedor event,
    Emitter<ProveedorState> emit,
  ) async {
    final currentState = state;
    if (currentState is ProveedorLoaded) {
      final list = List<Proveedor>.from(currentState.proveedores);
      try {
        await repository.deleteProveedor(event.id);
        list.removeWhere((p) => p.id == event.id);
        emit(ProveedorLoaded(list));
      } catch (e) {
        emit(ProveedorError(e.toString()));
      }
    }
  }
}
