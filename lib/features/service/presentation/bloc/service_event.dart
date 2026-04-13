import 'package:equatable/equatable.dart';
import '../../domain/entities/service.dart';

abstract class ServiceEvent extends Equatable {
  const ServiceEvent();
  @override
  List<Object?> get props => [];
}

class LoadServices extends ServiceEvent {}

class CreateService extends ServiceEvent {
  final Service service;
  const CreateService(this.service);
  @override
  List<Object?> get props => [service];
}

class UpdateService extends ServiceEvent {
  final Service service;
  const UpdateService(this.service);
  @override
  List<Object?> get props => [service];
}

class DeleteService extends ServiceEvent {
  final int id;
  const DeleteService(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleServiceActive extends ServiceEvent {
  final int id;
  const ToggleServiceActive(this.id);
  @override
  List<Object?> get props => [id];
}
