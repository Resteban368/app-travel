// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:agente_viajes/core/di/injection_container.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/auth_network_image.dart';
import 'package:agente_viajes/core/widgets/dialog_loading_widget.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import '../bloc/gallery_bloc.dart';
import '../bloc/gallery_event.dart';
import '../bloc/gallery_state.dart';
import '../../domain/entities/nextcloud_image.dart';

// ─── Entrada pública ──────────────────────────────────────────────────────────

class GalleryPickerDialog extends StatefulWidget {
  final bool isAdmin;
  /// Carpeta raíz de la galería; la navegación no sube más allá de aquí.
  final String rootFolder;
  final void Function(String url)? onSelected;

  const GalleryPickerDialog({
    super.key,
    this.isAdmin = false,
    this.rootFolder = 'Photos',
    this.onSelected,
  });

  static Future<String?> show(
    BuildContext context, {
    bool isAdmin = false,
    String rootFolder = 'Photos',
  }) {
    final completer = Completer<String?>();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (_) => BlocProvider(
        create: (_) => sl<GalleryBloc>()..add(BrowseCarpeta(rootFolder)),
        child: GalleryPickerDialog(
          isAdmin: isAdmin,
          rootFolder: rootFolder,
          onSelected: (url) {
            if (!completer.isCompleted) completer.complete(url);
          },
        ),
      ),
    ).then((_) {
      if (!completer.isCompleted) completer.complete(null);
    });
    return completer.future;
  }

  @override
  State<GalleryPickerDialog> createState() => _GalleryPickerDialogState();
}

// ─── Estado ───────────────────────────────────────────────────────────────────

class _GalleryPickerDialogState extends State<GalleryPickerDialog> {
  late String _currentFolder;

  String _search = '';
  NextcloudImage? _selected;
  final _searchCtrl = TextEditingController();
  String? _loadingOperation;

