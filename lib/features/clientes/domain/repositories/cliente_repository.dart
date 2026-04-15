import '../entities/cliente.dart';

abstract class ClienteRepository {
  Future<List<Cliente>> getClientes();
  Future<Cliente> getClienteById(int id);
  Future<void> createCliente(Cliente cliente);
  Future<void> updateCliente(Cliente cliente);
  Future<void> deleteCliente(int id);
}
