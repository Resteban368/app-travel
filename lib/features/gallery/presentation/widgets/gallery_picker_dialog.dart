// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/di/injection_container.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/dialog_loading_widget.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import '../bloc/gallery_bloc.dart';
import '../bloc/gallery_event.dart';
import '../bloc/gallery_state.dart';
import '../../domain/entities/nextcloud_image.dart';

// ─── Carpetas disponibles ─────────────────────────────────────────────────────

const _kFolders = ['general', 'tours', 'hoteles'];
const _kFolderLabels = {'general': 'General', 'tours': 'Tours', 'hoteles': 'Hoteles'};

// ─── Entrada pública ──────────────────────────────────────────────────────────

class GalleryPickerDialog extends StatefulWidget {
  final String initialFolder;
  final bool isAdmin;

  const GalleryPickerDialog({
    super.key,
    this.initialFolder = 'general',
    this.isAdmin = false,
  });

  /// Abre el diálogo y devuelve la URL seleccionada, o null si se cancela.
  static Future<String?> show(
    BuildContext context, {
    String initialFolder = 'general',
    bool isAdmin = false,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => BlocProvider(
        create: (_) =>
            sl<GalleryBloc>()..add(CargarGallery(initialFolder)),
        child: GalleryPickerDialog(
          initialFolder: initialFolder,
          isAdmin: isAdmin,
        ),
      ),
    );
  }

  @override
  State<GalleryPickerDialog> createState() => _GalleryPickerDialogState();
}

class _GalleryPickerDialogState extends State<GalleryPickerDialog> {
  late String _folder;
  String _search = '';
  NextcloudImage? _selected;
  final _searchCtrl = TextEditingController();
  // 'subida' | 'eliminacion' | null
  String? _loadingOperation;

