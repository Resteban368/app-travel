import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_precio.dart';
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
  late final TextEditingController _idTourCtrl;
  late final TextEditingController _cuposCtrl;

  DateTimeRange? _dateRange;
  String? _selectedSedeId;
  bool _isPromotion = false;
  bool _isActive = true;
  bool _precioPorPareja = false;
  List<String> _inclusions = [];
  List<String> _exclusions = [];
  List<ItineraryDay> _itinerary = [];
  List<TourPrecio> _precios = [];
  bool _preciosModificados = false;
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
    _idTourCtrl = TextEditingController(text: t?.idTour.toString() ?? '');
    _cuposCtrl = TextEditingController(text: t?.cupos?.toString() ?? '');
    if (t != null) {
      _dateRange = DateTimeRange(start: t.startDate, end: t.endDate);
      _selectedSedeId = t.sedeId;
      _isPromotion = t.isPromotion;
      _isActive = t.isActive;
      _precioPorPareja = t.precioPorPareja;
      _inclusions = List.from(t.inclusions);
      _exclusions = List.from(t.exclusions);
      _itinerary = List.from(t.itinerary);
      _precios = List.from(t.precios);
    }

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    _idTourCtrl.dispose();
    _cuposCtrl.dispose();
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
    //validamos que tenga un codigo de operacion
    if (_idTourCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El codigo de operacion es requerido');
      return;
    }
    //UN TITULO
    if (_nameCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El titulo es requerido');
      return;
    }

    //SEDE
    if (_selectedSedeId == null) {
      SaasSnackBar.showWarning(context, 'La sede es requerida');
      return;
    }

    //UN PRECIO
    if (_priceCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El precio es requerido');
      return;
    }
    //FECHAS
    if (_dateRange == null) {
      SaasSnackBar.showWarning(context, 'Las fechas son requeridas');
      return;
    }

    //CUPOS
    if (_cuposCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'Los cupos son requeridos');
      return;
    }

    //LUGAR DE SALIDA
    if (_departurePointCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El lugar de salida es requerido');
      return;
    }

    //HORA DE SALIDA
    if (_departureTimeCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'La hora de salida es requerida');
      return;
    }

    //DESTINO FINAL
    if (_arrivalCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El destino final es requerido');
      return;
    }

    //LINKS
    if (_pdfLinkCtrl.text.trim().isEmpty) {
      SaasSnackBar.showWarning(context, 'El link del pdf es requerido');
      return;
    }

    //INCLUSIONES
    if (_inclusions.isEmpty) {
      SaasSnackBar.showWarning(context, 'Las inclusiones son requeridas');
      return;
    }

    //EXCLUSIONES
    if (_exclusions.isEmpty) {
      SaasSnackBar.showWarning(context, 'Las exclusiones son requeridas');
      return;
    }

    //ITINERARIO
    if (_itinerary.isEmpty) {
      SaasSnackBar.showWarning(context, 'El itinerario es requerido');
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
      sedeId: _selectedSedeId,
      isPromotion: _isPromotion,
      isActive: _isActive,
      isDraft: !publish,
      precioPorPareja: _precioPorPareja,
      cupos: int.tryParse(_cuposCtrl.text.trim()),
      precios: _precios,
    );

    if (_isEditing) {
      context.read<TourBloc>().add(
        UpdateTour(tour, preciosPayload: _preciosModificados ? _precios : null),
      );
    } else {
      context.read<TourBloc>().add(CreateTour(tour));
    }
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
          SaasSnackBar.showSuccess(
            context,
            'Experiencia guardada exitosamente',
          );
          Navigator.pop(context);
        } else if (state is TourError) {
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
                      ? 'Ver Experiencia'
                      : (_isEditing
                            ? 'Configurar Experiencia'
                            : 'Nueva Aventura'),
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
                              const SizedBox(height: 20),
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
                                      const SizedBox(width: 16),
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
                                          controller: _cuposCtrl,
                                          label: 'Cupos totales *',
                                          icon: Icons.people_alt_rounded,
                                          isNumeric: true,
                                          readOnly: !canWrite,
                                        ),
                                      ),
                                      if (_isEditing &&
                                          widget.tour?.cupos != null) ...[
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: _CuposDisponiblesInfo(
                                            cuposDisponibles:
                                                widget.tour!.cuposDisponibles,
                                            cuposTotales: widget.tour!.cupos!,
                                          ),
                                        ),
                                      ] else
                                        const Expanded(child: SizedBox()),
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
                                      const SizedBox(width: 16),
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
                              const SizedBox(height: 20),
                              PremiumSectionCard(
                                title: 'CONTENIDO MULTIMEDIA',
                                icon: Icons.perm_media_rounded,
                                children: [
                                  PremiumTextField(
                                    controller: _pdfLinkCtrl,
                                    label: 'Link Catálogo (Google Drive) *',
                                    icon: Icons.picture_as_pdf_rounded,
                                    readOnly: !canWrite,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              PremiumSectionCard(
                                title: 'LOGÍSTICA',
                                icon: Icons.inventory_2_rounded,
                                children: [
                                  _buildDynamicList(
                                    'Inclusiones *',
                                    _inclusionCtrl,
                                    _inclusions,
                                    Icons.check_circle_rounded,
                                    SaasPalette.success,
                                    canWrite: canWrite,
                                  ),
                                  const SizedBox(height: 28),
                                  _buildDynamicList(
                                    'Exclusiones *',
                                    _exclusionCtrl,
                                    _exclusions,
                                    Icons.cancel_rounded,
                                    SaasPalette.danger,
                                    canWrite: canWrite,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildItinerarySection(canWrite: canWrite),
                              const SizedBox(height: 20),
                              _buildPreciosSection(canWrite: canWrite),
                              const SizedBox(height: 20),
                              _buildStatusCard(canWrite: canWrite),
                              if (_isEditing) ...[
                                const SizedBox(height: 20),
                                _buildPasajerosBtn(context),
                              ],
                              const SizedBox(height: 40),
                              if (canWrite) _buildBottomActions(),
                              const SizedBox(height: 80),
                            ],
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

  Widget _buildPreciosSection({required bool canWrite}) {
    final fmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PremiumSectionHeader(
                  title: 'PRECIOS POR CATEGORÍA',
                  icon: Icons.sell_rounded,
                ),
              ),
              if (canWrite)
                _MiniAddButton(
                  label: 'PRECIO',
                  onTap: () => _showAgregarPrecioSheet(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_precios.isEmpty)
            const PremiumEmptyIndicator(
              msg: 'Opcional — agrega categorías de precio por edad o punto de salida.',
              icon: Icons.local_offer_rounded,
            )
          else
            ..._precios.asMap().entries.map(
              (e) => _PrecioCard(
                precio: e.value,
                fmt: fmt,
                canWrite: canWrite,
                onRemove: () => setState(() {
                  _precios.removeAt(e.key);
                  _preciosModificados = true;
                }),
              ),
            ),
        ],
      ),
    );
  }

  void _showAgregarPrecioSheet() {
    final descCtrl = TextEditingController();
    final precioCtrl = TextEditingController();
    final edadMinCtrl = TextEditingController();
    final edadMaxCtrl = TextEditingController();
    final puntoCtrl = TextEditingController();
    bool activo = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: SaasPalette.bgCanvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Agregar precio',
                        style: TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: SaasPalette.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: descCtrl,
                  label: 'Descripción *',
                  icon: Icons.label_rounded,
                ),
                const SizedBox(height: 14),
                PremiumTextField(
                  controller: precioCtrl,
                  label: 'Precio (COP) *',
                  icon: Icons.attach_money_rounded,
                  isNumeric: true,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: PremiumTextField(
                        controller: edadMinCtrl,
                        label: 'Edad mín.',
                        icon: Icons.child_care_rounded,
                        isNumeric: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PremiumTextField(
                        controller: edadMaxCtrl,
                        label: 'Edad máx.',
                        icon: Icons.person_rounded,
                        isNumeric: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PremiumTextField(
                  controller: puntoCtrl,
                  label: 'Punto de salida',
                  icon: Icons.place_rounded,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Activo',
                        style: TextStyle(
                          color: SaasPalette.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Switch(
                      value: activo,
                      activeColor: SaasPalette.brand600,
                      onChanged: (v) => setSheetState(() => activo = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SaasPalette.brand600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (descCtrl.text.trim().isEmpty ||
                          precioCtrl.text.trim().isEmpty) return;
                      final nuevo = TourPrecio(
                        descripcion: descCtrl.text.trim(),
                        precio: double.tryParse(
                          precioCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                        ) ?? 0,
                        edadMin: int.tryParse(edadMinCtrl.text.trim()),
                        edadMax: int.tryParse(edadMaxCtrl.text.trim()),
                        puntoPartida: puntoCtrl.text.trim().isEmpty
                            ? null
                            : puntoCtrl.text.trim(),
                        activo: activo,
                      );
                      setState(() {
                        _precios.add(nuevo);
                        _preciosModificados = true;
                      });
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'AGREGAR',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      descCtrl.dispose();
      precioCtrl.dispose();
      edadMinCtrl.dispose();
      edadMaxCtrl.dispose();
      puntoCtrl.dispose();
    });
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
                  color: SaasPalette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              if (!canWrite)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: SaasPalette.bgSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SaasPalette.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.business_rounded,
                        color: SaasPalette.brand600,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state is SedeLoading ? 'Cargando...' : sedeLabel,
                        style: const TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  initialValue: sedes.any((s) => s.id == _selectedSedeId)
                      ? _selectedSedeId
                      : null,
                  dropdownColor: SaasPalette.bgCanvas,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.business_rounded,
                      color: SaasPalette.brand600,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: SaasPalette.bgCanvas,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: SaasPalette.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: SaasPalette.brand600,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
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
                    style: const TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 13,
                    ),
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
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
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
                padding: const EdgeInsets.only(top: 20),
                child: _CircleAddButton(
                  color: accent,
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
        const SizedBox(height: 12),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
          const SizedBox(height: 20),
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
    );
  }

  Widget _buildStatusCard({required bool canWrite}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          PremiumStatusSwitch(
            label: 'Experiencia Destacada (Promo)',
            value: _isPromotion,
            onChanged: canWrite
                ? (v) => setState(() => _isPromotion = v)
                : null,
            activeColor: SaasPalette.warning,
          ),
          const SizedBox(width: 24),
          PremiumStatusSwitch(
            label: 'Habilitada al Público',
            value: _isActive,
            onChanged: canWrite ? (v) => setState(() => _isActive = v) : null,
            activeColor: SaasPalette.success,
          ),
          const SizedBox(width: 24),
          PremiumStatusSwitch(
            label: 'Precio por Pareja',
            value: _precioPorPareja,
            onChanged: canWrite
                ? (v) => setState(() => _precioPorPareja = v)
                : null,
            activeColor: SaasPalette.brand600,
          ),
        ],
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

  Widget _buildPasajerosBtn(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRouter.tourDetalle,
        arguments: widget.tour,
      ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [SaasPalette.brand600, SaasPalette.brand900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: SaasPalette.brand600.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ver Pasajeros',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Integrantes y reservas con cupo',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: SaasPalette.brand600,
            onPrimary: Colors.white,
            surface: SaasPalette.bgCanvas,
            onSurface: SaasPalette.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (range != null) setState(() => _dateRange = range);
  }
}

// ─── Widgets locales ──────────────────────────────────────────────────────────

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
          color: SaasPalette.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      const SizedBox(height: 6),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SaasPalette.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.date_range_rounded,
                color: SaasPalette.brand600,
                size: 18,
              ),
              const SizedBox(width: 12),
              Text(
                range == null
                    ? 'Seleccionar fechas'
                    : '${DateFormat('dd/MM').format(range!.start)} '
                          '- ${DateFormat('dd/MM').format(range!.end)}',
                style: TextStyle(
                  color: range == null
                      ? SaasPalette.textTertiary
                      : SaasPalette.textPrimary,
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
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: SaasPalette.bgSubtle,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SaasPalette.border),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: SaasPalette.brand50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: SaasPalette.brand600.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'DÍA ${index + 1}',
                style: const TextStyle(
                  color: SaasPalette.brand600,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            if (canWrite)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: SaasPalette.danger,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: day.title,
          readOnly: !canWrite,
          style: const TextStyle(color: SaasPalette.textPrimary, fontSize: 14),
          decoration: _fieldDec('Título del día'),
          onChanged: canWrite ? (v) => onUpdate(day.copyWith(title: v)) : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: day.description,
          readOnly: !canWrite,
          maxLines: 3,
          style: const TextStyle(color: SaasPalette.textPrimary, fontSize: 14),
          decoration: _fieldDec('Detalles del recorrido'),
          onChanged: canWrite
              ? (v) => onUpdate(day.copyWith(description: v))
              : null,
        ),
      ],
    ),
  );

  InputDecoration _fieldDec(String label) => const InputDecoration(
    labelStyle: TextStyle(color: SaasPalette.textSecondary, fontSize: 13),
    filled: true,
    fillColor: SaasPalette.bgCanvas,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: SaasPalette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: SaasPalette.brand600, width: 1.5),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: SaasPalette.border),
    ),
  ).copyWith(labelText: label);
}

