import 'package:equatable/equatable.dart';

abstract class OpinionEvent extends Equatable {
  const OpinionEvent();
  @override
  List<Object?> get props => [];
}

class LoadOpiniones extends OpinionEvent {}

class SetOpinionAprobada extends OpinionEvent {
  final int id;
  final bool aprobada;
  const SetOpinionAprobada(this.id, this.aprobada);
  @override
  List<Object?> get props => [id, aprobada];
}

class DeleteOpinion extends OpinionEvent {
  final int id;
  const DeleteOpinion(this.id);
  @override
  List<Object?> get props => [id];
}
