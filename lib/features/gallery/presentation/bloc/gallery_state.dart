import 'package:equatable/equatable.dart';
import '../../domain/entities/nextcloud_folder.dart';
import '../../domain/entities/nextcloud_image.dart';

abstract class GalleryState extends Equatable {
  const GalleryState();
  @override
  List<Object?> get props => [];
}

class GalleryInitial extends GalleryState {}

class GalleryCargando extends GalleryState {
  const GalleryCargando();
}

/// Estado principal: contiene subcarpetas + imágenes de la carpeta actual.
/// [folder] null = raíz.
class GalleryBrowseCargada extends GalleryState {
  final String? folder;
  final List<NextcloudFolder> subfolders;
  final List<NextcloudImage> images;
  final bool subiendo;
  final String? errorSubida;
  final bool eliminando;
  final String? errorEliminacion;
  final bool creandoCarpeta;
  final String? errorCreacion;
  final bool eliminandoCarpeta;
  final String? errorEliminacionCarpeta;

  const GalleryBrowseCargada({
    this.folder,
    required this.subfolders,
    required this.images,
    this.subiendo = false,
    this.errorSubida,
    this.eliminando = false,
    this.errorEliminacion,
    this.creandoCarpeta = false,
    this.errorCreacion,
    this.eliminandoCarpeta = false,
    this.errorEliminacionCarpeta,
  });

  @override
  List<Object?> get props => [
    folder, subfolders, images,
    subiendo, errorSubida,
    eliminando, errorEliminacion,
    creandoCarpeta, errorCreacion,
    eliminandoCarpeta, errorEliminacionCarpeta,
  ];
}

class GalleryError extends GalleryState {
  final String mensaje;
  const GalleryError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}
