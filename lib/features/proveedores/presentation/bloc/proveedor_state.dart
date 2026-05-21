import 'package:equatable/equatable.dart';
import '../../domain/entities/proveedor.dart';

abstract class ProveedorState extends Equatable {
  const ProveedorState();

  @override
  List<Object?> get props => [];
}

class ProveedorInitial extends ProveedorState {}

class ProveedorLoading extends ProveedorState {}

class ProveedorLoaded extends ProveedorState {
  final List<Proveedor> proveedores;
  const ProveedorLoaded(this.proveedores);

  @override
  List<Object?> get props => [proveedores];
}

class ProveedorSaving extends ProveedorState {
  final List<Proveedor>? proveedores;
  const ProveedorSaving([this.proveedores]);

  @override
  List<Object?> get props => [proveedores];
}

class ProveedorSaved extends ProveedorState {
  final List<Proveedor>? proveedores;
  const ProveedorSaved([this.proveedores]);

  @override
  List<Object?> get props => [proveedores];
}

class ProveedorError extends ProveedorState {
  final String message;
  const ProveedorError(this.message);

  @override
  List<Object?> get props => [message];
}
