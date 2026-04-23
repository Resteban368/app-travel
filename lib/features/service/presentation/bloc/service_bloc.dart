import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/service_repository.dart';
import 'service_event.dart';
import 'service_state.dart';

class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final ServiceRepository _serviceRepository;

  ServiceBloc({required ServiceRepository serviceRepository})
    : _serviceRepository = serviceRepository,
      super(ServiceInitial()) {
    on<LoadServices>(_onLoadServices);
    on<CreateService>(_onCreateService);
    on<UpdateService>(_onUpdateService);
    on<DeleteService>(_onDeleteService);
    on<ToggleServiceActive>(_onToggleServiceActive);
  }

  Future<void> _onLoadServices(
    LoadServices event,
    Emitter<ServiceState> emit,
  ) async {
    emit(ServiceLoading());
    try {
      final services = await _serviceRepository.getServices();
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServiceError(e.toString()));
    }
  }

  Future<void> _onCreateService(
    CreateService event,
    Emitter<ServiceState> emit,
  ) async {
    final currentServices = state is ServicesLoaded
        ? (state as ServicesLoaded).services
        : null;
    emit(ServiceSaving(currentServices));
    try {
      await _serviceRepository.createService(event.service);
      emit(ServiceSaved(currentServices));
      add(LoadServices());
    } catch (e) {
      emit(ServiceError(e.toString()));
    }
  }

  Future<void> _onUpdateService(
    UpdateService event,
    Emitter<ServiceState> emit,
  ) async {
    final currentServices = state is ServicesLoaded
        ? (state as ServicesLoaded).services
        : null;
    emit(ServiceSaving(currentServices));
    try {
      await _serviceRepository.updateService(event.service);
      emit(ServiceSaved(currentServices));
      add(LoadServices());
    } catch (e) {
      emit(ServiceError(e.toString()));
    }
  }

  Future<void> _onDeleteService(
    DeleteService event,
    Emitter<ServiceState> emit,
  ) async {
    final currentServices = state is ServicesLoaded
        ? (state as ServicesLoaded).services
        : null;
    emit(ServiceSaving(currentServices));
    try {
      await _serviceRepository.deleteService(event.id);
      emit(ServiceSaved(currentServices));
      add(LoadServices());
    } catch (e) {
      emit(ServiceError(e.toString()));
    }
  }

  Future<void> _onToggleServiceActive(
    ToggleServiceActive event,
    Emitter<ServiceState> emit,
  ) async {
    final currentState = state;
    if (currentState is ServicesLoaded) {
      final currentServices = currentState.services;
      emit(ServiceSaving(currentServices));
      try {
        final service = currentServices.firstWhere((s) => s.id == event.id);
        final updated = service.copyWith(isActive: !service.isActive);
        await _serviceRepository.updateService(updated);
        emit(ServiceSaved(currentServices));
        add(LoadServices());
      } catch (e) {
        emit(ServiceError(e.toString()));
      }
    }
  }
}
