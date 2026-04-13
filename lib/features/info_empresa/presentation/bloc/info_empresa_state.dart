import 'package:equatable/equatable.dart';
import '../../domain/entities/info_empresa.dart';

abstract class InfoEmpresaState extends Equatable {
  const InfoEmpresaState();

  @override
  List<Object?> get props => [];
}

class InfoInitial extends InfoEmpresaState {}

class InfoLoading extends InfoEmpresaState {}

class InfoLoaded extends InfoEmpresaState {
  final List<InfoEmpresa> infoList;
  const InfoLoaded(this.infoList);

  @override
  List<Object?> get props => [infoList];
}

class InfoSaving extends InfoEmpresaState {
  final List<InfoEmpresa>? infoList;
  const InfoSaving({this.infoList});

  @override
  List<Object?> get props => [infoList];
}

class InfoSaved extends InfoEmpresaState {
  final List<InfoEmpresa> infoList;
  const InfoSaved(this.infoList);

  @override
  List<Object?> get props => [infoList];
}

class InfoError extends InfoEmpresaState {
  final String message;
  const InfoError(this.message);

  @override
  List<Object?> get props => [message];
}

class InfoSyncing extends InfoEmpresaState {
  final List<InfoEmpresa> infoList;
  const InfoSyncing(this.infoList);

  @override
  List<Object?> get props => [infoList];
}

class InfoSynced extends InfoEmpresaState {
  final List<InfoEmpresa> infoList;
  const InfoSynced(this.infoList);

  @override
  List<Object?> get props => [infoList];
}
