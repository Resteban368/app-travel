import '../entities/cliente.dart';
import '../entities/cliente_historial.dart';

abstract class ClienteRepository {
  Future<List<Cliente>> getClientes({String? search, int page = 1, int limit = 20});
  Future<Cliente> getClienteById(int id);
  Future<String?> createCliente(Cliente cliente);
  Future<void> updateCliente(Cliente cliente);
  Future<void> deleteCliente(int id);
  Future<ClienteHistorial> getClienteHistorial(int id);
}
