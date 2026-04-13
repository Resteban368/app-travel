import 'package:equatable/equatable.dart';
import '../../domain/entities/catalogue.dart';

abstract class CatalogueEvent extends Equatable {
  const CatalogueEvent();

  @override
  List<Object?> get props => [];
}

class LoadCatalogues extends CatalogueEvent {}

class CreateCatalogue extends CatalogueEvent {
  final Catalogue catalogue;
  const CreateCatalogue(this.catalogue);

  @override
  List<Object?> get props => [catalogue];
}

class UpdateCatalogue extends CatalogueEvent {
  final Catalogue catalogue;
  const UpdateCatalogue(this.catalogue);

  @override
  List<Object?> get props => [catalogue];
}

class DeleteCatalogue extends CatalogueEvent {
  final int id;
  const DeleteCatalogue(this.id);

  @override
  List<Object?> get props => [id];
}
