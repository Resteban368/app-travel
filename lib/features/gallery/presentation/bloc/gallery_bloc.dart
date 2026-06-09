import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/nextcloud_image.dart';
import '../../domain/repositories/nextcloud_repository.dart';
import 'gallery_event.dart';
import 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final NextcloudRepository _repository;

  GalleryBloc({required NextcloudRepository repository})
      : _repository = repository,
        super(GalleryInitial()) {
    on<CargarGallery>(_onCargar);
    on<SubirImagenGallery>(_onSubir);
    on<EliminarImagenGallery>(_onEliminar);
  }

  Future<void> _onCargar(
    CargarGallery event,
    Emitter<GalleryState> emit,
  ) async {
    final prevImagenes = state is GalleryCargada
        ? (state as GalleryCargada).imagenes
        : const <NextcloudImage>[];
    emit(GalleryCargando(imagenes: prevImagenes));
    try {
      final imagenes = await _repository.getImagenes(event.folder);
      emit(GalleryCargada(imagenes: imagenes, folder: event.folder));
    } catch (e) {
      emit(GalleryError('No se pudieron cargar las imágenes'));
    }
  }

  Future<void> _onSubir(
    SubirImagenGallery event,
    Emitter<GalleryState> emit,
  ) async {
    final current = state;
    final prev = current is GalleryCargada
        ? current.imagenes
        : const <NextcloudImage>[];
    final folder = current is GalleryCargada ? current.folder : event.folder;
    emit(GalleryCargada(imagenes: prev, folder: folder, subiendo: true));
    try {
      final nueva = await _repository.subirImagen(
        folder: event.folder,
        bytes: event.bytes,
        filename: event.filename,
        mimeType: event.mimeType,
      );
      emit(GalleryCargada(imagenes: [nueva, ...prev], folder: folder));
    } catch (_) {
      emit(GalleryCargada(
        imagenes: prev,
        folder: folder,
        errorSubida: 'No se pudo subir la imagen. Intenta de nuevo.',
      ));
    }
  }

  Future<void> _onEliminar(
    EliminarImagenGallery event,
    Emitter<GalleryState> emit,
  ) async {
    final current = state;
    if (current is! GalleryCargada) return;

    emit(GalleryCargada(
      imagenes: current.imagenes,
      folder: current.folder,
      eliminando: true,
    ));

    try {
      await _repository.eliminarImagen(event.imageUrl);
      final updated = current.imagenes
          .where((img) => img.filename != event.filename)
          .toList();
      emit(GalleryCargada(imagenes: updated, folder: current.folder));
    } catch (_) {
      emit(GalleryCargada(
        imagenes: current.imagenes,
        folder: current.folder,
        errorEliminacion: 'No se pudo eliminar la imagen. Intenta de nuevo.',
      ));
    }
  }
}
