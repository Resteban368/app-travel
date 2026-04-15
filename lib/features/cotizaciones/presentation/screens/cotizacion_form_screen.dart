import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cotizacion.dart';
import '../bloc/cotizacion_bloc.dart';
import '../bloc/cotizacion_event.dart';
import '../bloc/cotizacion_state.dart';
import '../../../../core/theme/premium_palette.dart';

class CotizacionFormScreen extends StatefulWidget {
  const CotizacionFormScreen({super.key});

  @override
  State<CotizacionFormScreen> createState() => _CotizacionFormScreenState();
}

class _CotizacionFormScreenState extends State<CotizacionFormScreen>
    with SingleTickerProviderStateMixin {
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

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  static const _estados = ['pendiente', 'atendida', 'cancelada'];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slide =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
            CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
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
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: D.royalBlue,
            onPrimary: Colors.white,
            surface: D.surface,
            onSurface: Colors.white,
          ),
          dialogBackgroundColor: D.bg,
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
      id: 0,
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
      isRead: true,
      createdAt: DateTime.now(),
    );

    context.read<CotizacionBloc>().add(CreateCotizacion(cotizacion));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CotizacionBloc, CotizacionState>(
      listener: (context, state) {
        if (state is CotizacionSaved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cotización creada exitosamente'),
              backgroundColor: D.emerald,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
          Navigator.pop(context, true);
        } else if (state is CotizacionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: D.rose,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: D.bg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Nueva Cotización',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        body: Stack(
          children: [
            // Orbes de fondo
            Positioned(
                top: -80,
                right: -40,
                child: _orb(220, D.indigo.withOpacity(0.12))),
            Positioned(
                bottom: -60,
                left: -40,
                child: _orb(180, D.royalBlue.withOpacity(0.08))),

            SafeArea(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Datos del Cliente ---
                          _sectionLabel('DATOS DEL CLIENTE'),
                          const SizedBox(height: 16),
                          _card(children: [
                            _field(
                              ctrl: _nombreCtrl,
                              label: 'Nombre Completo *',
                              icon: Icons.person_outline_rounded,
                              hint: 'Ej: Juan Carlos López',
                              textCapitalization: TextCapitalization.words,
                              required: true,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              ctrl: _correoCtrl,
                              label: 'Correo Electrónico',
                              icon: Icons.email_outlined,
                              hint: 'cliente@ejemplo.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              ctrl: _chatIdCtrl,
                              label: 'Número de WhatsApp *',
                              icon: Icons.phone_outlined,
                              hint: '573001234567',
                              keyboardType: TextInputType.phone,
                              required: true,
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // --- Detalles del Viaje ---
                          _sectionLabel('DETALLES DEL VIAJE'),
                          const SizedBox(height: 16),
                          _card(children: [
                            _field(
                              ctrl: _detallesPlanCtrl,
                              label: 'Plan / Destino *',
                              icon: Icons.flight_takeoff_rounded,
                              hint: 'Ej: Vuelo + Hotel Cartagena 5 días',
                              required: true,
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),
                            _field(
                              ctrl: _origenDestinoCtrl,
                              label: 'Origen → Destino',
                              icon: Icons.route_rounded,
                              hint: 'Ej: Bogotá → Cartagena',
                            ),
                            const SizedBox(height: 16),
                            // Fechas
                            Row(
                              children: [
                                Expanded(
                                  child: _DatePickerBtn(
                                    label: 'Fecha de Salida',
                                    date: _fechaSalida,
                                    onTap: () =>
                                        _pickFecha(esSalida: true),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _DatePickerBtn(
                                    label: 'Fecha de Regreso',
                                    date: _fechaRegreso,
                                    onTap: () =>
                                        _pickFecha(esSalida: false),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _field(
                              ctrl: _numeroPasajerosCtrl,
                              label: 'N° de Pasajeros *',
                              icon: Icons.group_outlined,
                              hint: '1',
                              keyboardType: TextInputType.number,
                              required: true,
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if ((int.tryParse(v) ?? 0) < 1) {
                                  return 'Mínimo 1';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _field(
                              ctrl: _edadesMenoresCtrl,
                              label: 'Edades de Menores',
                              icon: Icons.child_care_rounded,
                              hint: 'Ej: 5, 8, 12',
                            ),
                          ]),

                          const SizedBox(height: 20),

                          // --- Especificaciones y Estado ---
                          _sectionLabel('NOTAS Y ESTADO'),
                          const SizedBox(height: 16),
                          _card(children: [
                            _field(
                              ctrl: _especificacionesCtrl,
                              label: 'Especificaciones / Notas',
                              icon: Icons.notes_rounded,
                              hint:
                                  'Detalles adicionales, preferencias del cliente...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            // Estado dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estado',
                                    style: TextStyle(
                                        color: D.slate400,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  value: _estado,
                                  dropdownColor: D.surfaceHigh,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 15),
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(
                                        Icons.flag_outlined,
                                        color: D.skyBlue,
                                        size: 20),
                                    filled: true,
                                    fillColor: D.surfaceHigh.withOpacity(0.5),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: D.border)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(color: D.border)),
                                    focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: const BorderSide(
                                            color: D.skyBlue, width: 1.5)),
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 14),
                                  ),
                                  items: _estados
                                      .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                              e[0].toUpperCase() +
                                                  e.substring(1))))
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _estado = v ?? _estado),
                                ),
                              ],
                            ),
                          ]),

                          const SizedBox(height: 32),

                          // Botón Guardar
                          BlocBuilder<CotizacionBloc, CotizacionState>(
                            builder: (context, state) {
                              final isSaving = state is CotizacionSaving;
                              return SizedBox(
                                width: double.infinity,
                                height: 58,
                                child: ElevatedButton(
                                  onPressed: isSaving ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: D.royalBlue,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        D.slate600.withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18)),
                                    elevation: 8,
                                    shadowColor: D.royalBlue.withOpacity(0.4),
                                  ),
                                  child: isSaving
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2))
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.save_rounded, size: 20),
                                            SizedBox(width: 10),
                                            Text('GUARDAR COTIZACIÓN',
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.8)),
                                          ],
                                        ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
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

  Widget _sectionLabel(String label) => Row(
        children: [
          Container(
              width: 4,
              height: 14,
              decoration: BoxDecoration(
                  color: D.indigo, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: D.slate600,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6)),
        ],
      );

  Widget _card({required List<Widget> children}) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: D.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: D.border),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 6))
          ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: children),
      );

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    required String hint,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: D.slate400,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          validator: validator ??
              (v) =>
                  required && (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: D.slate600, fontSize: 13),
            prefixIcon: maxLines == 1
                ? Icon(icon, color: D.skyBlue, size: 18)
                : null,
            filled: true,
            fillColor: D.surfaceHigh.withOpacity(0.5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: D.border)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: D.border)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: D.skyBlue, width: 1.5)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: D.rose)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}

// ─── Date Picker Button ──────────────────────────────────────────────────────

class _DatePickerBtn extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DatePickerBtn(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDate = date != null;
    final text = hasDate
        ? '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}'
        : label;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: hasDate
              ? D.royalBlue.withOpacity(0.12)
              : D.surfaceHigh.withOpacity(0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: hasDate ? D.royalBlue.withOpacity(0.4) : D.border),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                color: hasDate ? D.skyBlue : D.slate600, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: hasDate ? Colors.white : D.slate600,
                  fontSize: 12,
                  fontWeight:
                      hasDate ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
