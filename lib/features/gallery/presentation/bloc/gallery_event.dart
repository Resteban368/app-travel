import 'dart:typed_data';
import 'package:equatable/equatable.dart';

abstract class GalleryEvent extends Equatable {
  const GalleryEvent();
  @override
  List<Object?> get props => [];
}

/// Navega y carga subcarpetas + imágenes de [folder] (null = raíz).
class BrowseCarpeta extends GalleryEvent {
  final String? folder;
  const BrowseCarpeta(this.folder);
  @override
  List<Object?> get props => [folder];
}

class CrearCarpetaGallery extends GalleryEvent {
  final String nombre;
  const CrearCarpetaGallery(this.nombre);
  @override
  List<Object?> get props => [nombre];
}

class SubirImagenGallery extends GalleryEvent {
  final String? folder;
  final Uint8List bytes;
  final String filename;
  final String mimeType;
  const SubirImagenGallery({
    this.folder,
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
  @override
  List<Object?> get props => [folder, filename, mimeType];
}

class EliminarImagenGallery extends GalleryEvent {
  final String filename;
  final String imageUrl;
  const EliminarImagenGallery({
    required this.filename,
    required this.imageUrl,
  });
  @override
  List<Object?> get props => [filename, imageUrl];
}

class EliminarCarpetaGallery extends GalleryEvent {
  final String folder;
  const EliminarCarpetaGallery(this.folder);
  @override
  List<Object?> get props => [folder];
}
