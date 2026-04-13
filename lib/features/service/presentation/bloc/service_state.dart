import 'package:equatable/equatable.dart';
import '../../domain/entities/service.dart';

abstract class ServiceState extends Equatable {
  const ServiceState();
  @override
  List<Object?> get props => [];
}

class ServiceInitial extends ServiceState {}

class ServiceLoading extends ServiceState {}

class ServicesLoaded extends ServiceState {
  final List<Service> services;
  const ServicesLoaded(this.services);
  @override
  List<Object?> get props => [services];
}

class ServiceError extends ServiceState {
  final String message;
  const ServiceError(this.message);
  @override
  List<Object?> get props => [message];
}

class ServiceSaving extends ServiceState {
  final List<Service>? services;
  const ServiceSaving([this.services]);
  @override
  List<Object?> get props => [services];
}

class ServiceSaved extends ServiceState {
  final List<Service>? services;
  const ServiceSaved([this.services]);
  @override
  List<Object?> get props => [services];
}