  @override
  void initState() {
    super.initState();
    _folder = widget.initialFolder;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _changeFolder(String folder) {
    if (folder == _folder) return;
    setState(() {
      _folder = folder;
      _selected = null;
      _search = '';
      _searchCtrl.clear();
    });
    context.read<GalleryBloc>().add(CargarGallery(folder));
  }

  Future<void> _pickAndUpload() async {
    final completer = Completer<(Uint8List, String, String)?>();

    final input = html.FileUploadInputElement()
      ..accept = 'image/jpeg,image/png,image/webp';
    input.click();

    input.onChange.listen((_) async {
      final file = input.files?.first;
      if (file == null) {
        completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoad.listen((_) {
        final bytes = Uint8List.fromList(reader.result as List<int>);
        final mime =
            file.type.isNotEmpty ? file.type : 'image/jpeg';
        completer.complete((bytes, file.name, mime));
      });
      reader.onError.listen((_) => completer.complete(null));
    });

    final result = await completer.future;
    if (result == null || !mounted) return;
    final (bytes, name, mime) = result;

    context.read<GalleryBloc>().add(SubirImagenGallery(
      folder: _folder,
      bytes: bytes,
      filename: name,
      mimeType: mime,
    ));
  }

  void _showPreview(BuildContext context, NextcloudImage img) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.88),
      builder: (_) => _ImagePreviewDialog(
        image: img,
        onUse: () {
          Navigator.of(context).pop();
          _selectAndClose(img);
        },
        onCopyUrl: () => _copyUrl(img.url),
      ),
    );
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('URL copiada al portapapeles'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _selectAndClose(NextcloudImage img) {
    Navigator.of(context).pop(img.url);
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  void _onGalleryState(BuildContext context, GalleryState state) {
    if (state is! GalleryCargada) return;

    // ── Subida ────────────────────────────────────────────────────────────────
    if (state.subiendo && _loadingOperation == null) {
      _loadingOperation = 'subida';
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DialogLoadingNetwork(titel: 'Subiendo imagen...'),
      ).whenComplete(() => _loadingOperation = null);
      return;
    }

    if (!state.subiendo && _loadingOperation == 'subida') {
      _loadingOperation = null;
      Navigator.of(context, rootNavigator: true).pop();
      if (state.errorSubida != null) {
        SaasSnackBar.showError(context, state.errorSubida!);
      }
      return;
    }

    // ── Eliminación ───────────────────────────────────────────────────────────
    if (state.eliminando && _loadingOperation == null) {
      _loadingOperation = 'eliminacion';
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            const DialogLoadingNetwork(titel: 'Eliminando imagen...'),
      ).whenComplete(() => _loadingOperation = null);
      return;
    }

    if (!state.eliminando && _loadingOperation == 'eliminacion') {
      _loadingOperation = null;
      Navigator.of(context, rootNavigator: true).pop();
      if (state.errorEliminacion != null) {
        SaasSnackBar.showError(context, state.errorEliminacion!);
      } else {
        SaasSnackBar.showSuccess(context, 'Imagen eliminada correctamente');
        // Si la imagen eliminada estaba seleccionada, deseleccionar
        if (_selected != null &&
            !state.imagenes.any((img) => img.filename == _selected!.filename)) {
          setState(() => _selected = null);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isNarrow = screenSize.width < 480;
    final hPad = isNarrow ? 12.0 : 32.0;
    final vPad = isNarrow ? 16.0 : 24.0;
    final dialogWidth = (screenSize.width - hPad * 2).clamp(0.0, 920.0);
    final dialogHeight = (screenSize.height * 0.9).clamp(0.0, 740.0);

    return BlocListener<GalleryBloc, GalleryState>(
      listenWhen: (prev, next) {
        if (next is! GalleryCargada) return false;
        final p = prev is GalleryCargada ? prev : null;
        return next.subiendo != (p?.subiendo ?? false) ||
            next.eliminando != (p?.eliminando ?? false) ||
            next.errorSubida != null ||
            next.errorEliminacion != null;
      },
      listener: _onGalleryState,
      child: Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      child: Container(
        width: dialogWidth,
        height: dialogHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              _buildHeader(),
              _buildToolbar(),
              const Divider(height: 1, color: SaasPalette.border),
              Expanded(child: _buildContent()),
              _buildFooter(),
            ],
          ),
        ),
      ),
    ),   // Dialog
  );     // BlocListener
  }

  Widget _buildHeader() {

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SaasPalette.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SaasPalette.brand600.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: SaasPalette.brand600,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Galería de imágenes',
            style: TextStyle(
              color: SaasPalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: SaasPalette.textSecondary,
            iconSize: 20,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return BlocBuilder<GalleryBloc, GalleryState>(
      builder: (context, state) {
        final subiendo = state is GalleryCargada && state.subiendo;

        final chips = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _kFolders.map((f) {
            final active = f == _folder;
            return GestureDetector(
              onTap: () => _changeFolder(f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: active ? SaasPalette.brand600 : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? SaasPalette.brand600 : SaasPalette.border,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: SaasPalette.brand600.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _kFolderLabels[f] ?? f,
                  style: TextStyle(
                    color: active ? Colors.white : SaasPalette.textSecondary,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        );

        final searchField = SizedBox(
          height: 36,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar imagen...',
              hintStyle: const TextStyle(
                color: SaasPalette.textTertiary,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: SaasPalette.textTertiary,
              ),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      onPressed: () => setState(() {
                        _search = '';
                        _searchCtrl.clear();
                      }),
                      icon: const Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: SaasPalette.textTertiary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: SaasPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: SaasPalette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: SaasPalette.brand600, width: 1.5),
              ),
            ),
          ),
        );

        final uploadBtn = widget.isAdmin
            ? FilledButton.icon(
                onPressed: subiendo ? null : _pickAndUpload,
                style: FilledButton.styleFrom(
                  backgroundColor: SaasPalette.brand600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: subiendo
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.upload_rounded, size: 16),
                label: Text(
                  subiendo ? 'Subiendo...' : 'Subir',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : null;

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          color: const Color(0xFFF9FAFB),
          child: LayoutBuilder(
            builder: (_, constraints) {
              final narrow = constraints.maxWidth < 560;
              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    chips,
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: searchField),
                        if (uploadBtn != null) ...[
                          const SizedBox(width: 8),
                          uploadBtn,
                        ],
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  chips,
                  const SizedBox(width: 12),
                  Expanded(child: searchField),
                  if (uploadBtn != null) ...[
                    const SizedBox(width: 12),
                    uploadBtn,
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return BlocBuilder<GalleryBloc, GalleryState>(
      builder: (context, state) {
        if (state is GalleryCargando && state.imagenes.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: SaasPalette.brand600,
              strokeWidth: 2,
            ),
          );
        }

        if (state is GalleryError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: SaasPalette.textTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  state.mensaje,
                  style: const TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<GalleryBloc>()
                      .add(CargarGallery(_folder)),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        final imagenes = state is GalleryCargada
            ? state.imagenes
            : (state is GalleryCargando ? state.imagenes : <NextcloudImage>[]);

        final filtered = _search.isEmpty
            ? imagenes
            : imagenes
                .where(
                  (img) => img.filename
                      .toLowerCase()
                      .contains(_search.toLowerCase()),
                )
                .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _search.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.photo_library_outlined,
                  size: 52,
                  color: SaasPalette.textTertiary,
                ),
                const SizedBox(height: 12),
                Text(
                  _search.isNotEmpty
                      ? 'Sin resultados para "$_search"'
                      : 'No hay imágenes en esta carpeta',
                  style: const TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (_search.isEmpty && widget.isAdmin) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Usa el botón "Subir imagen" para agregar la primera',
                    style: TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          );
        }

        return LayoutBuilder(
          builder: (_, constraints) {
            final cardMax = constraints.maxWidth < 400 ? 160.0 : 210.0;
            return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: cardMax,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.76,
          ),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final img = filtered[i];
            final isSelected = _selected?.filename == img.filename;
            return _ImageCard(
              image: img,
              isSelected: isSelected,
              isAdmin: widget.isAdmin,
              onTap: () => setState(() => _selected = img),
              onDoubleTap: () => _selectAndClose(img),
              onPreview: () => _showPreview(context, img),
              onCopyUrl: () => _copyUrl(img.url),
              onDelete: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      _ConfirmDeleteDialog(filename: img.filename),
                );
                if (confirmed == true && mounted) {
                  context.read<GalleryBloc>().add(EliminarImagenGallery(
                    folder: img.folder,
                    filename: img.filename,
                    imageUrl: img.url,
                  ));
                }
              },
            );
          },
        );
          },   // LayoutBuilder builder
        );     // LayoutBuilder
      },
    );
  }

  Widget _buildFooter() {
    final actionButtons = Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed:
              _selected != null ? () => _selectAndClose(_selected!) : null,
          style: FilledButton.styleFrom(
            backgroundColor: SaasPalette.brand600,
            disabledBackgroundColor: SaasPalette.border,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, size: 16),
              SizedBox(width: 6),
              Text(
                'Usar imagen',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(top: BorderSide(color: SaasPalette.border)),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final narrow = constraints.maxWidth < 420;

          // Info sobre la imagen seleccionada
          final infoRow = _selected != null
              ? Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: SaasPalette.brand600,
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: _AuthImage(
                            url: _selected!.url, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selected!.filename,
                        style: const TextStyle(
                          color: SaasPalette.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : const Text(
                  'Selecciona una imagen para usarla',
                  style: TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 12,
                  ),
                );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                infoRow,
                const SizedBox(height: 10),
                actionButtons,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: infoRow),
              const SizedBox(width: 12),
              actionButtons,
            ],
          );
        },
      ),
    );
  }
}

