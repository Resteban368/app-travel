import '../entities/proveedor.dart';

abstract class ProveedorRepository {
  Future<List<Proveedor>> getProveedores({String? search});
  Future<Proveedor> createProveedor(Proveedor proveedor);
  Future<Proveedor> updateProveedor(Proveedor proveedor);
  Future<void> deleteProveedor(int id);
}
