import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/info_empresa_repository.dart';
import '../../domain/entities/info_empresa.dart';
import 'info_empresa_event.dart';
import 'info_empresa_state.dart';

class InfoEmpresaBloc extends Bloc<InfoEmpresaEvent, InfoEmpresaState> {
  final InfoEmpresaRepository repository;

  InfoEmpresaBloc({required this.repository}) : super(InfoInitial()) {
    on<LoadInfo>(_onLoadInfo);
    on<CreateInfo>(_onCreateInfo);
    on<UpdateInfo>(_onUpdateInfo);
    on<DeleteInfo>(_onDeleteInfo);
    on<SyncVectors>(_onSyncVectors);
  }

  Future<void> _onLoadInfo(
    LoadInfo event,
    Emitter<InfoEmpresaState> emit,
  ) async {
    emit(InfoLoading());
    try {
      final infoList = await repository.getInfo();
      emit(InfoLoaded(infoList));
    } catch (e) {
      emit(InfoError(e.toString()));
    }
  }

  Future<void> _onCreateInfo(
    CreateInfo event,
    Emitter<InfoEmpresaState> emit,
  ) async {
    final currentInfo = _getCurrentInfo();
    emit(InfoSaving(infoList: currentInfo));
    try {
      await repository.createInfo(event.info);
      final updatedInfo = await repository.getInfo();
      emit(InfoSaved(updatedInfo));
    } catch (e) {
      emit(InfoError(e.toString()));
    }
  }

  Future<void> _onUpdateInfo(
    UpdateInfo event,
    Emitter<InfoEmpresaState> emit,
  ) async {
    final currentInfo = _getCurrentInfo();
    emit(InfoSaving(infoList: currentInfo));
    try {
      await repository.updateInfo(event.info);
      final updatedInfo = await repository.getInfo();
      emit(InfoSaved(updatedInfo));
    } catch (e) {
      emit(InfoError(e.toString()));
    }
  }

  Future<void> _onDeleteInfo(
    DeleteInfo event,
    Emitter<InfoEmpresaState> emit,
  ) async {
    final currentInfo = _getCurrentInfo();
    emit(InfoSaving(infoList: currentInfo));
    try {
      await repository.deleteInfo(event.id);
      final updatedInfo = await repository.getInfo();
      emit(InfoSaved(updatedInfo));
    } catch (e) {
      emit(InfoError(e.toString()));
    }
  }

  Future<void> _onSyncVectors(
    SyncVectors event,
    Emitter<InfoEmpresaState> emit,
  ) async {
    final currentInfo = _getCurrentInfo();
    if (currentInfo.isEmpty) return;
    
    emit(InfoSyncing(currentInfo));
    try {
      await repository.syncVectors();
      emit(InfoSynced(currentInfo));
    } catch (e) {
      emit(InfoError(e.toString()));
    }
  }

  List<InfoEmpresa> _getCurrentInfo() {
    if (state is InfoLoaded) return (state as InfoLoaded).infoList;
    if (state is InfoSaving) return (state as InfoSaving).infoList ?? [];
    if (state is InfoSaved) return (state as InfoSaved).infoList;
    if (state is InfoSyncing) return (state as InfoSyncing).infoList;
    if (state is InfoSynced) return (state as InfoSynced).infoList;
    return [];
  }
}