// ─── Card de imagen ───────────────────────────────────────────────────────────

class _ImageCard extends StatefulWidget {
  final NextcloudImage image;
  final bool isSelected;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onPreview;
  final VoidCallback onCopyUrl;
  final VoidCallback onDelete;

  const _ImageCard({
    required this.image,
    required this.isSelected,
    required this.isAdmin,
    required this.onTap,
    required this.onDoubleTap,
    required this.onPreview,
    required this.onCopyUrl,
    required this.onDelete,
  });

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> {
  bool _hovered = false;

  static String _formatDate(DateTime? dt) {
    if (dt == null) return 'Sin fecha';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  static String _shortName(String filename) {
    // Remove UUID prefix if present
    final parts = filename.split('-');
    if (parts.length > 1) {
      // Try to detect if first part is timestamp
      if (int.tryParse(parts.first) != null && parts.first.length >= 10) {
        return parts.skip(1).join('-');
      }
    }
    return filename;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? SaasPalette.brand600
                  : _hovered
                  ? const Color(0xFFCBD5E1)
                  : SaasPalette.border,
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? SaasPalette.brand600.withValues(alpha: 0.12)
                    : _hovered
                    ? Colors.black.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: widget.isSelected ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Imagen ─────────────────────────────────────
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _AuthImage(url: widget.image.url),

                      // Overlay hover
                      AnimatedOpacity(
                        opacity: _hovered && !widget.isSelected ? 0.08 : 0.0,
                        duration: const Duration(milliseconds: 120),
                        child: Container(color: Colors.black),
                      ),

                      // Preview / zoom button (center, hover)
                      AnimatedOpacity(
                        opacity: _hovered ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Center(
                          child: GestureDetector(
                            onTap: widget.onPreview,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.zoom_in_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Checkmark badge (selected)
                      if (widget.isSelected)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: SaasPalette.brand600,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),

                      // Delete button (admin)
                      if (widget.isAdmin)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: AnimatedOpacity(
                            opacity: _hovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 150),
                            child: GestureDetector(
                              onTap: widget.onDelete,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color:
                                      SaasPalette.danger.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Info ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: SaasPalette.border),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shortName(widget.image.filename),
                        style: const TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatDate(widget.image.uploadedAt),
                        style: const TextStyle(
                          color: SaasPalette.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          _SmallActionButton(
                            icon: Icons.link_rounded,
                            label: 'Copiar URL',
                            onTap: widget.onCopyUrl,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Botón pequeño de acción ──────────────────────────────────────────────────

class _SmallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: SaasPalette.bgSubtle,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: SaasPalette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: SaasPalette.textSecondary),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: SaasPalette.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Imagen con autenticación JWT ─────────────────────────────────────────────

class _AuthImage extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const _AuthImage({required this.url, this.fit = BoxFit.cover});

  @override
  State<_AuthImage> createState() => _AuthImageState();
}

class _AuthImageState extends State<_AuthImage> {
  static final Map<String, Uint8List> _cache = {};

  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Uint8List?> _load() async {
    if (_cache.containsKey(widget.url)) return _cache[widget.url];
    try {
      final resp =
          await sl<http.Client>().get(Uri.parse(widget.url));
      if (resp.statusCode == 200) {
        _cache[widget.url] = resp.bodyBytes;
        return resp.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: SaasPalette.brand600,
                ),
              ),
            ),
          );
        }
        if (snap.data == null) {
          return Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                color: SaasPalette.textTertiary,
                size: 22,
              ),
            ),
          );
        }
        return Image.memory(
          snap.data!,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      },
    );
  }
}

