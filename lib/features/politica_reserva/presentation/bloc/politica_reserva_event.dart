import 'package:equatable/equatable.dart';
import '../../domain/entities/politica_reserva.dart';

abstract class PoliticaReservaEvent extends Equatable {
  const PoliticaReservaEvent();

  @override
  List<Object?> get props => [];
}

class LoadPoliticas extends PoliticaReservaEvent {}

class CreatePolitica extends PoliticaReservaEvent {
  final PoliticaReserva politica;
  const CreatePolitica(this.politica);

  @override
  List<Object?> get props => [politica];
}

class UpdatePolitica extends PoliticaReservaEvent {
  final PoliticaReserva politica;
  const UpdatePolitica(this.politica);

  @override
  List<Object?> get props => [politica];
}

class DeletePolitica extends PoliticaReservaEvent {
  final int id;
  const DeletePolitica(this.id);

  @override
  List<Object?> get props => [id];
}

class TogglePoliticaActive extends PoliticaReservaEvent {
  final int id;
  const TogglePoliticaActive(this.id);

  @override
  List<Object?> get props => [id];
}
