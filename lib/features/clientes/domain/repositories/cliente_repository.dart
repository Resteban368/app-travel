import '../entities/cliente.dart';
import '../entities/cliente_historial.dart';

abstract class ClienteRepository {
  Future<List<Cliente>> getClientes();
  Future<Cliente> getClienteById(int id);
  Future<String?> createCliente(Cliente cliente);
  Future<void> updateCliente(Cliente cliente);
  Future<void> deleteCliente(int id);
  Future<ClienteHistorial> getClienteHistorial(int id);
}