// ─── Diálogo de previsualización ─────────────────────────────────────────────

class _ImagePreviewDialog extends StatelessWidget {
  final NextcloudImage image;
  final VoidCallback onUse;
  final VoidCallback onCopyUrl;

  const _ImagePreviewDialog({
    required this.image,
    required this.onUse,
    required this.onCopyUrl,
  });

  static String _shortName(String f) {
    final parts = f.split('-');
    if (parts.length > 1 && int.tryParse(parts.first) != null && parts.first.length >= 10) {
      return parts.skip(1).join('-');
    }
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final w = math.min(screenSize.width - 48.0, 920.0);
    final h = math.min(screenSize.height * 0.92, 700.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: w,
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: Container(
                  color: const Color(0xFF0D0D1A),
                  padding: const EdgeInsets.all(12),
                  child: _AuthImage(url: image.url, fit: BoxFit.contain),
                ),
              ),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      color: const Color(0xFF1A1A2E),
      child: Row(
        children: [
          const Icon(Icons.photo_rounded, color: Colors.white54, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _shortName(image.filename),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
            color: Colors.white60,
            iconSize: 20,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      color: const Color(0xFF1A1A2E),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final narrow = constraints.maxWidth < 480;

          final meta = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (image.uploadedAt != null) ...[
                const Icon(Icons.schedule_rounded, size: 12, color: Colors.white38),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(image.uploadedAt!),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                const SizedBox(width: 10),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  image.folder,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onCopyUrl();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white70,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.link_rounded, size: 14),
                label: const Text('Copiar URL', style: TextStyle(fontSize: 13)),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: onUse,
                style: FilledButton.styleFrom(
                  backgroundColor: SaasPalette.brand600,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.check_rounded, size: 14),
                label: const Text(
                  'Usar imagen',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                meta,
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [actions]),
              ],
            );
          }

          return Row(
            children: [
              meta,
              const Spacer(),
              actions,
            ],
          );
        },
      ),
    );
  }
}

// ─── Diálogo de confirmación de eliminación ───────────────────────────────────

class _ConfirmDeleteDialog extends StatelessWidget {
  final String filename;
  const _ConfirmDeleteDialog({required this.filename});

  static String _shortName(String f) {
    final parts = f.split('-');
    if (parts.length > 1 && int.tryParse(parts.first) != null) {
      return parts.skip(1).join('-');
    }
    return f;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icono ──────────────────────────────────────────────────────
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: SaasPalette.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: SaasPalette.danger,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),

              // ── Título ─────────────────────────────────────────────────────
              const Text(
                '¿Eliminar imagen?',
                style: TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // ── Subtítulo ──────────────────────────────────────────────────
              Text(
                'Se eliminará permanentemente\n"${_shortName(filename)}".\nEsta acción no se puede deshacer.',
                style: const TextStyle(
                  color: SaasPalette.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Botones ────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SaasPalette.textSecondary,
                        side: const BorderSide(color: SaasPalette.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: SaasPalette.danger,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_rounded, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Eliminar',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
