import 'package:equatable/equatable.dart';

abstract class SesionesEvent extends Equatable {
  const SesionesEvent();
  @override
  List<Object?> get props => [];
}

class LoadSesiones extends SesionesEvent {
  final DateTime? fecha;
  const LoadSesiones({this.fecha});
  @override
  List<Object?> get props => [fecha];
}