class _CircleAddButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  const _CircleAddButton({required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
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
    style: TextButton.styleFrom(foregroundColor: SaasPalette.brand600),
    icon: const Icon(Icons.add_rounded, size: 16),
    label: Text(
      'AGREGAR $label',
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _PrecioCard extends StatelessWidget {
  final TourPrecio precio;
  final NumberFormat fmt;
  final bool canWrite;
  final VoidCallback onRemove;

  const _PrecioCard({
    required this.precio,
    required this.fmt,
    required this.canWrite,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final edadStr = precio.edadMin != null || precio.edadMax != null
        ? '${precio.edadMin ?? '0'}-${precio.edadMax ?? '∞'} años'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  precio.descripcion,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (edadStr != null || precio.puntoPartida != null) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      if (edadStr != null)
                        _SmallBadge(label: edadStr, color: SaasPalette.brand600),
                      if (precio.puntoPartida != null)
                        _SmallBadge(
                          label: 'desde ${precio.puntoPartida}',
                          color: SaasPalette.textTertiary,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            fmt.format(precio.precio),
            style: const TextStyle(
              color: SaasPalette.success,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (canWrite) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: SaasPalette.danger,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _CuposDisponiblesInfo extends StatelessWidget {
  final int? cuposDisponibles;
  final int cuposTotales;

  const _CuposDisponiblesInfo({
    required this.cuposDisponibles,
    required this.cuposTotales,
  });

  @override
  Widget build(BuildContext context) {
    final disponibles = cuposDisponibles ?? cuposTotales;
    final porcentaje = cuposTotales > 0 ? disponibles / cuposTotales : 1.0;
    final color = porcentaje > 0.4
        ? SaasPalette.success
        : porcentaje > 0
        ? SaasPalette.warning
        : SaasPalette.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CUPOS DISPONIBLES',
          style: TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.event_seat_rounded, color: color, size: 18),
              const SizedBox(width: 10),
              Text(
                '$disponibles / $cuposTotales',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: porcentaje.clamp(0.0, 1.0),
                    backgroundColor: SaasPalette.bgSubtle,
                    color: color,
                    minHeight: 5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
