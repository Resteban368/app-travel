import 'package:equatable/equatable.dart';
import '../../domain/entities/politica_reserva.dart';

abstract class PoliticaReservaState extends Equatable {
  const PoliticaReservaState();

  @override
  List<Object?> get props => [];
}

class PoliticaInitial extends PoliticaReservaState {}

class PoliticaLoading extends PoliticaReservaState {}

class PoliticaLoaded extends PoliticaReservaState {
  final List<PoliticaReserva> politicas;
  const PoliticaLoaded(this.politicas);

  @override
  List<Object?> get props => [politicas];
}

class PoliticaSaving extends PoliticaReservaState {
  final List<PoliticaReserva>? politicas;
  const PoliticaSaving({this.politicas});

  @override
  List<Object?> get props => [politicas];
}

class PoliticaSaved extends PoliticaReservaState {
  final List<PoliticaReserva> politicas;
  const PoliticaSaved(this.politicas);

  @override
  List<Object?> get props => [politicas];
}

class PoliticaError extends PoliticaReservaState {
  final String message;
  const PoliticaError(this.message);

  @override
  List<Object?> get props => [message];
}
