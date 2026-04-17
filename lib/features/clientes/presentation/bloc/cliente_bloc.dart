import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/cliente_repository.dart';
import '../../domain/entities/cliente.dart';
import 'cliente_event.dart';
import 'cliente_state.dart';

class ClienteBloc extends Bloc<ClienteEvent, ClienteState> {
  final ClienteRepository repository;

  ClienteBloc({required this.repository}) : super(ClienteInitial()) {
    on<LoadClientes>(_onLoadClientes);
    on<CreateCliente>(_onCreateCliente);
    on<UpdateCliente>(_onUpdateCliente);
    on<DeleteCliente>(_onDeleteCliente);
  }

  Future<void> _onLoadClientes(
    LoadClientes event,
    Emitter<ClienteState> emit,
  ) async {
    emit(ClienteLoading());
    try {
      final clientes = await repository.getClientes();
      emit(ClienteLoaded(clientes));
    } catch (e) {
      emit(ClienteError(e.toString()));
    }
  }

  Future<void> _onCreateCliente(
    CreateCliente event,
    Emitter<ClienteState> emit,
  ) async {
    final current = _getCurrentClientes();
    emit(ClienteSaving(clientes: current));
    try {
      final message = await repository.createCliente(event.cliente);
      final updated = await repository.getClientes();
      emit(ClienteActionSuccess(updated, message: message));
    } catch (e) {
      emit(ClienteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateCliente(
    UpdateCliente event,
    Emitter<ClienteState> emit,
  ) async {
    final current = _getCurrentClientes();
    emit(ClienteSaving(clientes: current));
    try {
      await repository.updateCliente(event.cliente);
      final updated = await repository.getClientes();
      emit(ClienteActionSuccess(updated));
    } catch (e) {
      emit(ClienteError(e.toString()));
    }
  }

  Future<void> _onDeleteCliente(
    DeleteCliente event,
    Emitter<ClienteState> emit,
  ) async {
    final current = _getCurrentClientes();
    emit(ClienteSaving(clientes: current));
    try {
      await repository.deleteCliente(event.id);
      final updated = await repository.getClientes();
      emit(ClienteActionSuccess(updated));
    } catch (e) {
      emit(ClienteError(e.toString()));
    }
  }

  List<Cliente> _getCurrentClientes() {
    if (state is ClienteLoaded) {
      return (state as ClienteLoaded).clientes;
    } else if (state is ClienteSaving) {
      return (state as ClienteSaving).clientes ?? [];
    } else if (state is ClienteActionSuccess) {
      return (state as ClienteActionSuccess).clientes;
    }
    return [];
  }
}
