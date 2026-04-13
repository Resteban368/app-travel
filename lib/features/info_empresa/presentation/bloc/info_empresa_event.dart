import 'package:equatable/equatable.dart';
import '../../domain/entities/info_empresa.dart';

abstract class InfoEmpresaEvent extends Equatable {
  const InfoEmpresaEvent();

  @override
  List<Object?> get props => [];
}

class LoadInfo extends InfoEmpresaEvent {}

class CreateInfo extends InfoEmpresaEvent {
  final InfoEmpresa info;
  const CreateInfo(this.info);

  @override
  List<Object?> get props => [info];
}

class UpdateInfo extends InfoEmpresaEvent {
  final InfoEmpresa info;
  const UpdateInfo(this.info);

  @override
  List<Object?> get props => [info];
}

class DeleteInfo extends InfoEmpresaEvent {
  final int id;
  const DeleteInfo(this.id);

  @override
  List<Object?> get props => [id];
}

class SyncVectors extends InfoEmpresaEvent {}
