import 'package:equatable/equatable.dart';
import '../../domain/entities/proveedor.dart';

abstract class ProveedorEvent extends Equatable {
  const ProveedorEvent();

  @override
  List<Object?> get props => [];
}

class LoadProveedores extends ProveedorEvent {
  final String? search;
  const LoadProveedores({this.search});

  @override
  List<Object?> get props => [search];
}

class CreateProveedor extends ProveedorEvent {
  final Proveedor proveedor;
  const CreateProveedor(this.proveedor);

  @override
  List<Object?> get props => [proveedor];
}

class UpdateProveedor extends ProveedorEvent {
  final Proveedor proveedor;
  const UpdateProveedor(this.proveedor);

  @override
  List<Object?> get props => [proveedor];
}

class DeleteProveedor extends ProveedorEvent {
  final int id;
  const DeleteProveedor(this.id);

  @override
  List<Object?> get props => [id];
}
