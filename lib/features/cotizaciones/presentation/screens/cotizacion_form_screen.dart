import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/cotizacion.dart';
import '../../domain/repositories/respuesta_cotizacion_repository.dart';
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
  final _origenCtrl = TextEditingController();
  final _destinoCtrl = TextEditingController();
  final _especificacionesCtrl = TextEditingController();
  final _edadesMenoresCtrl = TextEditingController();
  final _numeroPasajerosCtrl = TextEditingController(text: '1');

  String _countryCode = '+57';

  DateTime? _fechaSalida;
  DateTime? _fechaRegreso;

  @override
  void initState() {
    super.initState();
    if (widget.cotizacion != null) {
      final c = widget.cotizacion!;
      _nombreCtrl.text = c.nombreCompleto;
      _correoCtrl.text = c.correoElectronico ?? '';
      final parsed = _parsePhone(c.chatId.trim());
      _countryCode = parsed.$1;
      _chatIdCtrl.text = parsed.$2;
      _detallesPlanCtrl.text = c.detallesPlan;
      final od = c.origenDestino ?? '';
      if (od.contains(' → ')) {
        final parts = od.split(' → ');
        _origenCtrl.text = parts[0].trim();
        _destinoCtrl.text = parts.sublist(1).join(' → ').trim();
      } else {
        _destinoCtrl.text = od;
      }
      _especificacionesCtrl.text = c.especificaciones ?? '';
      _edadesMenoresCtrl.text = c.edadesMenuores ?? '';
      _numeroPasajerosCtrl.text = c.numeroPasajeros.toString();
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
    _origenCtrl.dispose();
    _destinoCtrl.dispose();
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
          ),
          dialogTheme: DialogThemeData(backgroundColor: SaasPalette.bgCanvas),
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

  String? _buildOrigenDestino() {
    final origen = _origenCtrl.text.trim();
    final destino = _destinoCtrl.text.trim();
    if (origen.isEmpty && destino.isEmpty) return null;
    if (origen.isEmpty) return destino;
    if (destino.isEmpty) return origen;
    return '$origen → $destino';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final cotizacion = Cotizacion(
      id: widget.cotizacion?.id ?? 0,
      chatId: '$_countryCode${_chatIdCtrl.text.trim()}',
      nombreCompleto: _nombreCtrl.text.trim(),
      correoElectronico: _correoCtrl.text.trim().isEmpty
          ? null
          : _correoCtrl.text.trim(),
      detallesPlan: _detallesPlanCtrl.text.trim(),
      numeroPasajeros: int.tryParse(_numeroPasajerosCtrl.text.trim()) ?? 1,
      fechaSalida: _fechaSalida?.toIso8601String().split('T').first,
      fechaRegreso: _fechaRegreso?.toIso8601String().split('T').first,
      origenDestino: _buildOrigenDestino(),
      edadesMenuores: _edadesMenoresCtrl.text.trim().isEmpty
          ? null
          : _edadesMenoresCtrl.text.trim(),
      especificaciones: _especificacionesCtrl.text.trim().isEmpty
          ? null
          : _especificacionesCtrl.text.trim(),
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
          SaasSnackBar.showSuccess(context, 'Cotización guardada exitosamente');
          Navigator.pop(context, true);
        } else if (state is CotizacionError) {
          SaasSnackBar.showError(context, state.message);
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
                                _WhatsAppField(
                                  controller: _chatIdCtrl,
                                  countryCode: _countryCode,
                                  onCountryCodeChanged: (v) =>
                                      setState(() => _countryCode = v),
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
                                  label: 'Detalles del plan *',
                                  icon: Icons.map_rounded,
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: PremiumTextField(
                                        controller: _origenCtrl,
                                        label: 'Origen',
                                        icon: Icons.flight_takeoff_rounded,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: PremiumTextField(
                                        controller: _destinoCtrl,
                                        label: 'Destino',
                                        icon: Icons.flight_land_rounded,
                                      ),
                                    ),
                                  ],
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
                              title: 'NOTAS ',
                              icon: Icons.edit_note_rounded,
                              children: [
                                PremiumTextField(
                                  controller: _especificacionesCtrl,
                                  label: 'Especificaciones / Notas',
                                  icon: Icons.notes_rounded,
                                  maxLines: 5,
                                ),
                                const SizedBox(height: 20),
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
                            if (widget.cotizacion != null && widget.cotizacion?.respuestaCotizacionId == null) ...[
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRouter.cotizacionResponder,
                                    arguments: widget.cotizacion,
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                },
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: SaasPalette.success,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: SaasPalette.success.withValues(alpha: 0.25),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.reply_rounded, color: Colors.white, size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'RESPONDER COTIZACIÓN',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            if (widget.cotizacion?.respuestaCotizacionId != null) ...[
                              const SizedBox(height: 16),
                              PremiumActionButton(
                                label: 'VER RESPUESTA ENVIADA',
                                icon: Icons.forward_to_inbox_rounded,
                                isLoading: false,
                                onTap: _viewResponse,
                              ),
                            ],
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

  Future<void> _viewResponse() async {
    bool dialogShown = false;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: SaasPalette.brand600),
        ),
      );
      dialogShown = true;

      final repository = context.read<RespuestaCotizacionRepository>();
      final respuestas = await repository.getRespuestasByCotizacion(
        widget.cotizacion!.id,
      );

      // Cerrar el diálogo ANTES de navegar
      if (dialogShown && mounted) {
        Navigator.pop(context);
        dialogShown = false;
      }

      if (respuestas.isNotEmpty) {
        if (mounted) {
          await Navigator.pushNamed(
            context,
            AppRouter.respuestaDetalle,
            arguments: respuestas.first,
          );
          // Opcional: cerramos este formulario al volver si así se desea
          if (mounted) Navigator.pop(context);
        }
      } else {
        if (mounted) {
          SaasSnackBar.showWarning(
            context,
            'No se encontró una respuesta para esta cotización.',
          );
        }
      }
    } catch (e) {
      if (dialogShown && mounted) {
        Navigator.pop(context);
        dialogShown = false;
      }
      if (mounted) {
        SaasSnackBar.showError(
          context,
          'Error al obtener la respuesta: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }
}

// ─── Country codes ─────────────────────────────────────────────────────────────

class _CountryCode {
  final String code;
  final String name;
  final String flag;
  const _CountryCode({required this.code, required this.name, required this.flag});
}

const _kCountryCodes = [
  _CountryCode(code: '+57', name: 'Colombia', flag: '🇨🇴'),
  _CountryCode(code: '+1', name: 'EE.UU./Canadá', flag: '🇺🇸'),
  _CountryCode(code: '+34', name: 'España', flag: '🇪🇸'),
  _CountryCode(code: '+52', name: 'México', flag: '🇲🇽'),
  _CountryCode(code: '+54', name: 'Argentina', flag: '🇦🇷'),
  _CountryCode(code: '+55', name: 'Brasil', flag: '🇧🇷'),
  _CountryCode(code: '+56', name: 'Chile', flag: '🇨🇱'),
  _CountryCode(code: '+51', name: 'Perú', flag: '🇵🇪'),
  _CountryCode(code: '+58', name: 'Venezuela', flag: '🇻🇪'),
  _CountryCode(code: '+593', name: 'Ecuador', flag: '🇪🇨'),
  _CountryCode(code: '+591', name: 'Bolivia', flag: '🇧🇴'),
  _CountryCode(code: '+595', name: 'Paraguay', flag: '🇵🇾'),
  _CountryCode(code: '+598', name: 'Uruguay', flag: '🇺🇾'),
  _CountryCode(code: '+507', name: 'Panamá', flag: '🇵🇦'),
  _CountryCode(code: '+506', name: 'Costa Rica', flag: '🇨🇷'),
  _CountryCode(code: '+44', name: 'Reino Unido', flag: '🇬🇧'),
  _CountryCode(code: '+49', name: 'Alemania', flag: '🇩🇪'),
  _CountryCode(code: '+33', name: 'Francia', flag: '🇫🇷'),
];

(String, String) _parsePhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
  final sorted = _kCountryCodes.toList()
    ..sort((a, b) => b.code.length.compareTo(a.code.length));
  for (final cc in sorted) {
    final dial = cc.code.replaceAll('+', '');
    if (digits.startsWith(dial) && digits.length > dial.length) {
      return (cc.code, digits.substring(dial.length));
    }
  }
  return ('+57', digits);
}

// ─── WhatsApp field with country code selector ────────────────────────────────

class _WhatsAppField extends StatelessWidget {
  final TextEditingController controller;
  final String countryCode;
  final ValueChanged<String> onCountryCodeChanged;

  const _WhatsAppField({
    required this.controller,
    required this.countryCode,
    required this.onCountryCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chat - WhatsApp *',
          style: TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SaasPalette.border),
          ),
          child: Row(
            children: [
              // Selector de indicativo
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: countryCode,
                  dropdownColor: SaasPalette.bgCanvas,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 13,
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: SaasPalette.textTertiary,
                    size: 18,
                  ),
                  menuMaxHeight: 320,
                  onChanged: (v) { if (v != null) onCountryCodeChanged(v); },
                  items: _kCountryCodes
                      .map(
                        (cc) => DropdownMenuItem(
                          value: cc.code,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${cc.flag} ${cc.code}',
                              style: const TextStyle(
                                color: SaasPalette.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Container(width: 1, height: 24, color: SaasPalette.border),
              // Campo numérico
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Número sin indicativo',
                    hintStyle: TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
              ),
            ],
          ),
        ),
      ],
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
