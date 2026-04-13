import 'package:equatable/equatable.dart';
import '../../domain/entities/agente.dart';

abstract class AgenteState extends Equatable {
  const AgenteState();

  @override
  List<Object?> get props => [];
}

class AgenteInitial extends AgenteState {}

class AgenteLoading extends AgenteState {}

class AgenteLoaded extends AgenteState {
  final List<Agente> agentes;
  const AgenteLoaded(this.agentes);

  @override
  List<Object?> get props => [agentes];
}

class AgenteSaving extends AgenteState {
  final List<Agente>? agentes;
  const AgenteSaving({this.agentes});

  @override
  List<Object?> get props => [agentes];
}

class AgenteActionSuccess extends AgenteState {
  final List<Agente> agentes;
  const AgenteActionSuccess(this.agentes);

  @override
  List<Object?> get props => [agentes];
}

class AgenteError extends AgenteState {
  final String message;
  const AgenteError(this.message);

  @override
  List<Object?> get props => [message];
}
