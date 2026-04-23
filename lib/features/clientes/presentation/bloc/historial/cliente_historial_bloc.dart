import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/cliente_repository.dart';
import 'cliente_historial_event.dart';
import 'cliente_historial_state.dart';

class ClienteHistorialBloc extends Bloc<ClienteHistorialEvent, ClienteHistorialState> {
  final ClienteRepository repository;

  ClienteHistorialBloc({required this.repository}) : super(ClienteHistorialInitial()) {
    on<LoadClienteHistorial>(_onLoadHistorial);
  }

  Future<void> _onLoadHistorial(
    LoadClienteHistorial event,
    Emitter<ClienteHistorialState> emit,
  ) async {
    emit(ClienteHistorialLoading());
    try {
      final historial = await repository.getClienteHistorial(event.clienteId);
      emit(ClienteHistorialLoaded(historial));
    } catch (e) {
      emit(ClienteHistorialError(e.toString()));
    }
  }
}
