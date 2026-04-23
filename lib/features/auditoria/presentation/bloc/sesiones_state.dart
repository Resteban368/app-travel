import 'package:equatable/equatable.dart';
import '../../domain/entities/sesion_usuario.dart';

abstract class SesionesState extends Equatable {
  const SesionesState();
  @override
  List<Object?> get props => [];
}

class SesionesInitial extends SesionesState {}

class SesionesLoading extends SesionesState {}

class SesionesLoaded extends SesionesState {
  final List<SesionUsuario> sesiones;
  final DateTime fecha;
  const SesionesLoaded({required this.sesiones, required this.fecha});
  @override
  List<Object?> get props => [sesiones, fecha];
}

class SesionesError extends SesionesState {
  final String message;
  const SesionesError(this.message);
  @override
  List<Object?> get props => [message];
}
