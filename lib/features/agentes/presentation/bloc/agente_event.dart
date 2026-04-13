import 'package:equatable/equatable.dart';
import '../../domain/entities/agente.dart';

abstract class AgenteEvent extends Equatable {
  const AgenteEvent();

  @override
  List<Object?> get props => [];
}

class LoadAgentes extends AgenteEvent {}

class CreateAgente extends AgenteEvent {
  final Agente agente;
  const CreateAgente(this.agente);

  @override
  List<Object?> get props => [agente];
}

class UpdateAgente extends AgenteEvent {
  final Agente agente;
  const UpdateAgente(this.agente);

  @override
  List<Object?> get props => [agente];
}

class DeleteAgente extends AgenteEvent {
  final int id;
  const DeleteAgente(this.id);

  @override
  List<Object?> get props => [id];
}
