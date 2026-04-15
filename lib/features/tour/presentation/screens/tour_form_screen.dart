import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/di/injection_container.dart';
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Text(
            _isEditing && !canWrite
                ? 'Ver Experiencia'
                : (_isEditing ? 'Configurar Experiencia' : 'Nueva Aventura'),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
        body: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
            FadeTransition(
              opacity: _fade,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionCard('GENERAL', [
                            _buildField(
                              controller: _idTourCtrl,
                              label: 'Código de Operación *',
                              icon: Icons.vpn_key_rounded,
                              isNumeric: true,
                              readOnly: !canWrite,
                            ),
                            const SizedBox(height: 20),
                            _buildField(
                              controller: _nameCtrl,
                              label: 'Título de la Experiencia *',
                              icon: Icons.tour_rounded,
                              readOnly: !canWrite,
                            ),
                            const SizedBox(height: 20),
                            _buildSedeDropdown(canWrite: canWrite),
                          ]),
                          const SizedBox(height: 32),
                          _buildSectionCard('DETALLES DE VIAJE', [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
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
                                    onTap: canWrite ? _pickDateRange : () {},
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    controller: _departurePointCtrl,
                                    label: 'Lugar Salida *',
                                    icon: Icons.place_rounded,
                                    readOnly: !canWrite,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _buildField(
                                    controller: _departureTimeCtrl,
                                    label: 'Hora Estimada *',
                                    icon: Icons.access_time_rounded,
                                    readOnly: !canWrite,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildField(
                              controller: _arrivalCtrl,
                              label: 'Destino Final *',
                              icon: Icons.flag_rounded,
                              readOnly: !canWrite,
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _buildSectionCard('CONTENIDO MULTIMEDIA', [
                            _buildField(
                              controller: _imageUrlCtrl,
                              label: 'URL Portada',
                              icon: Icons.image_rounded,
                              readOnly: !canWrite,
                            ),
                            const SizedBox(height: 20),
                            _buildField(
                              controller: _pdfLinkCtrl,
                              label: 'Link Catálogo (Google Drive)',
                              icon: Icons.picture_as_pdf_rounded,
                              readOnly: !canWrite,
                            ),
                          ]),
                          const SizedBox(height: 32),
                          _buildSectionCard('LOGÍSTICA', [
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
                          ]),
                          const SizedBox(height: 32),
                          _buildItinerarySection(canWrite: canWrite),
                          const SizedBox(height: 32),
                          _buildStatusCard(canWrite: canWrite),
                          const SizedBox(height: 60),
                          if (canWrite) _buildBottomActions(),
                          const SizedBox(height: 100),
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

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumeric = false,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: D.slate600,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: D.slate800, size: 18),
            filled: true,
            fillColor: D.bg.withOpacity(0.3),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: D.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: D.skyBlue),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: (v) => (v == null || v.isEmpty) && label.contains('*')
              ? 'Requerido'
              : null,
        ),
      ],
    );
  }

  Widget _buildSedeDropdown({required bool canWrite}) {
    return BlocProvider(
      create: (_) => sl<SedeBloc>()..add(LoadSedes()),
      child: BlocBuilder<SedeBloc, SedeState>(
        builder: (context, state) {
          List<Sede> sedes = (state is SedesLoaded) ? state.sedes : [];

          final selectedSede = sedes.where((s) => s.id == _selectedSedeId).firstOrNull;
          final sedeLabel = selectedSede?.nombreSede ?? (_selectedSedeId != null ? 'Sede #$_selectedSedeId' : '—');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEDE DE OPERACIÓN *',
                style: TextStyle(
                  color: D.slate600,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (!canWrite)
                // Modo lectura: muestra el nombre directamente
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: D.bg.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: D.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.business_rounded, color: D.slate800, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        state is SedeLoading ? 'Cargando...' : sedeLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: sedes.any((s) => s.id == _selectedSedeId) ? _selectedSedeId : null,
                  dropdownColor: D.surface,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.business_rounded,
                      color: D.slate800,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: D.bg.withOpacity(0.3),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: D.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: D.skyBlue),
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
                    state is SedeLoading ? 'Cargando...' : 'Selecciona una sede',
                    style: TextStyle(color: D.slate800, fontSize: 13),
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
          style: TextStyle(
            color: D.slate600,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (canWrite)
          Row(
            children: [
              Expanded(
                child: _buildField(
                  controller: ctrl,
                  label: 'Nueva entrada',
                  icon: icon,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 20),
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
                (e) => _PremiumChip(
                  label: e.value,
                  color: accent,
                  onRemove: canWrite ? () => setState(() => list.removeAt(e.key)) : null,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildItinerarySection({required bool canWrite}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionHeader(title: 'ITINERARIO DETALLADO'),
              ),
              if (canWrite)
                _MiniAddButton(label: 'DÍA', onTap: _addItineraryDay),
            ],
          ),
          const SizedBox(height: 24),
          if (_itinerary.isEmpty)
            _EmptyIndicator(msg: 'No has definido el recorrido paso a paso.')
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
    );
  }

  Widget _buildStatusCard({required bool canWrite}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: D.bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: D.border),
      ),
      child: Row(
        children: [
          _StatusSwitch(
            label: 'Experiencia Destacada (Promo)',
            value: _isPromotion,
            onChanged: canWrite ? (v) => setState(() => _isPromotion = v) : null,
            activeColor: D.gold,
          ),
          const SizedBox(width: 32),
          _StatusSwitch(
            label: 'Habilitada al Público',
            value: _isActive,
            onChanged: canWrite ? (v) => setState(() => _isActive = v) : null,
            activeColor: D.emerald,
          ),
          const SizedBox(width: 32),
          _StatusSwitch(
            label: 'Precio por Pareja',
            value: _precioPorPareja,
            onChanged: canWrite ? (v) => setState(() => _precioPorPareja = v) : null,
            activeColor: D.skyBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return BlocBuilder<TourBloc, TourState>(
      builder: (context, state) {
        final isSaving = state is TourSaving;
        return _FormButton(
          label: 'GUARDAR',
          color: D.royalBlue,
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
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.dark(primary: D.royalBlue)),
        child: child!,
      ),
    );
    if (range != null) setState(() => _dateRange = range);
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 14,
        decoration: BoxDecoration(
          color: D.skyBlue,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: TextStyle(
          color: D.slate400,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    ],
  );
}

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
          color: D.slate600,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: D.bg.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: D.border),
          ),
          child: Row(
            children: [
              Icon(Icons.date_range_rounded, color: D.slate800, size: 18),
              const SizedBox(width: 12),
              Text(
                range == null
                    ? 'Seleccionar fechas'
                    : '${DateFormat('dd/MM').format(range!.start)} - ${DateFormat('dd/MM').format(range!.end)}',
                style: TextStyle(
                  color: range == null ? D.slate800 : Colors.white,
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

class _PremiumChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onRemove;
  const _PremiumChip({
    required this.label,
    required this.color,
    required this.onRemove,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (onRemove != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close_rounded, color: color, size: 14),
          ),
        ],
      ],
    ),
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
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: D.bg.withOpacity(0.5),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: D.border),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: D.royalBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'DÍA ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const Spacer(),
            if (canWrite)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: D.rose,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: day.title,
          readOnly: !canWrite,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _fieldDec('Título del día'),
          onChanged: canWrite ? (v) => onUpdate(day.copyWith(title: v)) : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: day.description,
          readOnly: !canWrite,
          maxLines: 3,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: _fieldDec('Detalles del recorrido'),
          onChanged: canWrite ? (v) => onUpdate(day.copyWith(description: v)) : null,
        ),
      ],
    ),
  );
  InputDecoration _fieldDec(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: D.slate800, fontSize: 13),
    filled: true,
    fillColor: D.surface.withOpacity(0.3),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: D.border),
    ),
  );
}

class _StatusSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool)? onChanged;
  final Color activeColor;
  const _StatusSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Switch(
          value: value,
          activeThumbColor: activeColor,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

class _FormButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;
  const _FormButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
      ),
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

class _EmptyIndicator extends StatelessWidget {
  final String msg;
  const _EmptyIndicator({required this.msg});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        msg,
        style: TextStyle(
          color: D.slate800,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    ),
  );
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = D.border.withOpacity(0.2);
    const spacing = 32.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
