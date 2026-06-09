import 'package:equatable/equatable.dart';
import '../../domain/entities/nextcloud_image.dart';

abstract class GalleryState extends Equatable {
  const GalleryState();
  @override
  List<Object?> get props => [];
}

class GalleryInitial extends GalleryState {}

class GalleryCargando extends GalleryState {
  final List<NextcloudImage> imagenes;
  final bool subiendo;
  const GalleryCargando({this.imagenes = const [], this.subiendo = false});
  @override
  List<Object?> get props => [imagenes, subiendo];
}

class GalleryCargada extends GalleryState {
  final List<NextcloudImage> imagenes;
  final String folder;
  final bool subiendo;
  final String? errorSubida;
  final bool eliminando;
  final String? errorEliminacion;
  const GalleryCargada({
    required this.imagenes,
    required this.folder,
    this.subiendo = false,
    this.errorSubida,
    this.eliminando = false,
    this.errorEliminacion,
  });
  @override
  List<Object?> get props => [
    imagenes, folder, subiendo, errorSubida, eliminando, errorEliminacion,
  ];
}

class GalleryError extends GalleryState {
  final String mensaje;
  const GalleryError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}
