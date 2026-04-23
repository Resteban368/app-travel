import 'dart:ui';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/service.dart';
import '../bloc/service_bloc.dart';
import '../bloc/service_event.dart';
import '../bloc/service_state.dart';
import '../../../settings/presentation/bloc/sede_bloc.dart';
import '../../../../core/widgets/premium_form_widgets.dart';

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
    super.dispose();
  }

  void _save(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final service = Service(
      id: _isEditing ? widget.service!.id : 0,
      name: _nameCtrl.text.trim(),
      cost: double.tryParse(_costCtrl.text.trim()),
      description: _descriptionCtrl.text.trim(),
      idSede: _selectedSedeId ?? 0,
      isActive: _isActive,
      createdAt: _isEditing ? widget.service!.createdAt : DateTime.now(),
    );

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
                                      label: 'Costo Monetario',
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
                value: sedes.any((s) => int.tryParse(s.id) == _selectedSedeId)
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
