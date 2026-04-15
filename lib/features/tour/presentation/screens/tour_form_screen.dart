import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/tour.dart';
import '../../../../features/settings/domain/entities/sede.dart';
import '../../../../features/settings/presentation/bloc/sede_bloc.dart';
import '../bloc/tour_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class TourFormScreen extends StatefulWidget {
  final Tour? tour;
  const TourFormScreen({super.key, this.tour});

  @override
  State<TourFormScreen> createState() => _TourFormScreenState();
}

class _TourFormScreenState extends State<TourFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _agencyCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _departurePointCtrl;
  late final TextEditingController _departureTimeCtrl;
  late final TextEditingController _arrivalCtrl;
  late final TextEditingController _pdfLinkCtrl;
  late final TextEditingController _imageUrlCtrl;
  late final TextEditingController _idTourCtrl;

  DateTimeRange? _dateRange;
  String? _selectedSedeId;
  bool _isPromotion = false;
  bool _isActive = true;
  bool _precioPorPareja = false;
  List<String> _inclusions = [];
  List<String> _exclusions = [];
  List<ItineraryDay> _itinerary = [];
  final _inclusionCtrl = TextEditingController();
  final _exclusionCtrl = TextEditingController();

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;

  bool get _isEditing => widget.tour != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tour;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _agencyCtrl = TextEditingController(
      text: t?.agency ?? 'Travel Tours Florencia',
    );
    _priceCtrl = TextEditingController(text: t?.price.toInt().toString() ?? '');
    _departurePointCtrl = TextEditingController(text: t?.departurePoint ?? '');
    _departureTimeCtrl = TextEditingController(text: t?.departureTime ?? '');
    _arrivalCtrl = TextEditingController(text: t?.arrival ?? '');
    _pdfLinkCtrl = TextEditingController(text: t?.pdfLink ?? '');
    _imageUrlCtrl = TextEditingController(text: t?.imageUrl ?? '');
    _idTourCtrl = TextEditingController(text: t?.idTour.toString() ?? '');
    if (t != null) {
      _dateRange = DateTimeRange(start: t.startDate, end: t.endDate);
      _selectedSedeId = t.sedeId;
      _isPromotion = t.isPromotion;
      _isActive = t.isActive;
      _precioPorPareja = t.precioPorPareja;
      _inclusions = List.from(t.inclusions);
      _exclusions = List.from(t.exclusions);
      _itinerary = List.from(t.itinerary);
    }

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _agencyCtrl.dispose();
    _priceCtrl.dispose();
    _departurePointCtrl.dispose();
    _departureTimeCtrl.dispose();
    _arrivalCtrl.dispose();
    _pdfLinkCtrl.dispose();
    _imageUrlCtrl.dispose();
    _idTourCtrl.dispose();
    _inclusionCtrl.dispose();
    _exclusionCtrl.dispose();
    super.dispose();
  }

  void _addItineraryDay() {
    setState(() {
      _itinerary.add(
        ItineraryDay(
          dayNumber: _itinerary.length + 1,
          title: '',
          description: '',
        ),
      );
    });
  }

  void _removeItineraryDay(int index) {
    setState(() {
      _itinerary.removeAt(index);
      for (int i = 0; i < _itinerary.length; i++) {
        _itinerary[i] = _itinerary[i].copyWith(dayNumber: i + 1);
      }
    });
  }

  void _saveTour(BuildContext context, {required bool publish}) {
    if (!_formKey.currentState!.validate()) return;
    if (_inclusions.isEmpty) {
      _showMsg('Incluye al menos una inclusión', D.rose);
      return;
    }
    if (_dateRange == null) {
      _showMsg('Selecciona el rango de fechas', D.rose);
      return;
    }

    final tour = Tour(
      id: _isEditing
          ? widget.tour!.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      idTour: int.tryParse(_idTourCtrl.text) ?? 0,
      name: _nameCtrl.text.trim(),
      agency: _agencyCtrl.text.trim(),
      startDate: _dateRange!.start,
      endDate: _dateRange!.end,
      price:
          double.tryParse(_priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
          0,
      departurePoint: _departurePointCtrl.text.trim(),
      departureTime: _departureTimeCtrl.text.trim(),
      arrival: _arrivalCtrl.text.trim(),
      pdfLink: _pdfLinkCtrl.text.trim(),
      inclusions: _inclusions,
      exclusions: _exclusions,
      itinerary: _itinerary,
      imageUrl: _imageUrlCtrl.text.trim(),
      sedeId: _selectedSedeId,
      isPromotion: _isPromotion,
      isActive: _isActive,
      isDraft: !publish,
      precioPorPareja: _precioPorPareja,
    );

    if (_isEditing) {
      context.read<TourBloc>().add(UpdateTour(tour));
    } else {
      context.read<TourBloc>().add(CreateTour(tour));
    }
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('tours')
        : true;

    return BlocListener<TourBloc, TourState>(
      listener: (context, state) {
        if (state is TourSaved) {
          _showMsg('Experiencia guardada exitosamente', D.emerald);
          Navigator.pop(context);
        } else if (state is TourError) {
          _showMsg(state.message, D.rose);
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
                      ? 'Ver Experiencia'
                      : (_isEditing
                            ? 'Configurar Experiencia'
                            : 'Nueva Aventura'),
                  actions: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: D.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _fade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PremiumSectionCard(
                                  title: 'GENERAL',
                                  icon: Icons.dashboard_rounded,
                                  children: [
                                    PremiumTextField(
                                      controller: _idTourCtrl,
                                      label: 'Código de Operación *',
                                      icon: Icons.vpn_key_rounded,
                                      isNumeric: true,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _nameCtrl,
                                      label: 'Título de la Experiencia *',
                                      icon: Icons.tour_rounded,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildSedeDropdown(canWrite: canWrite),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                PremiumSectionCard(
                                  title: 'DETALLES DE VIAJE',
                                  icon: Icons.flight_takeoff_rounded,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: PremiumTextField(
                                            controller: _priceCtrl,
                                            label: 'Precio (COP) *',
                                            icon: Icons.attach_money_rounded,
                                            isNumeric: true,
                                            readOnly: !canWrite,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: _DateRangeSelector(
                                            range: _dateRange,
                                            onTap: canWrite
                                                ? _pickDateRange
                                                : () {},
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: PremiumTextField(
                                            controller: _departurePointCtrl,
                                            label: 'Lugar Salida *',
                                            icon: Icons.place_rounded,
                                            readOnly: !canWrite,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Expanded(
                                          child: PremiumTextField(
                                            controller: _departureTimeCtrl,
                                            label: 'Hora Estimada *',
                                            icon: Icons.access_time_rounded,
                                            readOnly: !canWrite,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _arrivalCtrl,
                                      label: 'Destino Final *',
                                      icon: Icons.flag_rounded,
                                      readOnly: !canWrite,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                PremiumSectionCard(
                                  title: 'CONTENIDO MULTIMEDIA',
                                  icon: Icons.perm_media_rounded,
                                  children: [
                                    PremiumTextField(
                                      controller: _imageUrlCtrl,
                                      label: 'URL Portada',
                                      icon: Icons.image_rounded,
                                      readOnly: !canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    PremiumTextField(
                                      controller: _pdfLinkCtrl,
                                      label: 'Link Catálogo (Google Drive)',
                                      icon: Icons.picture_as_pdf_rounded,
                                      readOnly: !canWrite,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                PremiumSectionCard(
                                  title: 'LOGÍSTICA',
                                  icon: Icons.inventory_2_rounded,
                                  children: [
                                    _buildDynamicList(
                                      'Inclusiones',
                                      _inclusionCtrl,
                                      _inclusions,
                                      Icons.check_circle_rounded,
                                      D.emerald,
                                      canWrite: canWrite,
                                    ),
                                    const SizedBox(height: 32),
                                    _buildDynamicList(
                                      'Exclusiones',
                                      _exclusionCtrl,
                                      _exclusions,
                                      Icons.cancel_rounded,
                                      D.rose,
                                      canWrite: canWrite,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildItinerarySection(canWrite: canWrite),
                                const SizedBox(height: 24),
                                _buildStatusCard(canWrite: canWrite),
                                const SizedBox(height: 48),
                                if (canWrite) _buildBottomActions(),
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
    return BlocProvider(
      create: (_) => sl<SedeBloc>()..add(LoadSedes()),
      child: BlocBuilder<SedeBloc, SedeState>(
        builder: (context, state) {
          List<Sede> sedes = (state is SedesLoaded) ? state.sedes : [];
          final selectedSede = sedes
              .where((s) => s.id == _selectedSedeId)
              .firstOrNull;
          final sedeLabel =
              selectedSede?.nombreSede ??
              (_selectedSedeId != null ? 'Sede #$_selectedSedeId' : '—');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SEDE DE OPERACIÓN *',
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
                        state is SedeLoading ? 'Cargando...' : sedeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: sedes.any((s) => s.id == _selectedSedeId)
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
                      borderSide: const BorderSide(
                        color: D.skyBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                  items: sedes
                      .map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(s.nombreSede),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedSedeId = val),
                  validator: (v) => v == null ? 'Requerido' : null,
                  hint: Text(
                    state is SedeLoading
                        ? 'Cargando...'
                        : 'Selecciona una sede',
                    style: const TextStyle(color: D.slate600, fontSize: 13),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDynamicList(
    String title,
    TextEditingController ctrl,
    List<String> list,
    IconData icon,
    Color accent, {
    required bool canWrite,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: D.slate400,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        if (canWrite)
          Row(
            children: [
              Expanded(
                child: PremiumTextField(
                  controller: ctrl,
                  label: 'Nueva entrada',
                  icon: icon,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: _CircleAddButton(
                  onTap: () {
                    if (ctrl.text.trim().isNotEmpty) {
                      setState(() => list.add(ctrl.text.trim()));
                      ctrl.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: list
              .asMap()
              .entries
              .map(
                (e) => PremiumChip(
                  label: e.value,
                  color: accent,
                  onRemove: canWrite
                      ? () => setState(() => list.removeAt(e.key))
                      : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildItinerarySection({required bool canWrite}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: D.surfaceHigh.withOpacity(0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: PremiumSectionHeader(
                      title: 'ITINERARIO DETALLADO',
                      icon: Icons.map_rounded,
                    ),
                  ),
                  if (canWrite)
                    _MiniAddButton(label: 'DÍA', onTap: _addItineraryDay),
                ],
              ),
              const SizedBox(height: 24),
              if (_itinerary.isEmpty)
                const PremiumEmptyIndicator(
                  msg: 'No has definido el recorrido paso a paso.',
                  icon: Icons.route_rounded,
                )
              else
                ..._itinerary.asMap().entries.map(
                  (e) => _ItineraryDayCard(
                    day: e.value,
                    index: e.key,
                    canWrite: canWrite,
                    onRemove: () => _removeItineraryDay(e.key),
                    onUpdate: (newDay) =>
                        setState(() => _itinerary[e.key] = newDay),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard({required bool canWrite}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: D.surfaceHigh.withOpacity(0.4),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              PremiumStatusSwitch(
                label: 'Experiencia Destacada (Promo)',
                value: _isPromotion,
                onChanged: canWrite
                    ? (v) => setState(() => _isPromotion = v)
                    : null,
                activeColor: D.gold,
              ),
              const SizedBox(width: 32),
              PremiumStatusSwitch(
                label: 'Habilitada al Público',
                value: _isActive,
                onChanged: canWrite
                    ? (v) => setState(() => _isActive = v)
                    : null,
                activeColor: D.emerald,
              ),
              const SizedBox(width: 32),
              PremiumStatusSwitch(
                label: 'Precio por Pareja',
                value: _precioPorPareja,
                onChanged: canWrite
                    ? (v) => setState(() => _precioPorPareja = v)
                    : null,
                activeColor: D.skyBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return BlocBuilder<TourBloc, TourState>(
      builder: (context, state) {
        final isSaving = state is TourSaving;
        return PremiumActionButton(
          label: 'GUARDAR',
          icon: Icons.save_rounded,
          isLoading: isSaving,
          onTap: () => _saveTour(context, publish: true),
        );
      },
    );
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: D.skyBlue,
              onPrimary: Colors.white,
              secondary: D.royalBlue,
              onSecondary: Colors.white,
              surface: D.surfaceHigh,
              onSurface: Colors.white,
              outline: D.border,
            ),
            dialogBackgroundColor: D.surface,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: D.skyBlue,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: D.surfaceHigh,
              labelStyle: const TextStyle(color: D.slate400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: D.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: D.skyBlue, width: 1.5),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: D.surface,
              headerBackgroundColor: D.royalBlue,
              headerForegroundColor: Colors.white,
              dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                if (states.contains(WidgetState.disabled)) {
                  return D.slate600;
                }
                return Colors.white;
              }),
              dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return D.royalBlue;
                }
                return Colors.transparent;
              }),
              rangePickerBackgroundColor: D.surface,
              rangePickerHeaderBackgroundColor: D.royalBlue,
              rangePickerHeaderForegroundColor: Colors.white,
              rangeSelectionBackgroundColor: D.royalBlue.withOpacity(0.2),
              todayForegroundColor: WidgetStateProperty.all(D.skyBlue),
              todayBorder: const BorderSide(color: D.skyBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) setState(() => _dateRange = range);
  }
}

// ─── Widgets locales (específicos de este formulario) ─────────────────────────

class _DateRangeSelector extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onTap;
  const _DateRangeSelector({required this.range, required this.onTap});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'TEMPORADA *',
        style: TextStyle(
          color: D.slate400,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: D.surfaceHigh.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              const Icon(Icons.date_range_rounded, color: D.skyBlue, size: 20),
              const SizedBox(width: 12),
              Text(
                range == null
                    ? 'Seleccionar fechas'
                    : '${DateFormat('dd/MM').format(range!.start)} '
                          '- ${DateFormat('dd/MM').format(range!.end)}',
                style: TextStyle(
                  color: range == null ? D.slate400 : Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _ItineraryDayCard extends StatelessWidget {
  final ItineraryDay day;
  final int index;
  final bool canWrite;
  final VoidCallback onRemove;
  final Function(ItineraryDay) onUpdate;

  const _ItineraryDayCard({
    required this.day,
    required this.index,
    required this.canWrite,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: D.surfaceHigh.withOpacity(0.4),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.05)),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [D.skyBlue, D.royalBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'DÍA ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            if (canWrite)
              IconButton(
                onPressed: onRemove,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: D.rose.withOpacity(0.8),
                  size: 22,
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextFormField(
          initialValue: day.title,
          readOnly: !canWrite,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _fieldDec('Título del día'),
          onChanged: canWrite ? (v) => onUpdate(day.copyWith(title: v)) : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: day.description,
          readOnly: !canWrite,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _fieldDec('Detalles del recorrido'),
          onChanged: canWrite
              ? (v) => onUpdate(day.copyWith(description: v))
              : null,
        ),
      ],
    ),
  );

  InputDecoration _fieldDec(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: D.slate400, fontSize: 13),
    filled: true,
    fillColor: D.surfaceHigh.withOpacity(0.5),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: D.skyBlue, width: 1.5),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
    ),
  );
}

class _CircleAddButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CircleAddButton({required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: D.royalBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white),
    ),
  );
}

class _MiniAddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _MiniAddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.add_rounded, size: 18),
    label: Text(
      'AGREGAR $label',
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );
}
