import 'dart:ui';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/politica_reserva.dart';
import '../bloc/politica_reserva_bloc.dart';
import '../bloc/politica_reserva_event.dart';
import '../bloc/politica_reserva_state.dart';
import '../../../../core/widgets/premium_form_widgets.dart';

class PoliticaReservaFormScreen extends StatefulWidget {
  final PoliticaReserva? politica;
  const PoliticaReservaFormScreen({super.key, this.politica});

  @override
  State<PoliticaReservaFormScreen> createState() =>
      _PoliticaReservaFormScreenState();
}

class _PoliticaReservaFormScreenState extends State<PoliticaReservaFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloCtrl;
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _tipoCtrl;
  bool _activo = true;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.politica != null;

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController(text: widget.politica?.titulo ?? '');
    _descripcionCtrl = TextEditingController(
      text: widget.politica?.descripcion ?? '',
    );
    _tipoCtrl = TextEditingController(
      text: widget.politica?.tipoPolitica ?? '',
    );
    _activo = widget.politica?.activo ?? true;

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
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _tipoCtrl.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    //VALIDAMOS QUE TENGA EL TITULO
    if (_tituloCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El título es requerido');
      return;
    }

    //VALIDAMOS QUE TENGA LA DESCRIPCIÓN
    if (_descripcionCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'La descripción es requerida');
      return;
    }

    //VALIDAMOS QUE TENGA EL TIPO DE POLÍTICA
    if (_tipoCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El tipo de política es requerido');
      return;
    }

    final politica = PoliticaReserva(
      id: _isEditing ? widget.politica!.id : 0,
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      tipoPolitica: _tipoCtrl.text.trim(),
      activo: _activo,
      fechaCreacion: _isEditing ? widget.politica!.fechaCreacion : null,
    );

    if (_isEditing) {
      context.read<PoliticaReservaBloc>().add(UpdatePolitica(politica));
    } else {
      context.read<PoliticaReservaBloc>().add(CreatePolitica(politica));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final isAdmin =
        authState is AuthAuthenticated && authState.user.role == 'admin';
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('politicasReserva')
        : isAdmin;

    return BlocListener<PoliticaReservaBloc, PoliticaReservaState>(
      listener: (context, state) {
        if (state is PoliticaSaved) {
          SaasSnackBar.showSuccess(
            context,
            _isEditing
                ? 'Política actualizada con éxito'
                : 'Nueva política registrada',
          );
          Navigator.pop(context);
        } else if (state is PoliticaError) {
          SaasSnackBar.showError(context, state.message);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _isEditing && !canWrite
                      ? 'Ver Política'
                      : (_isEditing ? 'Configurar Política' : 'Nueva Política'),
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
                                        Icons.policy_rounded,
                                        color: D.skyBlue,
                                        size: 16,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'GESTIÓN DE POLÍTICA',
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
                                  title: 'DETALLES DE LA POLÍTICA',
                                  icon: Icons.description_outlined,
                                  children: [
                                    PremiumTextField(
                                      controller: _tituloCtrl,
                                      label: 'Título Principal *',
                                      icon: Icons.title_rounded,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _tipoCtrl,
                                      label: 'Tipo de Política (Categoría) *',
                                      icon: Icons.category_rounded,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _descripcionCtrl,
                                      label: 'Descripción Detallada *',
                                      icon: Icons.notes_rounded,
                                      maxLines: 6,
                                      readOnly: !canWrite,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                PremiumSectionCard(
                                  title: 'ESTADO DE LA POLÍTICA',
                                  icon: Icons.security_rounded,
                                  children: [
                                    _buildVisibilitySwitch(canWrite: canWrite),
                                  ],
                                ),
                                const SizedBox(height: 48),

                                if (canWrite)
                                  Builder(
                                    builder: (ctx) =>
                                        BlocBuilder<
                                          PoliticaReservaBloc,
                                          PoliticaReservaState
                                        >(
                                          builder: (context, state) {
                                            return PremiumActionButton(
                                              label: _isEditing
                                                  ? 'ACTUALIZAR POLÍTICA'
                                                  : 'GUARDAR POLÍTICA',
                                              icon: Icons.save_rounded,
                                              isLoading:
                                                  state is PoliticaSaving,
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
              'Habilitar Política',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              _activo ? 'Visible en el sistema' : 'Oculta actualmente',
              style: const TextStyle(color: D.slate400, fontSize: 12),
            ),
            value: _activo,
            activeThumbColor: D.emerald,
            activeTrackColor: D.emerald.withOpacity(0.3),
            inactiveThumbColor: D.slate400,
            inactiveTrackColor: D.bg.withOpacity(0.5),
            onChanged: canWrite ? (v) => setState(() => _activo = v) : null,
          ),
        ),
      ),
    );
  }
}
