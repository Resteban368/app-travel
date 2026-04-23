import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/catalogue_repository.dart';
import '../../domain/entities/catalogue.dart';
import 'catalogue_event.dart';
import 'catalogue_state.dart';

class CatalogueBloc extends Bloc<CatalogueEvent, CatalogueState> {
  final CatalogueRepository catalogueRepository;

  CatalogueBloc({required this.catalogueRepository})
    : super(CatalogueInitial()) {
    on<LoadCatalogues>(_onLoadCatalogues);
    on<CreateCatalogue>(_onCreateCatalogue);
    on<UpdateCatalogue>(_onUpdateCatalogue);
    on<DeleteCatalogue>(_onDeleteCatalogue);
  }

  Future<void> _onLoadCatalogues(
    LoadCatalogues event,
    Emitter<CatalogueState> emit,
  ) async {
    emit(CatalogueLoading());
    try {
      final catalogues = await catalogueRepository.getCatalogues();
      emit(CatalogueLoaded(catalogues));
    } catch (e) {
      emit(CatalogueError(e.toString()));
    }
  }

  Future<void> _onCreateCatalogue(
    CreateCatalogue event,
    Emitter<CatalogueState> emit,
  ) async {
    final currentList = state is CatalogueLoaded
        ? (state as CatalogueLoaded).catalogues
        : null;
    emit(CatalogueSaving(currentList));
    try {
      await catalogueRepository.createCatalogue(event.catalogue);
      // Re-fetch only for create to get the new ID
      final catalogues = await catalogueRepository.getCatalogues();
      emit(CatalogueSaved(catalogues));
      emit(CatalogueLoaded(catalogues));
    } catch (e) {
      emit(CatalogueError(e.toString()));
    }
  }

  Future<void> _onUpdateCatalogue(
    UpdateCatalogue event,
    Emitter<CatalogueState> emit,
  ) async {
    final currentState = state;
    if (currentState is CatalogueLoaded) {
      final currentList = List<Catalogue>.from(currentState.catalogues);
      emit(CatalogueSaving(currentList));
      try {
        await catalogueRepository.updateCatalogue(event.catalogue);
        // Local update instead of re-fetching
        final index = currentList.indexWhere(
          (c) => c.idCatalogue == event.catalogue.idCatalogue,
        );
        if (index != -1) {
          currentList[index] = event.catalogue;
        }
        emit(CatalogueSaved(currentList));
        emit(CatalogueLoaded(currentList));
      } catch (e) {
        emit(CatalogueError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteCatalogue(
    DeleteCatalogue event,
    Emitter<CatalogueState> emit,
  ) async {
    final currentState = state;
    if (currentState is CatalogueLoaded) {
      final currentList = List<Catalogue>.from(currentState.catalogues);
      // Optional: emit something or just perform the operation
      try {
        await catalogueRepository.deleteCatalogue(event.id);
        // Local update instead of re-fetching
        currentList.removeWhere((c) => c.idCatalogue == event.id);
        emit(CatalogueLoaded(currentList));
      } catch (e) {
        emit(CatalogueError(e.toString()));
      }
    }
  }
}
