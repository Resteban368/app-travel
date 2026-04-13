import 'package:equatable/equatable.dart';
import '../../domain/entities/catalogue.dart';

abstract class CatalogueState extends Equatable {
  const CatalogueState();

  @override
  List<Object?> get props => [];
}

class CatalogueInitial extends CatalogueState {}

class CatalogueLoading extends CatalogueState {}

class CatalogueSaving extends CatalogueState {
  final List<Catalogue>? catalogues;
  const CatalogueSaving([this.catalogues]);

  @override
  List<Object?> get props => [catalogues];
}

class CatalogueLoaded extends CatalogueState {
  final List<Catalogue> catalogues;
  const CatalogueLoaded(this.catalogues);

  @override
  List<Object?> get props => [catalogues];
}

class CatalogueSaved extends CatalogueState {
  final List<Catalogue>? catalogues;
  const CatalogueSaved([this.catalogues]);

  @override
  List<Object?> get props => [catalogues];
}

class CatalogueError extends CatalogueState {
  final String message;
  const CatalogueError(this.message);

  @override
  List<Object?> get props => [message];
}
