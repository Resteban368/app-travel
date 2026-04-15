import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/settings/domain/entities/sede.dart';
import '../../../../features/settings/presentation/bloc/sede_bloc.dart';
import '../../domain/entities/catalogue.dart';
import '../bloc/catalogue_bloc.dart';
import '../bloc/catalogue_event.dart';
import '../bloc/catalogue_state.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/widgets/premium_form_widgets.dart';

class CatalogueFormScreen extends StatefulWidget {
  final Catalogue? catalogue;
  const CatalogueFormScreen({super.key, this.catalogue});

  @override
  State<CatalogueFormScreen> createState() => _CatalogueFormScreenState();
}

class _CatalogueFormScreenState extends State<CatalogueFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  int? _selectedSedeId;
  bool _isActive = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.catalogue != null;

  @override
  void initState() {
    super.initState();
    final c = widget.catalogue;
    _nameCtrl = TextEditingController(text: c?.nombreCatalogue ?? '');
    _urlCtrl = TextEditingController(text: c?.urlArchivo ?? '');
    _selectedSedeId = c?.idSede;
    _isActive = c?.activo ?? true;

    context.read<SedeBloc>().add(LoadSedes());

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
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSedeId == null) {
      _showToast(context, 'Por favor, selecciona una sede', isError: true);
      return;
    }

    final catalogue = Catalogue(
      idCatalogue: _isEditing ? widget.catalogue!.idCatalogue : 0,
      idSede: _selectedSedeId!,
      nombreCatalogue: _nameCtrl.text.trim(),
      urlArchivo: _urlCtrl.text.trim(),
      activo: _isActive,
      fechaCreacion: _isEditing
          ? widget.catalogue!.fechaCreacion
          : DateTime.now(),
    );

    if (_isEditing) {
      context.read<CatalogueBloc>().add(UpdateCatalogue(catalogue));
    } else {
      context.read<CatalogueBloc>().add(CreateCatalogue(catalogue));
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
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('catalogues')
        : true;

    return BlocListener<CatalogueBloc, CatalogueState>(
      listener: (context, state) {
        if (state is CatalogueSaved) {
          _showToast(
            context,
            _isEditing ? 'Catálogo actualizado' : 'Catálogo creado',
          );
          Navigator.pop(context);
        } else if (state is CatalogueError) {
          _showToast(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        body: Stack(
          children: [
            const PremiumBackground(),
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _isEditing && !canWrite
                      ? 'Ver Catálogo'
                      : (_isEditing ? 'Editar Catálogo' : 'Nuevo Catálogo'),
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
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
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
                                          Icons.info_outline_rounded,
                                          color: D.skyBlue,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Completa los detalles del PDF',
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
                                    title: 'INFORMACIÓN DEL CATÁLOGO',
                                    icon: Icons.auto_stories_rounded,
                                    children: [
                                      PremiumTextField(
                                        controller: _nameCtrl,
                                        label: 'Nombre del Catálogo *',
                                        icon: Icons.title_rounded,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      PremiumTextField(
                                        controller: _urlCtrl,
                                        label: 'URL del Archivo (PDF) *',
                                        icon: Icons.link_rounded,
                                        readOnly: !canWrite,
                                      ),
                                      const SizedBox(height: 20),
                                      _buildSedeDropdown(canWrite: canWrite),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  PremiumSectionCard(
                                    title: 'VISIBILIDAD',
                                    icon: Icons.visibility_rounded,
                                    children: [
                                      _buildVisibilitySwitch(
                                        canWrite: canWrite,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 48),

                                  if (canWrite)
                                    Builder(
                                      builder: (ctx) =>
                                          BlocBuilder<
                                            CatalogueBloc,
                                            CatalogueState
                                          >(
                                            builder: (context, state) {
                                              return PremiumActionButton(
                                                label: _isEditing
                                                    ? 'ACTUALIZAR CATÁLOGO'
                                                    : 'CREAR CATÁLOGO',
                                                icon: Icons.save_rounded,
                                                isLoading:
                                                    state is CatalogueSaving,
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
                'SEDE / SUCURSAL *',
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

        List<Sede> sedes = [];
        if (state is SedesLoaded) {
          sedes = state.sedes;
        } else if (state is SedeSaved && state.sedes != null) {
          sedes = state.sedes!;
        } else if (state is SedeSaving && state.sedes != null) {
          sedes = state.sedes!;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SEDE / SUCURSAL *',
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
                      Icons.business_rounded,
                      color: D.skyBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      sedes
                          .firstWhere(
                            (s) => int.tryParse(s.id) == _selectedSedeId,
                            orElse: () => Sede(
                              id: '0',
                              nombreSede: 'Desconocido',
                              telefono: '',
                              direccion: '',
                              isActive: false,
                              linkMap: '',
                            ),
                          )
                          .nombreSede,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              )
            else
              DropdownButtonFormField<int>(
                value: sedes.any((s) => int.tryParse(s.id) == _selectedSedeId)
                    ? _selectedSedeId
                    : null,
                dropdownColor: D.surfaceHigh,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.business_rounded,
                    color: D.skyBlue,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: D.surfaceHigh.withOpacity(0.5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.05),
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

  Widget _buildVisibilitySwitch({required bool canWrite}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: D.surfaceHigh.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: SwitchListTile(
            title: const Text(
              'Estado del Catálogo',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _isActive ? 'Activo y visible' : 'Oculto para usuarios',
              style: const TextStyle(color: D.slate400, fontSize: 12),
            ),
            value: _isActive,
            activeColor: D.emerald,
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
