import 'dart:ui';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/service.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';
import '../../../settings/presentation/bloc/sede_bloc.dart';
import '../../../../core/widgets/auth_network_image.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../../gallery/presentation/widgets/gallery_picker_dialog.dart';

class ServiceFormScreen extends StatefulWidget {
  final Service? service;
  const ServiceFormScreen({super.key, this.service});

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _descriptionCtrl;
  int? _selectedSedeId;
  bool _isActive = true;
  List<String> _imagenes = [];
  final _imagenCtrl = TextEditingController();

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.service?.name ?? '');
    _costCtrl = TextEditingController(
      text: widget.service?.cost?.toString() ?? '',
    );
    _descriptionCtrl = TextEditingController(
      text: widget.service?.description ?? '',
    );
    _selectedSedeId = widget.service?.idSede;
    _isActive = widget.service?.isActive ?? true;
    _imagenes = List.from(widget.service?.imagenes ?? []);

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SedeBloc>().add(LoadSedes());
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _costCtrl.dispose();
    _descriptionCtrl.dispose();
    _imagenCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    //VALIDAMOS QUE TENGA EL NOMBRE DEL SERVICIO
    if (_nameCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El nombre del servicio es requerido');
      return;
    }

    //VALIDAMOS QUE TENGA EL COSTO DEL SERVICIO
    if (_costCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El costo del servicio es requerido');
      return;
    }

    //VALIDAMOS QUE TENGA LA DESCRIPCIÓN DEL SERVICIO
    if (_descriptionCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(
        context,
        'La descripción del servicio es requerida',
      );
      return;
    }

    //VALIDAMOS QUE TENGA LA SEDE
    if (_selectedSedeId == null) {
      SaasSnackBar.showWarning(context, 'La sede es requerida');
      return;
    }

    final service = Service(
      id: _isEditing ? widget.service!.id : 0,
      name: _nameCtrl.text.trim(),
      cost: double.tryParse(_costCtrl.text.trim()),
      description: _descriptionCtrl.text.trim(),
      idSede: _selectedSedeId ?? 0,
      isActive: _isActive,
      createdAt: _isEditing ? widget.service!.createdAt : DateTime.now(),
      imagenes: List.from(_imagenes),
    );

    // ignore: avoid_print
    print('[ServiceForm] _save imagenes: ${service.imagenes}');
    // ignore: avoid_print
    print('[ServiceForm] _save isEditing: $_isEditing, id: ${service.id}');

    if (_isEditing) {
      context.read<ServiceBloc>().add(UpdateService(service));
    } else {
      context.read<ServiceBloc>().add(CreateService(service));
    }
  }

  void _showToast(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? D.rose : D.emerald,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.role == 'admin';
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('services')
        : isAdmin;

    return BlocListener<ServiceBloc, ServiceState>(
      listener: (context, state) {
        if (state is ServiceSaved) {
          _showToast(
            context,
            _isEditing ? 'Servicio actualizado' : 'Servicio creado',
          );
          Navigator.pop(context);
        } else if (state is ServiceError) {
          _showToast(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _isEditing && !canWrite
                      ? 'Ver Servicio'
                      : (_isEditing ? 'Editar Servicio' : 'Nuevo Servicio'),
                  actions: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        child: Center(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Etiqueta de información
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: D.skyBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: D.skyBlue.withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.label_important_rounded,
                                        color: D.skyBlue,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'DEFINICIÓN DE SERVICIO',
                                        style: TextStyle(
                                          color: D.skyBlue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                PremiumSectionCard(
                                  title: 'INFORMACIÓN BÁSICA',
                                  icon: Icons.room_service_rounded,
                                  children: [
                                    PremiumTextField(
                                      controller: _nameCtrl,
                                      label: 'Nombre del Servicio *',
                                      icon:
                                          Icons.label_important_outline_rounded,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildSedeDropdown(canWrite: canWrite),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _costCtrl,
                                      label: 'Costo Monetario *',
                                      icon: Icons.attach_money_rounded,
                                      isNumeric: true,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _descriptionCtrl,
                                      label: 'Descripción Detallada *',
                                      icon: Icons.description_outlined,
                                      maxLines: 3,
                                      readOnly: !canWrite,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                _buildImagenesSection(canWrite: canWrite),
                                const SizedBox(height: 24),

                                PremiumSectionCard(
                                  title: 'ESTADO Y VISIBILIDAD',
                                  icon: Icons.visibility_rounded,
                                  children: [
                                    _buildVisibilitySwitch(canWrite: canWrite),
                                  ],
                                ),
                                const SizedBox(height: 48),

                                if (canWrite)
                                  Builder(
                                    builder: (ctx) =>
                                        BlocBuilder<ServiceBloc, ServiceState>(
                                          builder: (context, state) {
                                            return PremiumActionButton(
                                              label: _isEditing
                                                  ? 'ACTUALIZAR SERVICIO'
                                                  : 'GUARDAR SERVICIO',
                                              icon: Icons.save_rounded,
                                              isLoading: state is ServiceSaving,
                                              onTap: () => _save(ctx),
                                            );
                                          },
                                        ),
                                  ),
                                const SizedBox(height: 100),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeDropdown({required bool canWrite}) {
    return BlocBuilder<SedeBloc, SedeState>(
      builder: (context, state) {
        if (state is SedeLoading || state is SedeInitial) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEDE ASOCIADA *',
                style: TextStyle(
                  color: D.slate400,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 16),
              CircularProgressIndicator(color: D.skyBlue),
            ],
          );
        }

        final sedes = (state is SedesLoaded)
            ? state.sedes
            : (state is SedeSaved && state.sedes != null)
            ? state.sedes!
            : (state is SedeSaving && state.sedes != null)
            ? state.sedes!
            : [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SEDE ASOCIADA *',
              style: TextStyle(
                color: D.slate400,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (!canWrite)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: D.surfaceHigh.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.store_rounded,
                      color: SaasPalette.brand600,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      sedes.any((s) => int.tryParse(s.id) == _selectedSedeId)
                          ? sedes
                                .firstWhere(
                                  (s) => int.tryParse(s.id) == _selectedSedeId,
                                )
                                .nombreSede
                          : 'Selecciona una sede',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<int>(
                initialValue:
                    sedes.any((s) => int.tryParse(s.id) == _selectedSedeId)
                    ? _selectedSedeId
                    : null,
                dropdownColor: D.white,
                style: const TextStyle(color: Colors.black, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.store_rounded,
                    color: SaasPalette.brand600,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: D.white,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.black.withOpacity(0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: D.skyBlue, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                items: sedes.map((s) {
                  return DropdownMenuItem(
                    value: int.tryParse(s.id) ?? 0,
                    child: Text(s.nombreSede),
                  );
                }).toList(),
                onChanged: canWrite
                    ? (val) => setState(() => _selectedSedeId = val)
                    : null,
                validator: (v) => v == null ? 'Selecciona una sede' : null,
              ),
          ],
        );
      },
    );
  }

  Widget _buildImagenesSection({required bool canWrite}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PremiumSectionHeader(
            title: 'IMÁGENES DEL SERVICIO',
            icon: Icons.photo_library_rounded,
          ),
          const SizedBox(height: 12),
          if (canWrite) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: PremiumTextField(
                    controller: _imagenCtrl,
                    label: 'URL de imagen (opcional)',
                    icon: Icons.link_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                _GaleriaBtn(
                  onPressed: () async {
                    final url = await GalleryPickerDialog.show(
                      context,
                      initialFolder: 'general',
                      isAdmin: true,
                    );
                    // ignore: avoid_print
                    print('[GaleriaBtn] gallery returned url: $url');
                    if (url != null && mounted) {
                      setState(() {
                        if (!_imagenes.contains(url)) _imagenes.add(url);
                        _imagenCtrl.clear();
                      });
                    }
                  },
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: TextButton.icon(
                    onPressed: _agregarImagen,
                    style: TextButton.styleFrom(
                      foregroundColor: SaasPalette.brand600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 11),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'AGREGAR',
                      style:
                          TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (_imagenes.isEmpty)
            const PremiumEmptyIndicator(
              msg: 'Sin imágenes — campo opcional.',
              icon: Icons.image_not_supported_rounded,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _imagenes
                  .asMap()
                  .entries
                  .map(
                    (e) => _ServiceImagePreviewCard(
                      url: e.value,
                      canDelete: canWrite,
                      onRemove: () => _confirmDeleteImagen(e.key),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  void _agregarImagen() {
    final url = _imagenCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() => _imagenes.add(url));
    _imagenCtrl.clear();
  }

  void _confirmDeleteImagen(int index) {
    _showDeleteDialog(
      title: 'Eliminar imagen',
      body: '¿Seguro que deseas eliminar esta imagen de la galería?',
      onConfirm: () => setState(() => _imagenes.removeAt(index)),
    );
  }

  void _showDeleteDialog({
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SaasPalette.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: const TextStyle(
            color: SaasPalette.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(color: SaasPalette.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: SaasPalette.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: SaasPalette.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilitySwitch({required bool canWrite}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: D.bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: SwitchListTile(
            title: const Text(
              'Servicio Activo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _isActive ? 'Visible en el sistema' : 'Oculto actualmente',
              style: const TextStyle(color: D.slate400, fontSize: 12),
            ),
            value: _isActive,
            activeThumbColor: D.emerald,
            activeTrackColor: D.emerald.withOpacity(0.3),
            inactiveThumbColor: D.slate400,
            inactiveTrackColor: D.bg.withOpacity(0.5),
            onChanged: canWrite ? (v) => setState(() => _isActive = v) : null,
          ),
        ),
      ),
    );
  }
}

class _GaleriaBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _GaleriaBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: SaasPalette.brand600),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_rounded,
                color: SaasPalette.brand600, size: 16),
            SizedBox(width: 5),
            Text(
              'Galería',
              style: TextStyle(
                color: SaasPalette.brand600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceImagePreviewCard extends StatelessWidget {
  final String url;
  final bool canDelete;
  final VoidCallback onRemove;

  const _ServiceImagePreviewCard({
    required this.url,
    required this.canDelete,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 110,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SaasPalette.border),
            color: SaasPalette.bgSubtle,
          ),
          clipBehavior: Clip.antiAlias,
          child: AuthNetworkImage(url: url, fit: BoxFit.cover),
        ),
        if (canDelete)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: SaasPalette.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