  @override
  void initState() {
    super.initState();
    _currentFolder = widget.rootFolder;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool get _atRoot => _currentFolder == widget.rootFolder;

  // ─── Navegación ────────────────────────────────────────────────────────────

  void _navigate(String folder) {
    setState(() {
      _currentFolder = folder;
      _selected = null;
      _search = '';
      _searchCtrl.clear();
    });
    context.read<GalleryBloc>().add(BrowseCarpeta(folder));
  }

  void _navigateUp() {
    if (_atRoot) return;
    final idx = _currentFolder.lastIndexOf('/');
    final parent = idx == -1 ? widget.rootFolder : _currentFolder.substring(0, idx);
    // No subir más allá de rootFolder
    _navigate(parent.length < widget.rootFolder.length ? widget.rootFolder : parent);
  }

  String _formatPath(String path) {
    if (path == widget.rootFolder) return 'Galería';
    // Muestra solo la parte relativa a rootFolder
    final prefix = '${widget.rootFolder}/';
    final relative = path.startsWith(prefix) ? path.substring(prefix.length) : path;
    return relative.split('/').join(' / ');
  }

  // ─── Helpers de imagen ─────────────────────────────────────────────────────

  Future<void> _pickAndUpload() async {
    final completer = Completer<(Uint8List, String, String)?>();
    final input = html.FileUploadInputElement()
      ..accept = 'image/jpeg,image/png,image/webp';
    input.click();
    input.onChange.listen((_) async {
      final file = input.files?.first;
      if (file == null) { completer.complete(null); return; }
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoad.listen((_) {
        final bytes = Uint8List.fromList(reader.result as List<int>);
        completer.complete((bytes, file.name, file.type.isNotEmpty ? file.type : 'image/jpeg'));
      });
      reader.onError.listen((_) => completer.complete(null));
    });
    final result = await completer.future;
    if (result == null || !mounted) return;
    final (bytes, name, mime) = result;
    context.read<GalleryBloc>().add(SubirImagenGallery(
      folder: _currentFolder,
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
        onUse: () { Navigator.of(context, rootNavigator: true).pop(); _selectAndClose(img); },
        onCopyUrl: () => _copyUrl(img.url),
      ),
    );
  }

  void _copyUrl(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('URL copiada al portapapeles'),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _selectAndClose(NextcloudImage img) {
    widget.onSelected?.call(img.url);
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showCreateFolderDialog(BuildContext context) {
    final bloc = context.read<GalleryBloc>();
    showDialog<String>(
      context: context,
      builder: (_) => _CreateFolderDialog(parentPath: _currentFolder),
    ).then((nombre) {
      if (nombre != null && nombre.isNotEmpty && mounted) {
        bloc.add(CrearCarpetaGallery(nombre));
      }
    });
  }

  // ─── BLoC listener ─────────────────────────────────────────────────────────

  void _onGalleryState(BuildContext context, GalleryState state) {
    if (state is! GalleryBrowseCargada) return;

    // ── Creación ──────────────────────────────────────────────────────────────
    if (state.creandoCarpeta && _loadingOperation == null) {
      _loadingOperation = 'creacion';
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DialogLoadingNetwork(titel: 'Creando carpeta...'),
      ).whenComplete(() => _loadingOperation = null);
      return;
    }
    if (!state.creandoCarpeta && _loadingOperation == 'creacion') {
      _loadingOperation = null;
      Navigator.of(context, rootNavigator: true).pop();
      if (state.errorCreacion != null) {
        SaasSnackBar.showError(context, state.errorCreacion!);
      } else {
        SaasSnackBar.showSuccess(context, 'Carpeta creada correctamente');
      }
      return;
    }

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
      if (state.errorSubida != null) SaasSnackBar.showError(context, state.errorSubida!);
      return;
    }

    // ── Eliminación imagen ────────────────────────────────────────────────────
    if (state.eliminando && _loadingOperation == null) {
      _loadingOperation = 'eliminacion';
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DialogLoadingNetwork(titel: 'Eliminando imagen...'),
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
        if (_selected != null &&
            !state.images.any((img) => img.filename == _selected!.filename)) {
          setState(() => _selected = null);
        }
      }
      return;
    }

    // ── Eliminación carpeta ───────────────────────────────────────────────────
    if (state.eliminandoCarpeta && _loadingOperation == null) {
      _loadingOperation = 'eliminacionCarpeta';
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DialogLoadingNetwork(titel: 'Eliminando carpeta...'),
      ).whenComplete(() => _loadingOperation = null);
      return;
    }
    if (!state.eliminandoCarpeta && _loadingOperation == 'eliminacionCarpeta') {
      _loadingOperation = null;
      Navigator.of(context, rootNavigator: true).pop();
      if (state.errorEliminacionCarpeta != null) {
        SaasSnackBar.showError(context, state.errorEliminacionCarpeta!);
      } else {
        SaasSnackBar.showSuccess(context, 'Carpeta eliminada correctamente');
      }
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

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
        if (next is! GalleryBrowseCargada) return false;
        final p = prev is GalleryBrowseCargada ? prev : null;
        return next.creandoCarpeta != (p?.creandoCarpeta ?? false) ||
            next.subiendo != (p?.subiendo ?? false) ||
            next.eliminando != (p?.eliminando ?? false) ||
            next.eliminandoCarpeta != (p?.eliminandoCarpeta ?? false) ||
            next.errorCreacion != null ||
            next.errorSubida != null ||
            next.errorEliminacion != null ||
            next.errorEliminacionCarpeta != null;
      },
      listener: _onGalleryState,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: Container(
          width: dialogWidth,
          height: dialogHeight,
          decoration: BoxDecoration(
            color: context.saas.bgApp,
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
                Divider(height: 1, color: context.saas.border),
                Expanded(child: _buildContent()),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final atRoot = _atRoot;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.saas.border)),
      ),
      child: Row(
        children: [
          if (!atRoot)
            IconButton(
              onPressed: _navigateUp,
              icon: const Icon(Icons.arrow_back_rounded),
              color: context.saas.textSecondary,
              iconSize: 20,
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(),
              tooltip: 'Atrás',
            )
          else
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.saas.brand600.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.photo_library_rounded,
                  color: context.saas.brand600, size: 18),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _formatPath(_currentFolder),
              style: TextStyle(
                color: context.saas.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            icon: const Icon(Icons.close_rounded),
            color: context.saas.textSecondary,
            iconSize: 20,
            padding: const EdgeInsets.all(6),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ─── Toolbar ───────────────────────────────────────────────────────────────

  Widget _buildToolbar() {
    return BlocBuilder<GalleryBloc, GalleryState>(
      builder: (context, state) {
        final subiendo =
            state is GalleryBrowseCargada && state.subiendo;
        final creando =
            state is GalleryBrowseCargada && state.creandoCarpeta;

        final searchField = SizedBox(
          height: 36,
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Buscar imagen...',
              hintStyle: TextStyle(
                  color: context.saas.textTertiary, fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 18, color: context.saas.textTertiary),
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      onPressed: () => setState(() {
                        _search = '';
                        _searchCtrl.clear();
                      }),
                      icon: Icon(Icons.close_rounded,
                          size: 16, color: context.saas.textTertiary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
              filled: true,
              fillColor: context.saas.bgApp,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.saas.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: context.saas.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: context.saas.brand600, width: 1.5),
              ),
            ),
          ),
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          color: context.saas.bgApp,
          child: LayoutBuilder(
            builder: (_, constraints) {
              final narrow = constraints.maxWidth < 520;

              final adminBtns = widget.isAdmin
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nueva carpeta
                        OutlinedButton.icon(
                          onPressed: creando
                              ? null
                              : () => _showCreateFolderDialog(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.saas.textSecondary,
                            side: BorderSide(color: context.saas.border),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: creando
                              ? SizedBox(
                                  width: 13,
                                  height: 13,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.saas.textSecondary))
                              : const Icon(Icons.create_new_folder_rounded,
                                  size: 15),
                          label: Text(
                            _atRoot ? 'Nueva carpeta' : 'Nueva subcarpeta',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Subir imagen
                        FilledButton.icon(
                          onPressed: subiendo ? null : _pickAndUpload,
                          style: FilledButton.styleFrom(
                            backgroundColor: context.saas.brand600,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: subiendo
                              ? const SizedBox(
                                  width: 13,
                                  height: 13,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, ))
                              : const Icon(Icons.upload_rounded, size: 15),
                          label: Text(
                            subiendo ? 'Subiendo...' : 'Subir',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )
                  : null;

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    searchField,
                    if (adminBtns != null) ...[
                      const SizedBox(height: 8),
                      adminBtns,
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: searchField),
                  if (adminBtns != null) ...[
                    const SizedBox(width: 12),
                    adminBtns,
                  ],
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ─── Contenido (browse) ────────────────────────────────────────────────────

  Widget _buildContent() {
    return BlocBuilder<GalleryBloc, GalleryState>(
      builder: (context, state) {
        if (state is GalleryCargando) {
          return Center(
            child: CircularProgressIndicator(
                color: context.saas.brand600, strokeWidth: 2),
          );
        }

        if (state is GalleryError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 48, color: context.saas.textTertiary),
                const SizedBox(height: 12),
                Text(state.mensaje,
                    style: TextStyle(
                        color: context.saas.textSecondary, fontSize: 14)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context
                      .read<GalleryBloc>()
                      .add(BrowseCarpeta(_currentFolder)),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (state is GalleryInitial) return const SizedBox.shrink();

        final browse = state as GalleryBrowseCargada;
        final filtered = _search.isEmpty
            ? browse.images
            : browse.images
                .where((img) => img.filename
                    .toLowerCase()
                    .contains(_search.toLowerCase()))
                .toList();

        return CustomScrollView(
          slivers: [
            // ── Subcarpetas ─────────────────────────────────────────────────
            if (browse.subfolders.isNotEmpty) ...[
              _sliverHeader('Subcarpetas', count: browse.subfolders.length),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 96,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    itemCount: browse.subfolders.length,
                    itemBuilder: (_, i) {
                      final sub = browse.subfolders[i];
                      final leafName = sub.nombre.split('/').last;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FolderChip(
                          nombre: leafName,
                          isAdmin: widget.isAdmin,
                          onTap: () => _navigate(sub.nombre),
                          onDelete: () async {
                            final bloc = context.read<GalleryBloc>();
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => _ConfirmDeleteFolderDialog(
                                folder: sub.nombre,
                              ),
                            );
                            if (confirmed == true && mounted) {
                              bloc.add(EliminarCarpetaGallery(sub.nombre));
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Divider(height: 1, color: context.saas.border),
              ),
            ],

            // ── Imágenes ─────────────────────────────────────────────────────
            _sliverHeader(
              'Imágenes',
              count: _search.isEmpty ? browse.images.length : null,
              subtitle: _search.isNotEmpty
                  ? '${filtered.length} resultado${filtered.length == 1 ? '' : 's'}'
                  : null,
            ),

            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _search.isNotEmpty
                            ? Icons.search_off_rounded
                            : Icons.photo_library_outlined,
                        size: 48,
                        color: context.saas.textTertiary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _search.isNotEmpty
                            ? 'Sin resultados para "$_search"'
                            : 'No hay imágenes en esta carpeta',
                        style: TextStyle(
                          color: context.saas.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (_search.isEmpty && widget.isAdmin) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Usa "Subir" para agregar la primera',
                          style: TextStyle(
                            color: context.saas.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.76,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final img = filtered[i];
                      final isSelected =
                          _selected?.filename == img.filename;
                      return _ImageCard(
                        image: img,
                        isSelected: isSelected,
                        isAdmin: widget.isAdmin,
                        onTap: () => setState(() => _selected = img),
                        onDoubleTap: () => _selectAndClose(img),
                        onPreview: () => _showPreview(context, img),
                        onCopyUrl: () => _copyUrl(img.url),
                        onDelete: () async {
                          final bloc = context.read<GalleryBloc>();
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) =>
                                _ConfirmDeleteDialog(filename: img.filename),
                          );
                          if (confirmed == true && mounted) {
                            bloc.add(
                              EliminarImagenGallery(
                                filename: img.filename,
                                imageUrl: img.url,
                              ),
                            );
                          }
                        },
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sliverHeader(
    String title, {
    int? count,
    String? subtitle,
  }) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                color: context.saas.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: context.saas.bgSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.saas.border),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: context.saas.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (subtitle != null) ...[
              const SizedBox(width: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: context.saas.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: context.saas.bgApp,
        border: Border(top: BorderSide(color: context.saas.border)),
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final narrow = constraints.maxWidth < 420;

          final actionButtons = Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _selected != null
                    ? () => _selectAndClose(_selected!)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: context.saas.brand600,
                  disabledBackgroundColor: context.saas.border,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Usar imagen',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          );

          final infoRow = _selected != null
              ? Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: context.saas.brand600, width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: AuthNetworkImage(
                            url: _selected!.url, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selected!.filename,
                        style: TextStyle(
                            color: context.saas.textSecondary, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Selecciona una imagen para usarla',
                  style: TextStyle(
                      color: context.saas.textTertiary, fontSize: 12),
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

// ─── Chip de subcarpeta (scroll horizontal) ───────────────────────────────────

class _FolderChip extends StatefulWidget {
  final String nombre;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FolderChip({
    required this.nombre,
    required this.isAdmin,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_FolderChip> createState() => _FolderChipState();
}

class _FolderChipState extends State<_FolderChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 80,
          decoration: BoxDecoration(
            color: _hovered
                ? context.saas.brand600.withValues(alpha: 0.05)
                : context.saas.bgApp,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? context.saas.brand600 : context.saas.border,
              width: _hovered ? 1.5 : 1,
            ),
          ),
          child: Stack(
            children: [
              // Contenido principal
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_rounded,
                    size: 30,
                    color: _hovered
                        ? context.saas.brand600
                        : const Color(0xFFFBBF24),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      widget.nombre,
                      style: TextStyle(
                        color: _hovered
                            ? context.saas.brand600
                            : context.saas.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Botón eliminar (solo admin, visible en hover)
              if (widget.isAdmin)
                Positioned(
                  top: 4,
                  right: 4,
                  child: AnimatedOpacity(
                    opacity: _hovered ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 150),
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: context.saas.danger.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child:  Icon(
                          Icons.delete_outline_rounded,
                          color: context.saas.bgApp,
                          size: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Diálogo crear carpeta ────────────────────────────────────────────────────

class _CreateFolderDialog extends StatefulWidget {
  final String? parentPath;
  const _CreateFolderDialog({this.parentPath});

  @override
  State<_CreateFolderDialog> createState() => _CreateFolderDialogState();
}

class _CreateFolderDialogState extends State<_CreateFolderDialog> {
  late final TextEditingController _ctrl;
  final _formKey = GlobalKey<FormState>();

  static final _validPath =
      RegExp(r'^[a-zA-Z0-9_-]+(\/[a-zA-Z0-9_-]+)*$');

  @override
  void initState() {
    super.initState();
    final prefix =
        widget.parentPath != null ? '${widget.parentPath}/' : '';
    _ctrl = TextEditingController(text: prefix)
      ..selection = TextSelection.collapsed(offset: prefix.length);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_ctrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: context.saas.bgApp,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            context.saas.brand600.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.create_new_folder_rounded,
                          color: context.saas.brand600, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.parentPath != null
                          ? 'Nueva subcarpeta'
                          : 'Nueva carpeta',
                      style: TextStyle(
                        color: context.saas.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Ruta',
                  style: TextStyle(
                    color: context.saas.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _ctrl,
                  autofocus: true,
                  maxLength: 200,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: widget.parentPath != null
                        ? '${widget.parentPath}/nombre'
                        : 'ej. tours/colombia-2026',
                    hintStyle: TextStyle(
                        color: context.saas.textTertiary, fontSize: 13),
                    counterText: '',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: context.saas.border)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: context.saas.border)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: context.saas.brand600, width: 1.5)),
                    errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: context.saas.danger)),
                    focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: context.saas.danger, width: 1.5)),
                  ),
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'La ruta es requerida';
                    if (!_validPath.hasMatch(val)) {
                      return 'Solo letras, números, guiones, _ y /';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  'Usa / para crear subcarpetas  ·  Solo letras, números, - y _',
                  style: TextStyle(
                      color: context.saas.textTertiary, fontSize: 11),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.saas.textSecondary,
                          side: BorderSide(color: context.saas.border),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancelar',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submit,
                        style: FilledButton.styleFrom(
                          backgroundColor: context.saas.brand600,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Crear',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  static String _shortName(String f) {
    final parts = f.split('-');
    if (parts.length > 1 &&
        int.tryParse(parts.first) != null &&
        parts.first.length >= 10) {
      return parts.skip(1).join('-');
    }
    return f;
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
            color: context.saas.bgApp,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? context.saas.brand600
                  : _hovered
                  ? const Color(0xFFCBD5E1)
                  : context.saas.border,
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? context.saas.brand600.withValues(alpha: 0.12)
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
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AuthNetworkImage(url: widget.image.url),
                      AnimatedOpacity(
                        opacity:
                            _hovered && !widget.isSelected ? 0.08 : 0.0,
                        duration: const Duration(milliseconds: 120),
                        child: Container(color: Colors.black),
                      ),
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
                              child:  Icon(Icons.zoom_in_rounded,
                                  color: context.saas.bgApp, size: 20),
                            ),
                          ),
                        ),
                      ),
                      if (widget.isSelected)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: context.saas.brand600,
                              shape: BoxShape.circle,
                            ),
                            child:  Icon(Icons.check_rounded,
                                color: context.saas.bgApp, size: 14),
                          ),
                        ),
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
                                  color: context.saas.danger
                                      .withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child:  Icon(
                                    Icons.delete_outline_rounded,
                                    color: context.saas.bgApp,
                                    size: 14),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: context.saas.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _shortName(widget.image.filename),
                        style: TextStyle(
                          color: context.saas.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        _formatDate(widget.image.uploadedAt),
                        style: TextStyle(
                            color: context.saas.textTertiary, fontSize: 10),
                      ),
                      const SizedBox(height: 5),
                      _SmallActionButton(
                        icon: Icons.link_rounded,
                        label: 'Copiar URL',
                        onTap: widget.onCopyUrl,
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
          color: context.saas.bgSubtle,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: context.saas.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: context.saas.textSecondary),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: context.saas.textSecondary,
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

// ─── Diálogo previsualización ─────────────────────────────────────────────────

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
    if (parts.length > 1 &&
        int.tryParse(parts.first) != null &&
        parts.first.length >= 10) {
      return parts.skip(1).join('-');
    }
    return f;
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    final w = math.min(s.width - 48.0, 920.0);
    final h = math.min(s.height * 0.92, 700.0);

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
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                color: const Color(0xFF1A1A2E),
                child: Row(
                  children: [
                    const Icon(Icons.photo_rounded,
                        color: Colors.white54, size: 17),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _shortName(image.filename),
                        style:  TextStyle(
                            color: context.saas.bgApp,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context, rootNavigator: true).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white60,
                      iconSize: 20,
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Imagen
              Expanded(
                child: Container(
                  color: const Color(0xFF0D0D1A),
                  padding: const EdgeInsets.all(12),
                  child: AuthNetworkImage(
                      url: image.url, fit: BoxFit.contain),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                color: const Color(0xFF1A1A2E),
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    final narrow = constraints.maxWidth < 480;

                    final meta = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (image.uploadedAt != null) ...[
                          const Icon(Icons.schedule_rounded,
                              size: 12, color: Colors.white38),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yyyy')
                                .format(image.uploadedAt!),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (image.folder.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white12,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              image.folder.split('/').join(' / '),
                              style: const TextStyle(
                                  color: Colors.white60, fontSize: 11),
                            ),
                          ),
                      ],
                    );

                    final actions = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context, rootNavigator: true)
                                .pop();
                            onCopyUrl();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white70,
                            side: const BorderSide(color: Colors.white24),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.link_rounded, size: 14),
                          label: const Text('Copiar URL',
                              style: TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: onUse,
                          style: FilledButton.styleFrom(
                            backgroundColor: context.saas.brand600,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 9),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.check_rounded, size: 14),
                          label: const Text('Usar imagen',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    );

                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          meta,
                          const SizedBox(height: 10),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [actions]),
                        ],
                      );
                    }
                    return Row(
                        children: [meta, const Spacer(), actions]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Diálogo confirmación eliminación de carpeta ─────────────────────────────

class _ConfirmDeleteFolderDialog extends StatelessWidget {
  final String folder;
  const _ConfirmDeleteFolderDialog({required this.folder});

  @override
  Widget build(BuildContext context) {
    final leafName = folder.split('/').last;
    final isNested = folder.contains('/');

    return Dialog(
      backgroundColor: context.saas.bgApp,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.saas.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.folder_delete_outlined,
                    color: context.saas.danger, size: 28),
              ),
              const SizedBox(height: 18),
              Text(
                '¿Eliminar carpeta "$leafName"?',
                style: TextStyle(
                    color: context.saas.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                isNested
                    ? 'Se eliminarán permanentemente esta subcarpeta y todas las imágenes que contiene.\nEsta acción no se puede deshacer.'
                    : 'Se eliminarán permanentemente esta carpeta, todas sus subcarpetas e imágenes.\nEsta acción no se puede deshacer.',
                style: TextStyle(
                    color: context.saas.textSecondary,
                    fontSize: 13,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.saas.danger.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: context.saas.danger.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: context.saas.danger, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        folder,
                        style: TextStyle(
                            color: context.saas.danger,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.saas.textSecondary,
                        side: BorderSide(color: context.saas.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.saas.danger,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_delete_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Eliminar todo',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
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

// ─── Diálogo confirmación de eliminación de imagen ────────────────────────────

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
      backgroundColor: context.saas.bgApp,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: context.saas.danger.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_outline_rounded,
                    color: context.saas.danger, size: 28),
              ),
              const SizedBox(height: 18),
              Text('¿Eliminar imagen?',
                  style: TextStyle(
                      color: context.saas.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Se eliminará permanentemente\n"${_shortName(filename)}".\nEsta acción no se puede deshacer.',
                style: TextStyle(
                    color: context.saas.textSecondary,
                    fontSize: 13,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.saas.textSecondary,
                        side: BorderSide(color: context.saas.border),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancelar',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: context.saas.danger,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Eliminar',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
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
