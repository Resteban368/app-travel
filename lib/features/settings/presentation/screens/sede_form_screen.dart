import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/sede.dart';
import '../bloc/sede_bloc.dart';

class SedeFormScreen extends StatefulWidget {
  final Sede? sede;
  const SedeFormScreen({super.key, this.sede});

  @override
  State<SedeFormScreen> createState() => _SedeFormScreenState();
}

class _SedeFormScreenState extends State<SedeFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _mapsLinkCtrl;
  bool _isActive = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.sede != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.sede?.nombreSede ?? '');
    _phoneCtrl = TextEditingController(text: widget.sede?.telefono ?? '');
    _addressCtrl = TextEditingController(text: widget.sede?.direccion ?? '');
    _mapsLinkCtrl = TextEditingController(text: widget.sede?.linkMap ?? '');
    _isActive = widget.sede?.isActive ?? true;

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
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _mapsLinkCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    final id = _isEditing
        ? widget.sede!.id
        : DateTime.now().millisecondsSinceEpoch.toString();
    final sede = Sede(
      id: id,
      nombreSede: _nameCtrl.text.trim(),
      telefono: _phoneCtrl.text.trim(),
      direccion: _addressCtrl.text.trim(),
      linkMap: _mapsLinkCtrl.text.trim(),
      isActive: _isActive,
    );
    if (_isEditing) {
      context.read<SedeBloc>().add(UpdateSede(sede));
    } else {
      context.read<SedeBloc>().add(CreateSede(sede));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SedeBloc>(),
      child: BlocListener<SedeBloc, SedeState>(
        listener: (context, state) {
          if (state is SedeSaved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isEditing ? 'Sede actualizada' : 'Sede creada'),
                backgroundColor: D.emerald,
                behavior: SnackBarBehavior.floating,
              ),
            );
            Navigator.pop(context, true);
          } else if (state is SedeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: D.rose,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: D.bg,
          body: Stack(
            children: [
              // Fondo premium glassmorphism
              const PremiumBackground(),

              // Contenido con encabezado colapsable
              CustomScrollView(
                slivers: [
                  PremiumSliverAppBar(
                    actions: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: D.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    title: _isEditing
                        ? 'Editar Punto de Atención'
                        : 'Nueva Sede Oficial',
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
                                    // ── Sección: Información General ──
                                    PremiumSectionCard(
                                      title: 'INFORMACIÓN GENERAL',
                                      icon: Icons.store_rounded,
                                      children: [
                                        PremiumTextField(
                                          controller: _nameCtrl,
                                          label: 'Nombre de la Sede *',
                                          icon: Icons.store_rounded,
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: PremiumTextField(
                                                controller: _phoneCtrl,
                                                label: 'Teléfono Contacto *',
                                                icon: Icons.phone_rounded,
                                                isNumeric: true,
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Expanded(
                                              child: PremiumTextField(
                                                controller: _mapsLinkCtrl,
                                                label: 'Google Maps Link',
                                                icon: Icons.map_rounded,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        PremiumTextField(
                                          controller: _addressCtrl,
                                          label: 'Dirección Exacta *',
                                          icon: Icons.place_rounded,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),

                                    // ── Sección: Operatividad ──
                                    PremiumSectionCard(
                                      title: 'OPERATIVIDAD',
                                      icon: Icons.toggle_on_rounded,
                                      children: [_buildVisibilitySwitch()],
                                    ),
                                    const SizedBox(height: 48),

                                    // ── Botón de guardado ──
                                    Builder(
                                      builder: (ctx) =>
                                          BlocBuilder<SedeBloc, SedeState>(
                                            builder: (context, state) {
                                              return PremiumActionButton(
                                                label: 'GUARDAR CAMBIOS',
                                                icon: Icons.save_rounded,
                                                isLoading: state is SedeSaving,
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
      ),
    );
  }

  Widget _buildVisibilitySwitch() {
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
              'Visibilidad Pública',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _isActive
                  ? 'La sede aparecerá en la aplicación para clientes.'
                  : 'Sede oculta temporalmente.',
              style: const TextStyle(color: D.slate400, fontSize: 12),
            ),
            value: _isActive,
            activeColor: D.emerald,
            activeTrackColor: D.emerald.withOpacity(0.3),
            inactiveThumbColor: D.slate400,
            inactiveTrackColor: D.bg.withOpacity(0.5),
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ),
      ),
    );
  }
}
