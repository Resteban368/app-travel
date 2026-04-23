import 'package:equatable/equatable.dart';
import '../../domain/entities/auditoria_general.dart';

abstract class AuditoriaGeneralState extends Equatable {
  const AuditoriaGeneralState();

  @override
  List<Object?> get props => [];
}

class AuditoriaGeneralInitial extends AuditoriaGeneralState {}

class AuditoriaGeneralLoading extends AuditoriaGeneralState {}

class AuditoriaGeneralLoaded extends AuditoriaGeneralState {
  final List<AuditoriaGeneral> auditoria;

  const AuditoriaGeneralLoaded({required this.auditoria});

  @override
  List<Object?> get props => [auditoria];
}

class AuditoriaGeneralError extends AuditoriaGeneralState {
  final String message;

  const AuditoriaGeneralError(this.message);

  @override
  List<Object?> get props => [message];
}
