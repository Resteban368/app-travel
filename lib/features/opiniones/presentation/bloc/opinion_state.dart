import 'package:equatable/equatable.dart';
import '../../domain/entities/opinion.dart';

abstract class OpinionState extends Equatable {
  const OpinionState();
  @override
  List<Object?> get props => [];
}

class OpinionInitial extends OpinionState {}

class OpinionLoading extends OpinionState {}

class OpinionesLoaded extends OpinionState {
  final List<Opinion> opiniones;
  const OpinionesLoaded(this.opiniones);
  @override
  List<Object?> get props => [opiniones];
}

class OpinionError extends OpinionState {
  final String message;
  const OpinionError(this.message);
  @override
  List<Object?> get props => [message];
}

class OpinionSaving extends OpinionState {
  final List<Opinion>? opiniones;
  const OpinionSaving([this.opiniones]);
  @override
  List<Object?> get props => [opiniones];
}

class OpinionSaved extends OpinionState {
  final List<Opinion>? opiniones;
  final String message;
  const OpinionSaved(this.message, [this.opiniones]);
  @override
  List<Object?> get props => [message, opiniones];
}
