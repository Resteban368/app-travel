import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/hotel.dart';
import '../bloc/hotel_bloc.dart';
import '../bloc/hotel_event.dart';
import '../bloc/hotel_state.dart';

class HotelFormScreen extends StatefulWidget {
  final Hotel? hotel;
  const HotelFormScreen({super.key, this.hotel});

  @override
  State<HotelFormScreen> createState() => _HotelFormScreenState();
}

class _HotelFormScreenState extends State<HotelFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _direccionCtrl;
  late bool _isActive;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.hotel != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.hotel?.nombre ?? '');
    _ciudadCtrl = TextEditingController(text: widget.hotel?.ciudad ?? '');
    _telefonoCtrl = TextEditingController(text: widget.hotel?.telefono ?? '');
    _direccionCtrl = TextEditingController(text: widget.hotel?.direccion ?? '');
    _isActive = widget.hotel?.isActive ?? true;

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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
    _nombreCtrl.dispose();
    _ciudadCtrl.dispose();
    _telefonoCtrl.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? SaasPalette.danger : SaasPalette.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSave(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final hotel = Hotel(
      id: widget.hotel?.id,
      nombre: _nombreCtrl.text.trim(),
      ciudad: _ciudadCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      direccion: _direccionCtrl.text.trim(),
      isActive: _isActive,
    );

    if (_isEditing) {
      context.read<HotelBloc>().add(UpdateHotel(hotel));
    } else {
      context.read<HotelBloc>().add(CreateHotel(hotel));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('hoteles')
        : false;

    return BlocListener<HotelBloc, HotelState>(
      listener: (context, state) {
        if (state is HotelSaved) {
          _showMsg(_isEditing ? 'Hotel actualizado' : 'Hotel creado');
          Navigator.pop(context);
        } else if (state is HotelError) {
          _showMsg(state.message, isError: true);
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            PremiumSliverAppBar(
              title: _isEditing && !canWrite
                  ? 'Ver Hotel'
                  : (_isEditing ? 'Editar Hotel' : 'Nuevo Hotel'),
              actions: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
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
                            // Etiqueta
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: SaasPalette.brand50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: SaasPalette.brand600.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.hotel_rounded,
                                    color: SaasPalette.brand600,
                                    size: 16,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'DATOS DEL HOTEL',
                                    style: TextStyle(
                                      color: SaasPalette.brand600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            PremiumSectionCard(
                              title: 'INFORMACIÓN GENERAL',
                              icon: Icons.hotel_rounded,
                              children: [
                                PremiumTextField(
                                  controller: _nombreCtrl,
                                  label: 'Nombre del Hotel *',
                                  icon: Icons.hotel_rounded,
                                  readOnly: !canWrite,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'El nombre es requerido'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _ciudadCtrl,
                                  label: 'Ciudad *',
                                  icon: Icons.location_city_rounded,
                                  readOnly: !canWrite,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'La ciudad es requerida'
                                      : null,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _telefonoCtrl,
                                  label: 'Teléfono (opcional)',
                                  icon: Icons.phone_rounded,
                                  isNumeric: true,
                                  readOnly: !canWrite,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _direccionCtrl,
                                  label: 'Dirección (opcional)',
                                  icon: Icons.location_on_rounded,
                                  readOnly: !canWrite,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            if (_isEditing)
                              PremiumSectionCard(
                                title: 'ESTADO',
                                icon: Icons.toggle_on_rounded,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: SaasPalette.bgSubtle,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: SaasPalette.border,
                                      ),
                                    ),
                                    child: SwitchListTile(
                                      title: const Text(
                                        'Hotel Activo',
                                        style: TextStyle(
                                          color: SaasPalette.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        'Disponible para asignar a reservas',
                                        style: TextStyle(
                                          color: SaasPalette.textTertiary,
                                          fontSize: 12,
                                        ),
                                      ),
                                      value: _isActive,
                                      activeThumbColor: SaasPalette.success,
                                      activeTrackColor: SaasPalette.success
                                          .withValues(alpha: 0.25),
                                      inactiveThumbColor:
                                          SaasPalette.textTertiary,
                                      inactiveTrackColor: SaasPalette.bgSubtle,
                                      onChanged: canWrite
                                          ? (v) => setState(() => _isActive = v)
                                          : null,
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 48),

                            if (canWrite)
                              Builder(
                                builder: (ctx) =>
                                    BlocBuilder<HotelBloc, HotelState>(
                                      builder: (context, state) =>
                                          PremiumActionButton(
                                            label: _isEditing
                                                ? 'GUARDAR CAMBIOS'
                                                : 'CREAR HOTEL',
                                            icon: Icons.save_rounded,
                                            isLoading: state is HotelSaving,
                                            onTap: () => _onSave(ctx),
                                          ),
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
      ),
    );
  }
}
