import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/nextcloud_browse_result.dart';
import '../../domain/entities/nextcloud_image.dart';
import '../../domain/repositories/nextcloud_repository.dart';
import 'gallery_event.dart';
import 'gallery_state.dart';

class GalleryBloc extends Bloc<GalleryEvent, GalleryState> {
  final NextcloudRepository _repository;

  /// Caché de resultados browse por path. '' = raíz.
  final Map<String, NextcloudBrowseResult> _browseCache = {};

  GalleryBloc({required NextcloudRepository repository})
      : _repository = repository,
        super(GalleryInitial()) {
    on<BrowseCarpeta>(_onBrowse);
    on<CrearCarpetaGallery>(_onCrearCarpeta);
    on<SubirImagenGallery>(_onSubir);
    on<EliminarImagenGallery>(_onEliminar);
    on<EliminarCarpetaGallery>(_onEliminarCarpeta);
  }

  String _key(String? folder) => folder ?? '';

  GalleryBrowseCargada _fromResult(NextcloudBrowseResult r) =>
      GalleryBrowseCargada(
        folder: r.folder,
        subfolders: r.subfolders,
        images: r.images,
      );

  // ─── Browse ──────────────────────────────────────────────────────────────

  Future<void> _onBrowse(
    BrowseCarpeta event,
    Emitter<GalleryState> emit,
  ) async {
    final key = _key(event.folder);
    if (_browseCache.containsKey(key)) {
      emit(_fromResult(_browseCache[key]!));
      return;
    }
    emit(const GalleryCargando());
    try {
      final result = await _repository.browse(event.folder);
      _browseCache[key] = result;
      emit(_fromResult(result));
    } catch (_) {
      emit(const GalleryError('No se pudo cargar el contenido'));
    }
  }

  // ─── Crear carpeta ────────────────────────────────────────────────────────

  Future<void> _onCrearCarpeta(
    CrearCarpetaGallery event,
    Emitter<GalleryState> emit,
  ) async {
    final current = state;
    final browse = current is GalleryBrowseCargada ? current : null;

    emit(GalleryBrowseCargada(
      folder: browse?.folder,
      subfolders: browse?.subfolders ?? const [],
      images: browse?.images ?? const [],
      creandoCarpeta: true,
    ));
    try {
      await _repository.crearCarpeta(event.nombre);
      // Recargar carpeta actual para mostrar la nueva subcarpeta
      _browseCache.remove(_key(browse?.folder));
      final result = await _repository.browse(browse?.folder);
      _browseCache[_key(result.folder)] = result;
      emit(_fromResult(result));
    } catch (_) {
      emit(GalleryBrowseCargada(
        folder: browse?.folder,
        subfolders: browse?.subfolders ?? const [],
        images: browse?.images ?? const [],
        errorCreacion: 'No se pudo crear la carpeta. Intenta de nuevo.',
      ));
    }
  }

  // ─── Subir imagen ─────────────────────────────────────────────────────────

  Future<void> _onSubir(
    SubirImagenGallery event,
    Emitter<GalleryState> emit,
  ) async {
    final current = state;
    final browse = current is GalleryBrowseCargada ? current : null;
    final prev = browse?.images ?? const <NextcloudImage>[];

    emit(GalleryBrowseCargada(
      folder: browse?.folder,
      subfolders: browse?.subfolders ?? const [],
      images: prev,
      subiendo: true,
    ));
    try {
      final nueva = await _repository.subirImagen(
        folder: event.folder,
        bytes: event.bytes,
        filename: event.filename,
        mimeType: event.mimeType,
      );
      final updated = [nueva, ...prev];
      final result = NextcloudBrowseResult(
        folder: browse?.folder,
        subfolders: browse?.subfolders ?? const [],
        images: updated,
      );
      _browseCache[_key(browse?.folder)] = result;
      emit(_fromResult(result));
    } catch (_) {
      emit(GalleryBrowseCargada(
        folder: browse?.folder,
        subfolders: browse?.subfolders ?? const [],
        images: prev,
        errorSubida: 'No se pudo subir la imagen. Intenta de nuevo.',
      ));
    }
  }

  // ─── Eliminar imagen ──────────────────────────────────────────────────────

  Future<void> _onEliminar(
    EliminarImagenGallery event,
    Emitter<GalleryState> emit,
  ) async {
    final current = state;
    if (current is! GalleryBrowseCargada) return;

    emit(GalleryBrowseCargada(
      folder: current.folder,
      subfolders: current.subfolders,
      images: current.images,
      eliminando: true,
    ));
    try {
      await _repository.eliminarImagen(event.imageUrl);
      final updated = current.images
          .where((img) => img.filename != event.filename)
          .toList();
      final result = NextcloudBrowseResult(
        folder: current.folder,
        subfolders: current.subfolders,
        images: updated,
      );
      _browseCache[_key(current.folder)] = result;
      emit(_fromResult(result));
    } catch (_) {
      emit(GalleryBrowseCargada(
        folder: current.folder,
        subfolders: current.subfolders,
        images: current.images,
        errorEliminacion: 'No se pudo eliminar la imagen. Intenta de nuevo.',
      ));
    }
  }

  // ─── Eliminar carpeta ─────────────────────────────────────────────────────

  Future<void> _onEliminarCarpeta(
    EliminarCarpetaGallery event,
    Emitter<GalleryState> emit,
  ) async {
    final current = state;
    final browse = current is GalleryBrowseCargada ? current : null;

    emit(GalleryBrowseCargada(
      folder: browse?.folder,
      subfolders: browse?.subfolders ?? const [],
      images: browse?.images ?? const [],
      eliminandoCarpeta: true,
    ));
    try {
      await _repository.eliminarCarpeta(event.folder);
      // Invalida la carpeta eliminada y todas sus descendientes del caché
      _browseCache.removeWhere(
        (key, _) => key == event.folder || key.startsWith('${event.folder}/'),
      );
      // Recarga la carpeta actual para reflejar que la subcarpeta ya no existe
      _browseCache.remove(_key(browse?.folder));
      final result = await _repository.browse(browse?.folder);
      _browseCache[_key(result.folder)] = result;
      emit(_fromResult(result));
    } catch (_) {
      emit(GalleryBrowseCargada(
        folder: browse?.folder,
        subfolders: browse?.subfolders ?? const [],
        images: browse?.images ?? const [],
        errorEliminacionCarpeta: 'No se pudo eliminar la carpeta. Intenta de nuevo.',
      ));
    }
  }
}
