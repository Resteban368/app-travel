import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/cotizacion.dart';
import '../bloc/cotizacion_bloc.dart';
import '../bloc/cotizacion_event.dart';
import '../bloc/cotizacion_state.dart';

class CotizacionFormScreen extends StatefulWidget {
  final Cotizacion? cotizacion;
  const CotizacionFormScreen({super.key, this.cotizacion});

  @override
  State<CotizacionFormScreen> createState() => _CotizacionFormScreenState();
}

class _CotizacionFormScreenState extends State<CotizacionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _chatIdCtrl = TextEditingController();
  final _detallesPlanCtrl = TextEditingController();
  final _origenDestinoCtrl = TextEditingController();
  final _especificacionesCtrl = TextEditingController();
  final _edadesMenoresCtrl = TextEditingController();
  final _numeroPasajerosCtrl = TextEditingController(text: '1');

  DateTime? _fechaSalida;
  DateTime? _fechaRegreso;
  String _estado = 'pendiente';

  @override
  void initState() {
    super.initState();
    if (widget.cotizacion != null) {
      final c = widget.cotizacion!;
      _nombreCtrl.text = c.nombreCompleto;
      _correoCtrl.text = c.correoElectronico ?? '';
      _chatIdCtrl.text = c.chatId;
      _detallesPlanCtrl.text = c.detallesPlan;
      _origenDestinoCtrl.text = c.origenDestino ?? '';
      _especificacionesCtrl.text = c.especificaciones ?? '';
      _edadesMenoresCtrl.text = c.edadesMenuores ?? '';
      _numeroPasajerosCtrl.text = c.numeroPasajeros.toString();
      _estado = c.estado;
      if (c.fechaSalida != null) _fechaSalida = DateTime.parse(c.fechaSalida!);
      if (c.fechaRegreso != null) {
        _fechaRegreso = DateTime.parse(c.fechaRegreso!);
      }
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _correoCtrl.dispose();
    _chatIdCtrl.dispose();
    _detallesPlanCtrl.dispose();
    _origenDestinoCtrl.dispose();
    _especificacionesCtrl.dispose();
    _edadesMenoresCtrl.dispose();
    _numeroPasajerosCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFecha({required bool esSalida}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: SaasPalette.brand600,
            onPrimary: Colors.white,
            surface: SaasPalette.bgCanvas,
            onSurface: SaasPalette.textPrimary,
          ), dialogTheme: DialogThemeData(backgroundColor: SaasPalette.bgCanvas),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (esSalida) {
          _fechaSalida = picked;
        } else {
          _fechaRegreso = picked;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final cotizacion = Cotizacion(
      id: widget.cotizacion?.id ?? 0,
      chatId: _chatIdCtrl.text.trim(),
      nombreCompleto: _nombreCtrl.text.trim(),
      correoElectronico: _correoCtrl.text.trim().isEmpty
          ? null
          : _correoCtrl.text.trim(),
      detallesPlan: _detallesPlanCtrl.text.trim(),
      numeroPasajeros: int.tryParse(_numeroPasajerosCtrl.text.trim()) ?? 1,
      fechaSalida: _fechaSalida?.toIso8601String().split('T').first,
      fechaRegreso: _fechaRegreso?.toIso8601String().split('T').first,
      origenDestino: _origenDestinoCtrl.text.trim().isEmpty
          ? null
          : _origenDestinoCtrl.text.trim(),
      edadesMenuores: _edadesMenoresCtrl.text.trim().isEmpty
          ? null
          : _edadesMenoresCtrl.text.trim(),
      especificaciones: _especificacionesCtrl.text.trim().isEmpty
          ? null
          : _especificacionesCtrl.text.trim(),
      estado: _estado,
      isRead: widget.cotizacion?.isRead ?? true,
      createdAt: widget.cotizacion?.createdAt ?? DateTime.now(),
    );

    if (widget.cotizacion != null) {
      context.read<CotizacionBloc>().add(UpdateCotizacion(cotizacion));
    } else {
      context.read<CotizacionBloc>().add(CreateCotizacion(cotizacion));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CotizacionBloc, CotizacionState>(
      listener: (context, state) {
        if (state is CotizacionSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cotización guardada exitosamente'),
              backgroundColor: SaasPalette.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context, true);
        } else if (state is CotizacionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: SaasPalette.danger,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: widget.cotizacion != null
                      ? 'Editar Cotización'
                      : 'Nueva Cotización',
                  actions: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
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
                            PremiumSectionCard(
                              title: 'DATOS DEL CLIENTE',
                              icon: Icons.person_rounded,
                              children: [
                                PremiumTextField(
                                  controller: _nombreCtrl,
                                  label: 'Nombre Completo *',
                                  icon: Icons.badge_rounded,
                                  keyboardType: TextInputType.text,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _chatIdCtrl,
                                  label: 'Número de WhatsApp *',
                                  icon: Icons.phone_android_rounded,
                                  keyboardType: TextInputType.number,
                                  isNumeric: true,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _correoCtrl,
                                  label: 'Correo Electrónico',
                                  icon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            PremiumSectionCard(
                              title: 'DETALLES DEL VIAJE',
                              icon: Icons.flight_takeoff_rounded,
                              children: [
                                PremiumTextField(
                                  controller: _detallesPlanCtrl,
                                  label: 'Plan / Destino *',
                                  icon: Icons.map_rounded,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 20),
                                PremiumTextField(
                                  controller: _origenDestinoCtrl,
                                  label: 'Origen → Destino',
                                  icon: Icons.route_rounded,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DatePickerPremium(
                                        label: 'Salida',
                                        date: _fechaSalida,
                                        onTap: () => _pickFecha(esSalida: true),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _DatePickerPremium(
                                        label: 'Regreso',
                                        date: _fechaRegreso,
                                        onTap: () =>
                                            _pickFecha(esSalida: false),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: PremiumTextField(
                                        controller: _numeroPasajerosCtrl,
                                        label: 'N° Pasajeros *',
                                        icon: Icons.people_alt_rounded,
                                        isNumeric: true,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Requerido';
                                          }
                                          if ((int.tryParse(v) ?? 0) < 1) {
                                            return 'Mínimo 1';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: PremiumTextField(
                                        controller: _edadesMenoresCtrl,
                                        label: 'Edades Menores',
                                        icon: Icons.child_care_rounded,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            PremiumSectionCard(
                              title: 'NOTAS Y ESTADO',
                              icon: Icons.edit_note_rounded,
                              children: [
                                PremiumTextField(
                                  controller: _especificacionesCtrl,
                                  label: 'Especificaciones / Notas',
                                  icon: Icons.notes_rounded,
                                  maxLines: 5,
                                ),
                                const SizedBox(height: 20),
                                _StatusDropdownPremium(
                                  value: _estado,
                                  onChanged: (v) =>
                                      setState(() => _estado = v ?? _estado),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            BlocBuilder<CotizacionBloc, CotizacionState>(
                              builder: (context, state) {
                                return PremiumActionButton(
                                  label: widget.cotizacion != null
                                      ? 'ACTUALIZAR COTIZACIÓN'
                                      : 'GUARDAR COTIZACIÓN',
                                  icon: Icons.save_rounded,
                                  isLoading: state is CotizacionSaving,
                                  onTap: _save,
                                );
                              },
                            ),
                            const SizedBox(height: 100),
                          ],
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
}

class _DatePickerPremium extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerPremium({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    final text = hasDate
        ? '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}'
        : 'Seleccionar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: SaasPalette.bgCanvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDate ? SaasPalette.brand600 : SaasPalette.border,
                width: hasDate ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: hasDate
                      ? SaasPalette.brand600
                      : SaasPalette.textTertiary,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      color: hasDate
                          ? SaasPalette.textPrimary
                          : SaasPalette.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusDropdownPremium extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _StatusDropdownPremium({required this.value, required this.onChanged});

  static const _estados = ['pendiente', 'atendida', 'cancelada'];

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Estado Inicial',
          style: TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SaasPalette.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: SaasPalette.bgCanvas,
              icon: Icon(Icons.arrow_drop_down_rounded, color: color, size: 28),
              isExpanded: true,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
              onChanged: onChanged,
              items: _estados.map<DropdownMenuItem<String>>((String val) {
                final itemColor = _getStatusColor(val);
                return DropdownMenuItem<String>(
                  value: val,
                  child: Text(
                    val.toUpperCase(),
                    style: TextStyle(
                      color: itemColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'atendida':
        return SaasPalette.success;
      case 'cancelada':
        return SaasPalette.danger;
      default:
        return Colors.amber.shade700;
    }
  }
}
