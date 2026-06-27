import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:agente_viajes/core/widgets/dialog_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/auth_network_image.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/tour.dart';
import '../../domain/entities/tour_precio.dart';
import '../../domain/entities/precio_grupal.dart';
import '../../domain/entities/tour_salida.dart';
import '../../../../features/settings/domain/entities/sede.dart';
import '../../../../features/settings/presentation/bloc/sede_bloc.dart';
import '../../../../features/bus_layouts/domain/entities/bus_layout.dart';
import '../../../../features/bus_layouts/presentation/bloc/bus_layout_bloc.dart';
import '../../../../features/bus_layouts/presentation/bloc/bus_layout_event.dart';
import '../../../../features/bus_layouts/presentation/bloc/bus_layout_state.dart';
import '../../domain/repositories/tour_repository.dart';
import '../bloc/tour_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../gallery/presentation/widgets/gallery_picker_dialog.dart';

class TourFormScreen extends StatefulWidget {
  final Tour? tour;
  final bool duplicateMode;
  const TourFormScreen({super.key, this.tour, this.duplicateMode = false});

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
  late final TextEditingController _descripcionCtrl;
  late final TextEditingController _recomendacionesCtrl;
  late final ScrollController _descripcionScrollCtrl;
  late final ScrollController _recomendacionesScrollCtrl;

  DateTimeRange? _dateRange;
  String? _selectedSedeId;
  List<int> _selectedBusLayoutIds = [];
  // busLayoutId → asientos de agente seleccionados para ese bus en este tour
  Map<int, Set<String>> _agenteSeatsByBus = {};
  bool _isPromotion = false;
  bool _isActive = true;
  bool _precioPorPareja = false;
  List<String> _inclusions = [];
  List<String> _exclusions = [];
  List<ItineraryDay> _itinerary = [];
  List<TourPrecio> _precios = [];
  List<PrecioGrupal> _preciosGrupales = [];
  List<String> _imagenes = [];
  bool _preciosModificados = false;
  String _modoPrecio = 'individual';
  final _inclusionCtrl = TextEditingController();
  final _exclusionCtrl = TextEditingController();
  final _imagenCtrl = TextEditingController();
  bool _isLoadingFullData = false;
  String? _tipoTour;
  String _disponibilidadTipo = 'fecha_fija';
  List<TourSalida> _salidas = [];

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;

  bool get _isEditing => widget.tour != null;

  @override
  void initState() {
    super.initState();
    final t = widget.tour;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _agencyCtrl = TextEditingController(text: t?.agency ?? 'Agente Viajes');
    _priceCtrl = TextEditingController(
      text: t?.price?.toInt().toString() ?? '',
    );
    _departurePointCtrl = TextEditingController(text: t?.departurePoint ?? '');
    _departureTimeCtrl = TextEditingController(text: t?.departureTime ?? '');
    _arrivalCtrl = TextEditingController(text: t?.arrival ?? '');
    _pdfLinkCtrl = TextEditingController(text: t?.pdfLink ?? '');
    _idTourCtrl = TextEditingController(text: t?.idTour.toString() ?? '');
    _cuposCtrl = TextEditingController(text: t?.cupos?.toString() ?? '');
    _descripcionCtrl = TextEditingController(text: t?.descripcion ?? '');
    _recomendacionesCtrl = TextEditingController(text: t?.recomendaciones ?? '');
    _descripcionScrollCtrl = ScrollController();
    _recomendacionesScrollCtrl = ScrollController();
    if (t != null) {
      if (t.startDate != null && t.endDate != null) {
        _dateRange = DateTimeRange(start: t.startDate!, end: t.endDate!);
      }
      _selectedSedeId = t.sedeId;
      _selectedBusLayoutIds = List<int>.from(t.busLayoutIds ?? []);
      _isPromotion = t.isPromotion ?? false;
      _isActive = t.isActive ?? false;
      _precioPorPareja = t.precioPorPareja ?? false;
      _inclusions = List.from(t.inclusions ?? []);
      _exclusions = List.from(t.exclusions ?? []);
      _itinerary = List.from(t.itinerary ?? []);
      _precios = List.from(t.precios ?? []);
      _preciosGrupales = List.from(t.preciosGrupales);
      _imagenes = List.from(t.imagenes);
      _modoPrecio = t.modoPrecio ?? 'individual';
      _tipoTour = t.tipoTour;
      _disponibilidadTipo = t.disponibilidadTipo;
      _salidas = List.from(t.salidas ?? []);
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

    if (_isEditing && !widget.duplicateMode) {
      _isLoadingFullData = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const DialogLoadingNetwork(
            titel: 'Cargando información del tour...',
          ),
        );
        context.read<TourBloc>().add(GetTourDetail(widget.tour!.id));
      });
    }
  }

  void _updateFieldsFromTour(Tour t) {
    _nameCtrl.text = t.name ?? '';
    _agencyCtrl.text = t.agency ?? '';
    _priceCtrl.text = t.price?.toInt().toString() ?? '';
    _departurePointCtrl.text = t.departurePoint ?? '';
    _departureTimeCtrl.text = t.departureTime ?? '';
    _arrivalCtrl.text = t.arrival ?? '';
    _pdfLinkCtrl.text = t.pdfLink ?? '';
    _idTourCtrl.text = t.idTour?.toString() ?? '';
    _cuposCtrl.text = t.cupos?.toString() ?? '';
    _descripcionCtrl.text = t.descripcion ?? '';
    _recomendacionesCtrl.text = t.recomendaciones ?? '';

    if (t.startDate != null && t.endDate != null) {
      _dateRange = DateTimeRange(start: t.startDate!, end: t.endDate!);
    } else {
      _dateRange = null;
    }
    _selectedSedeId = t.sedeId;
    _selectedBusLayoutIds = List<int>.from(t.busLayoutIds ?? []);
    _isPromotion = t.isPromotion ?? false;
    _isActive = t.isActive ?? false;
    _precioPorPareja = t.precioPorPareja ?? false;
    _inclusions = List.from(t.inclusions ?? []);
    _exclusions = List.from(t.exclusions ?? []);
    _itinerary = List.from(t.itinerary ?? []);
    _precios = List.from(t.precios ?? []);
    _preciosGrupales = List.from(t.preciosGrupales);
    _imagenes = List.from(t.imagenes);
    _tipoTour = t.tipoTour;
    _disponibilidadTipo = t.disponibilidadTipo;
    _salidas = List.from(t.salidas ?? []);
    _isLoadingFullData = false;
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
    _descripcionCtrl.dispose();
    _recomendacionesCtrl.dispose();
    _descripcionScrollCtrl.dispose();
    _recomendacionesScrollCtrl.dispose();
    _inclusionCtrl.dispose();
    _exclusionCtrl.dispose();
    _imagenCtrl.dispose();
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

  Future<void> _loadAgentesForAllBuses(String tourId, List<int> busIds) async {
    final repo = sl<TourRepository>();
    debugPrint('🔍 [Agentes] Cargando agentes — tourId=$tourId busIds=$busIds');
    for (final busId in busIds) {
      try {
        final seats = await repo.getAgentesForBus(tourId, busId);
        debugPrint('✅ [Agentes] bus=$busId → seats=$seats');
        if (mounted) {
          setState(() => _agenteSeatsByBus[busId] = Set<String>.from(seats));
        }
      } catch (e, st) {
        debugPrint('❌ [Agentes] bus=$busId error: $e\n$st');
      }
    }
  }

  Future<void> _saveAllAgentes(BuildContext ctx, String tourId) async {
    if (_agenteSeatsByBus.isEmpty) return;
    final repo = sl<TourRepository>();
    for (final entry in _agenteSeatsByBus.entries) {
      try {
        await repo.updateAgentesForBus(tourId, entry.key, entry.value.toList());
      } catch (e) {
        debugPrint('⚠️ Error guardando agentes bus ${entry.key}: $e');
      }
    }
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

    //TIPO DE TOUR
    if (_tipoTour == null) {
      SaasSnackBar.showWarning(context, 'El tipo de tour es requerido');
      return;
    }

    //PRECIO
    if (_modoPrecio == 'individual') {
      if (_priceCtrl.text.trim().isEmpty) {
        SaasSnackBar.showWarning(context, 'El precio es requerido');
        return;
      }
    } else {
      if (_preciosGrupales.isEmpty) {
        SaasSnackBar.showWarning(
          context,
          'Debes agregar al menos un rango de precio grupal',
        );
        return;
      }
    }
    //FECHAS (solo para fecha_fija)
    if (_disponibilidadTipo == 'fecha_fija' && _dateRange == null) {
      SaasSnackBar.showWarning(context, 'Las fechas son requeridas');
      return;
    }

    //SALIDAS (obligatorias para multiples_fechas)
    if (_disponibilidadTipo == 'multiples_fechas' && _salidas.isEmpty) {
      SaasSnackBar.showWarning(context, 'Debes agregar al menos una salida');
      return;
    }

    //CUPOS (no requerido para permanente)
    if (_disponibilidadTipo != 'permanente' &&
        _disponibilidadTipo != 'multiples_fechas' &&
        _cuposCtrl.text.trim().isEmpty) {
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
      startDate: _disponibilidadTipo == 'fecha_fija' ? _dateRange?.start : null,
      endDate: _disponibilidadTipo == 'fecha_fija' ? _dateRange?.end : null,
      price: _modoPrecio == 'grupal'
          ? 0
          : (double.tryParse(
                  _priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                ) ??
                0),
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
      cupos: _disponibilidadTipo == 'fecha_fija'
          ? int.tryParse(_cuposCtrl.text.trim())
          : null,
      precios: _precios,
      busLayoutIds: _selectedBusLayoutIds,
      tipoTour: _tipoTour,
      modoPrecio: _modoPrecio,
      preciosGrupales: _preciosGrupales,
      imagenes: _imagenes,
      disponibilidadTipo: _disponibilidadTipo,
      salidas: _disponibilidadTipo == 'multiples_fechas'
          ? List.from(_salidas)
          : null,
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      recomendaciones: _recomendacionesCtrl.text.trim().isEmpty
          ? null
          : _recomendacionesCtrl.text.trim(),
    );

    if (_isEditing) {
      context.read<TourBloc>().add(
        UpdateTour(tour, preciosPayload: _preciosModificados ? _precios : null),
      );
    } else {
      context.read<TourBloc>().add(CreateTour(tour));
    }
  }

  void _showFinalizarDialog(BuildContext context, String tourId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FinalizarTourDialog(tourId: tourId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = widget.duplicateMode
        ? false
        : (authState is AuthAuthenticated
              ? authState.user.canWrite('tours')
              : true);
    final canDuplicate = authState is AuthAuthenticated
        ? authState.user.canWrite('historico_tours')
        : true;

    return BlocListener<TourBloc, TourState>(
      listener: (context, state) async {
        if (state is TourDetailLoaded) {
          Navigator.of(context, rootNavigator: true).pop();
          if (mounted) setState(() => _updateFieldsFromTour(state.tour));
          final busIds = state.tour.busLayoutIds ?? [];
          if (busIds.isNotEmpty) {
            _loadAgentesForAllBuses(state.tour.id, busIds);
          }
          final now = DateTime.now();
          final end = state.tour.endDate;
          final start = state.tour.startDate;
          if (end != null &&
              start != null &&
              end.isBefore(now) &&
              start.isBefore(now)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showFinalizarDialog(context, state.tour.id);
            });
          }
        } else if (state is TourError && _isLoadingFullData) {
          Navigator.of(context, rootNavigator: true).pop();
          if (mounted) setState(() => _isLoadingFullData = false);
          SaasSnackBar.showError(
            context,
            'Error al cargar detalle: ${state.message}',
          );
        }

        if (state is TourDuplicado) {
          SaasSnackBar.showSuccess(context, 'Tour duplicado exitosamente');
          if (mounted) Navigator.pop(context);
        } else if (state is TourSaved) {
          final tourId = _isEditing ? widget.tour!.id : state.savedTourId;
          if (tourId != null && _agenteSeatsByBus.isNotEmpty) {
            await _saveAllAgentes(context, tourId);
          }
          SaasSnackBar.showSuccess(
            context,
            'Experiencia guardada exitosamente',
          );
          if (mounted) Navigator.pop(context);
        } else if (state is TourError && !_isLoadingFullData) {
          if (mounted) SaasSnackBar.showError(context, state.message);
        }
      },
      child: PopScope(
        canPop:
            !_isLoadingFullData &&
            (context.watch<TourBloc>().state is! TourSaving) &&
            (context.watch<TourBloc>().state is! TourDuplicando),
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            SaasSnackBar.showWarning(
              context,
              'Por favor espera a que termine el proceso actual',
            );
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  PremiumSliverAppBar(
                    title: widget.duplicateMode
                        ? 'Detalle Histórico'
                        : (_isEditing && !canWrite
                              ? 'Ver Experiencia'
                              : (_isEditing
                                    ? 'Configurar Experiencia'
                                    : 'Nueva Aventura')),
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
                                    const SizedBox(height: 20),
                                    _buildTipoTourDropdown(canWrite: canWrite),
                                    const SizedBox(height: 20),
                                    _buildDisponibilidadTipoSelector(
                                      canWrite: canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildBusLayoutDropdown(canWrite: canWrite),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                PremiumSectionCard(
                                  title: 'DETALLES DE VIAJE',
                                  icon: Icons.flight_takeoff_rounded,
                                  children: [
                                    if (_disponibilidadTipo ==
                                        'fecha_fija') ...[
                                      Row(
                                        children: [
                                          if (_modoPrecio == 'individual') ...[
                                            Expanded(
                                              child: PremiumTextField(
                                                controller: _priceCtrl,
                                                label: 'Precio (COP) *',
                                                icon:
                                                    Icons.attach_money_rounded,
                                                isNumeric: true,
                                                readOnly: !canWrite,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                          ],
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
                                    ] else if (_modoPrecio == 'individual') ...[
                                      PremiumTextField(
                                        controller: _priceCtrl,
                                        label: 'Precio (COP) *',
                                        icon: Icons.attach_money_rounded,
                                        isNumeric: true,
                                        readOnly: !canWrite,
                                        inputFormatters: [
                                          ThousandsSeparatorInputFormatter(),
                                        ],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                      ),
                                    ],
                                    if (_disponibilidadTipo ==
                                        'fecha_fija') ...[
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
                                                cuposDisponibles: widget
                                                    .tour!
                                                    .cuposDisponibles,
                                                cuposTotales:
                                                    widget.tour!.cupos!,
                                              ),
                                            ),
                                          ] else
                                            const Expanded(child: SizedBox()),
                                        ],
                                      ),
                                    ] else if (_disponibilidadTipo ==
                                        'permanente') ...[
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.saas.bgSubtle,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(
                                            color: context.saas.border,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.all_inclusive_rounded,
                                              color: context.saas.brand600,
                                              size: 18,
                                            ),
                                            SizedBox(width: 12),
                                            Text(
                                              'Cupos ilimitados',
                                              style: TextStyle(
                                                color:
                                                    context.saas.textSecondary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
                                if (_disponibilidadTipo ==
                                    'multiples_fechas') ...[
                                  const SizedBox(height: 20),
                                  _buildSalidasSection(canWrite: canWrite),
                                ],
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
                                    const SizedBox(height: 24),
                                    _buildImagenesSection(canWrite: canWrite),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                PremiumSectionCard(
                                  title: 'DESCRIPCIÓN Y RECOMENDACIONES',
                                  icon: Icons.article_rounded,
                                  children: [
                                    _buildTextAreaField(
                                      ctrl: _descripcionCtrl,
                                      scrollCtrl: _descripcionScrollCtrl,
                                      label: 'DESCRIPCIÓN',
                                      hint: 'Describe el tour de forma detallada...',
                                      icon: Icons.description_rounded,
                                      canWrite: canWrite,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildTextAreaField(
                                      ctrl: _recomendacionesCtrl,
                                      scrollCtrl: _recomendacionesScrollCtrl,
                                      label: 'RECOMENDACIONES',
                                      hint: 'Qué llevar, recomendaciones para los viajeros...',
                                      icon: Icons.tips_and_updates_rounded,
                                      canWrite: canWrite,
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
                                      context.saas.success,
                                      canWrite: canWrite,
                                    ),
                                    const SizedBox(height: 28),
                                    _buildDynamicList(
                                      'Exclusiones *',
                                      _exclusionCtrl,
                                      _exclusions,
                                      Icons.cancel_rounded,
                                      context.saas.danger,
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
                                if (widget.duplicateMode && canDuplicate)
                                  _buildDuplicateAction()
                                else if (canWrite)
                                  _buildBottomActions(),
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
              BlocBuilder<TourBloc, TourState>(
                builder: (context, state) {
                  if (state is TourSaving) {
                    return const DialogLoadingNetwork(
                      titel: 'Guardando cambios...',
                    );
                  }
                  if (state is TourDuplicando) {
                    return const DialogLoadingNetwork(
                      titel: 'Duplicando tour...',
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
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
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
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
                  title: 'PRECIOS',
                  icon: Icons.sell_rounded,
                ),
              ),
              if (canWrite) _buildModoPrecioToggle(),
            ],
          ),
          const SizedBox(height: 20),
          if (_modoPrecio == 'grupal')
            _buildPreciosGrupalesContent(canWrite, fmt)
          else
            _buildPreciosIndividualesContent(canWrite, fmt),
        ],
      ),
    );
  }

  Widget _buildModoPrecioToggle() {
    return Container(
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.saas.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModePill(
            label: 'Por persona',
            selected: _modoPrecio == 'individual',
            onTap: () => setState(() => _modoPrecio = 'individual'),
          ),
          _ModePill(
            label: 'Grupal',
            selected: _modoPrecio == 'grupal',
            onTap: () => setState(() => _modoPrecio = 'grupal'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreciosIndividualesContent(bool canWrite, NumberFormat fmt) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'CATEGORÍAS DE PRECIO',
                style: TextStyle(
                  color: context.saas.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (canWrite)
              _MiniAddButton(
                label: 'PRECIO',
                onTap: () => _showAgregarPrecioSheet(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_precios.isEmpty)
          const PremiumEmptyIndicator(
            msg:
                'Opcional — agrega categorías de precio por edad o punto de salida.',
            icon: Icons.local_offer_rounded,
          )
        else
          ..._precios.asMap().entries.map(
            (e) => _PrecioCard(
              precio: e.value,
              fmt: fmt,
              canWrite: canWrite,
              onRemove: () => _confirmDeletePrecio(e.key),
            ),
          ),
      ],
    );
  }

  Widget _buildPreciosGrupalesContent(bool canWrite, NumberFormat fmt) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'RANGOS DE PRECIO GRUPAL',
                style: TextStyle(
                  color: context.saas.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (canWrite)
              _MiniAddButton(
                label: 'RANGO',
                onTap: () => _showAgregarPrecioGrupalSheet(),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'El precio es fijo por rango. Los rangos deben cubrir todos los tamaños de grupo posibles.',
          style: TextStyle(color: context.saas.textTertiary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        if (_preciosGrupales.isEmpty)
          const PremiumEmptyIndicator(
            msg:
                'Agrega rangos de personas con su precio fijo correspondiente.',
            icon: Icons.groups_rounded,
          )
        else
          ..._preciosGrupales.asMap().entries.map(
            (e) => _PrecioGrupalCard(
              precio: e.value,
              fmt: fmt,
              canWrite: canWrite,
              onRemove: () => _confirmDeletePrecioGrupal(e.key),
            ),
          ),
      ],
    );
  }

  void _showAgregarPrecioGrupalSheet() {
    showModalBottomSheet<PrecioGrupal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GrupalPriceSheet(),
    ).then((resultado) {
      if (resultado != null && mounted) {
        setState(() => _preciosGrupales.add(resultado));
      }
    });
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
            decoration: BoxDecoration(
              color: context.saas.bgCanvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Agregar precio',
                        style: TextStyle(
                          color: context.saas.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.saas.textTertiary,
                      ),
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
                    Expanded(
                      child: Text(
                        'Activo',
                        style: TextStyle(
                          color: context.saas.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Switch(
                      value: activo,
                      activeColor: context.saas.brand600,
                      onChanged: (v) => setSheetState(() => activo = v),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.saas.brand600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (descCtrl.text.trim().isEmpty ||
                          precioCtrl.text.trim().isEmpty)
                        return;
                      final nuevo = TourPrecio(
                        descripcion: descCtrl.text.trim(),
                        precio:
                            double.tryParse(
                              precioCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                            ) ??
                            0,
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
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
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

  Widget _buildImagenesSection({required bool canWrite}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'GALERÍA DE IMÁGENES',
                style: TextStyle(
                  color: context.saas.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            if (canWrite)
              Text(
                '${_imagenes.length} imagen${_imagenes.length == 1 ? '' : 'es'}',
                style: TextStyle(
                  color: context.saas.textTertiary,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (canWrite)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: PremiumTextField(
                  controller: _imagenCtrl,
                  label: 'URL de imagen',
                  icon: Icons.image_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: _GaleriaBtn(
                  onPressed: () async {
                    final url = await GalleryPickerDialog.show(
                      context,
                      isAdmin: true,
                    );
                    if (url != null && mounted) {
                      setState(() {
                        if (!_imagenes.contains(url)) _imagenes.add(url);
                        _imagenCtrl.clear();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _CircleAddButton(
                  color: context.saas.brand600,
                  onTap: () {
                    final url = _imagenCtrl.text.trim();
                    if (url.isNotEmpty) {
                      setState(() => _imagenes.add(url));
                      _imagenCtrl.clear();
                    }
                  },
                ),
              ),
            ],
          ),
        if (_imagenes.isEmpty) ...[
          const SizedBox(height: 12),
          const PremiumEmptyIndicator(
            msg: 'Sin imágenes — agrega URLs para la galería del tour.',
            icon: Icons.photo_library_rounded,
          ),
        ] else ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _imagenes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _ImagenThumbnail(
                url: _imagenes[index],
                canWrite: canWrite,
                onDelete: () => _confirmDeleteImagen(index),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _confirmDeletePrecio(int index) {
    final precio = _precios[index];
    _showDeleteDialog(
      title: 'Eliminar precio',
      body: '¿Eliminar la categoría "${precio.descripcion}"?',
      onConfirm: () => setState(() {
        _precios.removeAt(index);
        _preciosModificados = true;
      }),
    );
  }

  void _confirmDeletePrecioGrupal(int index) {
    final rango = _preciosGrupales[index];
    final label = rango.descripcion?.isNotEmpty == true
        ? rango.descripcion!
        : '${rango.minPersonas}–${rango.maxPersonas} personas';
    _showDeleteDialog(
      title: 'Eliminar rango grupal',
      body: '¿Eliminar el rango "$label"?',
      onConfirm: () => setState(() => _preciosGrupales.removeAt(index)),
    );
  }

  void _showDeleteDialog({
    required String title,
    required String body,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.saas.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.saas.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_rounded,
                color: context.saas.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: context.saas.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          body,
          style: TextStyle(
            color: context.saas.textSecondary,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(color: context.saas.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.saas.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteImagen(int index) {
    _showDeleteDialog(
      title: 'Eliminar imagen',
      body: '¿Eliminar esta imagen de la galería?',
      onConfirm: () => setState(() => _imagenes.removeAt(index)),
    );
  }

  Widget _buildTextAreaField({
    required TextEditingController ctrl,
    required ScrollController scrollCtrl,
    required String label,
    required String hint,
    required IconData icon,
    required bool canWrite,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: context.saas.brand600, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: context.saas.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(opcional)',
              style: TextStyle(
                color: context.saas.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Scrollbar(
          controller: scrollCtrl,
          thumbVisibility: true,
          child: TextFormField(
            controller: ctrl,
            scrollController: scrollCtrl,
            readOnly: !canWrite,
            maxLines: 5,
            minLines: 5,
            style: TextStyle(
              color: context.saas.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: context.saas.textTertiary,
                fontSize: 13,
              ),
              filled: true,
              fillColor: canWrite ? context.saas.bgCanvas : context.saas.bgSubtle,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.saas.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: context.saas.brand600,
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.saas.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
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
          final selectedSede = sedes
              .where((s) => s.id == _selectedSedeId)
              .firstOrNull;
          final sedeLabel =
              selectedSede?.nombreSede ??
              (_selectedSedeId != null ? 'Sede #$_selectedSedeId' : '—');

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SEDE DE OPERACIÓN *',
                style: TextStyle(
                  color: context.saas.textSecondary,
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
                    color: context.saas.bgSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: context.saas.border),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.business_rounded,
                        color: context.saas.brand600,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        state is SedeLoading ? 'Cargando...' : sedeLabel,
                        style: TextStyle(
                          color: context.saas.textPrimary,
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
                  dropdownColor: context.saas.bgCanvas,
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.business_rounded,
                      color: context.saas.brand600,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: context.saas.bgCanvas,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: context.saas.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: context.saas.brand600,
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
                    style: TextStyle(
                      color: context.saas.textTertiary,
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

  static const _tipoTourOpciones = [
    ('terrestre', 'Terrestre'),
    ('pasadia', 'Pasadía'),
    ('aereo', 'Aéreo'),
    ('combinado', 'Combinado'),
  ];

  Widget _buildTipoTourDropdown({required bool canWrite}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIPO DE TOUR',
          style: TextStyle(
            color: context.saas.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        if (!canWrite)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.saas.bgSubtle,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.saas.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  color: context.saas.brand600,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  _tipoTourOpciones
                          .where((o) => o.$1 == _tipoTour)
                          .firstOrNull
                          ?.$2 ??
                      '—',
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _tipoTour,
            dropdownColor: context.saas.bgCanvas,
            style: TextStyle(
              color: context.saas.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.category_rounded,
                color: context.saas.brand600,
                size: 18,
              ),
              filled: true,
              fillColor: context.saas.bgCanvas,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: context.saas.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: context.saas.brand600,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            hint: Text(
              'Selecciona el tipo',
              style: TextStyle(color: context.saas.textTertiary, fontSize: 13),
            ),
            items: _tipoTourOpciones
                .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                .toList(),
            onChanged: (val) => setState(() => _tipoTour = val),
          ),
      ],
    );
  }

  Widget _buildDisponibilidadTipoSelector({required bool canWrite}) {
    const options = [
      ('fecha_fija', 'Fecha fija', Icons.event_rounded),
      ('multiples_fechas', 'Múltiples salidas', Icons.date_range_rounded),
      ('permanente', 'Permanente', Icons.all_inclusive_rounded),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TIPO DE DISPONIBILIDAD *',
          style: TextStyle(
            color: context.saas.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = _disponibilidadTipo == opt.$1;
            return Expanded(
              child: GestureDetector(
                onTap: canWrite
                    ? () => setState(() {
                        _disponibilidadTipo = opt.$1;
                        if (opt.$1 != 'fecha_fija') _dateRange = null;
                        if (opt.$1 != 'multiples_fechas') _salidas = [];
                      })
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? context.saas.brand600.withValues(alpha: 0.1)
                        : context.saas.bgSubtle,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? context.saas.brand600
                          : context.saas.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        opt.$3,
                        color: isSelected
                            ? context.saas.brand600
                            : context.saas.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        opt.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected
                              ? context.saas.brand600
                              : context.saas.textSecondary,
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSalidasSection({required bool canWrite}) {
    final fmt = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
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
                  title: 'SALIDAS',
                  icon: Icons.departure_board_rounded,
                ),
              ),
              if (canWrite)
                _MiniAddButton(label: 'SALIDA', onTap: _showAgregarSalidaSheet),
            ],
          ),
          const SizedBox(height: 16),
          if (_salidas.isEmpty)
            const PremiumEmptyIndicator(
              msg: 'Agrega las fechas de salida para este tour.',
              icon: Icons.calendar_month_rounded,
            )
          else
            ..._salidas.asMap().entries.map(
              (e) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.saas.bgSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.saas.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event_rounded,
                      color: context.saas.brand600,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value.label?.isNotEmpty == true
                                ? e.value.label!
                                : '${fmt.format(DateTime.parse(e.value.fechaInicio))} – ${fmt.format(DateTime.parse(e.value.fechaFin))}',
                            style: TextStyle(
                              color: context.saas.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (e.value.label?.isNotEmpty == true)
                            Text(
                              '${fmt.format(DateTime.parse(e.value.fechaInicio))} – ${fmt.format(DateTime.parse(e.value.fechaFin))}',
                              style: TextStyle(
                                color: context.saas.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          if (e.value.cupos != null)
                            Text(
                              '${e.value.cupos} cupos',
                              style: TextStyle(
                                color: context.saas.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (canWrite)
                      IconButton(
                        onPressed: () =>
                            setState(() => _salidas.removeAt(e.key)),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: context.saas.danger,
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAgregarSalidaSheet() {
    final fechaInicioCtrl = TextEditingController();
    final fechaFinCtrl = TextEditingController();
    final cuposCtrl = TextEditingController();
    final labelCtrl = TextEditingController();
    DateTimeRange? salidaRange;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: context.saas.bgCanvas,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Agregar salida',
                        style: TextStyle(
                          color: context.saas.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.saas.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: ctx,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                    );
                    if (range != null) {
                      setSheetState(() {
                        salidaRange = range;
                        fechaInicioCtrl.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(range.start);
                        fechaFinCtrl.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(range.end);
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: context.saas.bgCanvas,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: salidaRange != null
                            ? context.saas.brand600
                            : context.saas.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          color: context.saas.brand600,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          salidaRange == null
                              ? 'Seleccionar fechas *'
                              : '${DateFormat('dd/MM/yyyy').format(salidaRange!.start)} – ${DateFormat('dd/MM/yyyy').format(salidaRange!.end)}',
                          style: TextStyle(
                            color: salidaRange != null
                                ? context.saas.textPrimary
                                : context.saas.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                PremiumTextField(
                  controller: cuposCtrl,
                  label: 'Cupos (opcional)',
                  icon: Icons.people_alt_rounded,
                  isNumeric: true,
                ),
                const SizedBox(height: 14),
                PremiumTextField(
                  controller: labelCtrl,
                  label: 'Etiqueta (ej. Temporada alta)',
                  icon: Icons.label_rounded,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.saas.brand600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      if (salidaRange == null) return;
                      final nueva = TourSalida(
                        id: 0,
                        fechaInicio: DateFormat(
                          'yyyy-MM-dd',
                        ).format(salidaRange!.start),
                        fechaFin: DateFormat(
                          'yyyy-MM-dd',
                        ).format(salidaRange!.end),
                        cupos: int.tryParse(cuposCtrl.text.trim()),
                        label: labelCtrl.text.trim().isEmpty
                            ? null
                            : labelCtrl.text.trim(),
                      );
                      setState(() => _salidas.add(nueva));
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'AGREGAR',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      fechaInicioCtrl.dispose();
      fechaFinCtrl.dispose();
      cuposCtrl.dispose();
      labelCtrl.dispose();
    });
  }

  Widget _buildBusLayoutDropdown({required bool canWrite}) {
    return BlocProvider(
      create: (_) => sl<BusLayoutBloc>()..add(const LoadBusLayouts()),
      child: BlocBuilder<BusLayoutBloc, BusLayoutState>(
        builder: (context, state) {
          final layouts = state is BusLayoutLoaded
              ? state.layouts
              : <BusLayout>[];

          final selectedLayouts = layouts
              .where((l) => _selectedBusLayoutIds.contains(l.id))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BUSES ASIGNADOS *',
                style: TextStyle(
                  color: context.saas.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.saas.bgCanvas,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.saas.border),
                ),
                child: state is BusLayoutLoading
                    ? const SizedBox(
                        height: 36,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ...layouts.map((l) {
                            final isSelected = _selectedBusLayoutIds.contains(
                              l.id,
                            );
                            return FilterChip(
                              label: Text(
                                '${l.nombre} (${l.totalAsientosCliente})',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : context.saas.textPrimary,
                                ),
                              ),
                              avatar: Icon(
                                Icons.directions_bus_rounded,
                                size: 15,
                                color: isSelected
                                    ? Colors.white
                                    : context.saas.brand600,
                              ),
                              selected: isSelected,
                              selectedColor: context.saas.brand600,
                              backgroundColor: context.saas.bgSubtle,
                              checkmarkColor: Colors.white,
                              showCheckmark: false,
                              side: BorderSide(
                                color: isSelected
                                    ? context.saas.brand600
                                    : context.saas.border,
                              ),
                              onSelected: canWrite
                                  ? (val) {
                                      if (l.id == null) return;
                                      setState(() {
                                        if (val) {
                                          _selectedBusLayoutIds.add(l.id!);
                                        } else {
                                          _selectedBusLayoutIds.remove(l.id);
                                          _agenteSeatsByBus.remove(l.id);
                                        }
                                      });
                                    }
                                  : null,
                            );
                          }),
                          if (layouts.isEmpty)
                            Text(
                              'No hay buses disponibles',
                              style: TextStyle(
                                color: context.saas.textTertiary,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
              ),

              // ── Configurar agentes por bus seleccionado ──────────────────
              if (selectedLayouts.isNotEmpty) ...[
                const SizedBox(height: 10),
                ...selectedLayouts.map((l) {
                  final agentes = _agenteSeatsByBus[l.id] ?? {};
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.saas.bgSubtle,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.saas.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_bus_rounded,
                          size: 15,
                          color: context.saas.brand600,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.nombre,
                                style: TextStyle(
                                  color: context.saas.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (agentes.isNotEmpty)
                                Text(
                                  '${agentes.length} asiento${agentes.length == 1 ? '' : 's'} de agente',
                                  style: const TextStyle(
                                    color: Color(0xFFF59E0B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: l.configuracion == null
                              ? null
                              : () async {
                                  final result = await showDialog<Set<String>>(
                                    context: context,
                                    builder: (_) => _AgenteSeatDialog(
                                      layout: l,
                                      initialAgentes: agentes,
                                    ),
                                  );
                                  if (result != null) {
                                    setState(
                                      () => _agenteSeatsByBus[l.id!] = result,
                                    );
                                  }
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF59E0B),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                          icon: const Icon(Icons.person_pin_rounded, size: 14),
                          label: const Text(
                            'Configurar agentes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
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
            color: context.saas.textSecondary,
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
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
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
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
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
            activeColor: context.saas.warning,
          ),
          const SizedBox(width: 24),
          PremiumStatusSwitch(
            label: 'Habilitada al Público',
            value: _isActive,
            onChanged: canWrite ? (v) => setState(() => _isActive = v) : null,
            activeColor: context.saas.success,
          ),
          const SizedBox(width: 24),
          PremiumStatusSwitch(
            label: 'Precio por Pareja',
            value: _precioPorPareja,
            onChanged: canWrite
                ? (v) => setState(() => _precioPorPareja = v)
                : null,
            activeColor: context.saas.brand600,
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateAction() {
    return BlocBuilder<TourBloc, TourState>(
      builder: (context, state) {
        final isDuplicating = state is TourDuplicando;
        return PremiumActionButton(
          label: 'DUPLICAR TOUR',
          icon: Icons.content_copy_rounded,
          isLoading: isDuplicating,
          onTap: () =>
              context.read<TourBloc>().add(DuplicarTour(widget.tour!.id)),
        );
      },
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
          gradient: LinearGradient(
            colors: [context.saas.brand600, context.saas.brand900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.saas.brand600.withValues(alpha: 0.25),
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
      Text(
        'TEMPORADA *',
        style: TextStyle(
          color: context.saas.textSecondary,
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
            color: context.saas.bgCanvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.saas.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.date_range_rounded,
                color: context.saas.brand600,
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
                      ? context.saas.textTertiary
                      : context.saas.textPrimary,
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
      color: context.saas.bgSubtle,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: context.saas.border),
    ),
    child: Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.saas.brand50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: context.saas.brand600.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'DÍA ${index + 1}',
                style: TextStyle(
                  color: context.saas.brand600,
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
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: context.saas.danger,
                  size: 20,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: day.title,
          readOnly: !canWrite,
          style: TextStyle(color: context.saas.textPrimary, fontSize: 14),
          decoration: _fieldDec(context, 'Título del día'),
          onChanged: canWrite ? (v) => onUpdate(day.copyWith(title: v)) : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: day.description,
          readOnly: !canWrite,
          maxLines: 3,
          style: TextStyle(color: context.saas.textPrimary, fontSize: 14),
          decoration: _fieldDec(context, 'Detalles del recorrido'),
          onChanged: canWrite
              ? (v) => onUpdate(day.copyWith(description: v))
              : null,
        ),
      ],
    ),
  );

  InputDecoration _fieldDec(BuildContext context, String label) => InputDecoration(
    labelStyle: TextStyle(color: context.saas.textSecondary, fontSize: 13),
    filled: true,
    fillColor: context.saas.bgCanvas,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: context.saas.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: context.saas.brand600, width: 1.5),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: context.saas.border),
    ),
  ).copyWith(labelText: label);
}

class _GaleriaBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _GaleriaBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.saas.brand600),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.photo_library_rounded,
              color: context.saas.brand600,
              size: 16,
            ),
            SizedBox(width: 5),
            Text(
              'Galería',
              style: TextStyle(
                color: context.saas.brand600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
    style: TextButton.styleFrom(foregroundColor: context.saas.brand600),
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
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  precio.descripcion,
                  style: TextStyle(
                    color: context.saas.textPrimary,
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
                        _SmallBadge(
                          label: edadStr,
                          color: context.saas.brand600,
                        ),
                      if (precio.puntoPartida != null)
                        _SmallBadge(
                          label: 'desde ${precio.puntoPartida}',
                          color: context.saas.textTertiary,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Text(
            fmt.format(precio.precio),
            style: TextStyle(
              color: context.saas.success,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (canWrite) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: context.saas.danger,
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
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
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
        ? context.saas.success
        : porcentaje > 0
        ? context.saas.warning
        : context.saas.danger;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CUPOS DISPONIBLES',
          style: TextStyle(
            color: context.saas.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: context.saas.bgCanvas,
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
                    backgroundColor: context.saas.bgSubtle,
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

class _ImagenThumbnail extends StatelessWidget {
  final String url;
  final bool canWrite;
  final VoidCallback onDelete;

  const _ImagenThumbnail({
    required this.url,
    required this.canWrite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 130,
        height: 130,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AuthNetworkImage(url: url, fit: BoxFit.cover),
            if (canWrite)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
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

class _GrupalPriceSheet extends StatefulWidget {
  const _GrupalPriceSheet();

  @override
  State<_GrupalPriceSheet> createState() => _GrupalPriceSheetState();
}

class _GrupalPriceSheetState extends State<_GrupalPriceSheet> {
  final _minCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _precioCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.saas.bgCanvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Agregar rango grupal',
                    style: TextStyle(
                      color: context.saas.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.saas.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PremiumTextField(
                    controller: _minCtrl,
                    label: 'Mín. personas *',
                    icon: Icons.person_rounded,
                    isNumeric: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PremiumTextField(
                    controller: _maxCtrl,
                    label: 'Máx. personas *',
                    icon: Icons.groups_rounded,
                    isNumeric: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            PremiumTextField(
              controller: _precioCtrl,
              label: 'Precio fijo del rango (COP) *',
              icon: Icons.attach_money_rounded,
              isNumeric: true,
            ),
            const SizedBox(height: 14),
            PremiumTextField(
              controller: _descCtrl,
              label: 'Descripción (opcional)',
              icon: Icons.label_rounded,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.saas.brand600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final min = int.tryParse(_minCtrl.text.trim());
                  final max = int.tryParse(_maxCtrl.text.trim());
                  final precio = double.tryParse(
                    _precioCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  );
                  if (min == null || max == null || precio == null) return;
                  Navigator.pop(
                    context,
                    PrecioGrupal(
                      minPersonas: min,
                      maxPersonas: max,
                      precio: precio,
                      descripcion: _descCtrl.text.trim().isEmpty
                          ? null
                          : _descCtrl.text.trim(),
                    ),
                  );
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
    );
  }
}

class _ModePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? context.saas.brand600 : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : context.saas.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _PrecioGrupalCard extends StatelessWidget {
  final PrecioGrupal precio;
  final NumberFormat fmt;
  final bool canWrite;
  final VoidCallback onRemove;

  const _PrecioGrupalCard({
    required this.precio,
    required this.fmt,
    required this.canWrite,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: context.saas.brand50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.saas.brand600.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.groups_rounded,
                  color: context.saas.brand600,
                  size: 15,
                ),
                const SizedBox(width: 5),
                Text(
                  '${precio.minPersonas}–${precio.maxPersonas}',
                  style: TextStyle(
                    color: context.saas.brand600,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: precio.descripcion != null && precio.descripcion!.isNotEmpty
                ? Text(
                    precio.descripcion!,
                    style: TextStyle(
                      color: context.saas.textSecondary,
                      fontSize: 12,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Text(
            fmt.format(precio.precio),
            style: TextStyle(
              color: context.saas.success,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (canWrite) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onRemove,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: context.saas.danger,
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

class _FinalizarTourDialog extends StatefulWidget {
  final String tourId;
  const _FinalizarTourDialog({required this.tourId});

  @override
  State<_FinalizarTourDialog> createState() => _FinalizarTourDialogState();
}

class _FinalizarTourDialogState extends State<_FinalizarTourDialog> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<TourBloc, TourState>(
      listener: (context, state) {
        if (state is TourFinalizando) {
          if (mounted) setState(() => _loading = true);
        } else if (state is TourFinalizado) {
          // Reload tour list, close dialog and then form screen
          context.read<TourBloc>().add(LoadTours());
          final nav = Navigator.of(context);
          nav.pop(); // close dialog
          nav.pop(); // close form screen → back to tour list
          SaasSnackBar.showSuccess(context, 'Tour finalizado correctamente');
        } else if (state is TourError) {
          if (mounted) setState(() => _loading = false);
        }
      },
      child: AlertDialog(
        backgroundColor: context.saas.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: Colors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Finalizar tour',
              style: TextStyle(
                color: context.saas.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Las fechas de este tour ya han pasado. ¿Deseas marcarlo como finalizado?\n\nEl tour dejará de aparecer en la lista activa pero sus datos y registros se conservarán.',
          style: TextStyle(color: context.saas.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: _loading ? null : () => Navigator.of(context).pop(),
            child: Text(
              'Cancelar',
              style: TextStyle(color: context.saas.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: _loading
                ? null
                : () {
                    context.read<TourBloc>().add(FinalizarTour(widget.tourId));
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Finalizar'),
          ),
        ],
      ),
    );
  }
}

// ── Diálogo para configurar asientos de agente en un bus ──────────────────────

class _AgenteSeatDialog extends StatefulWidget {
  final BusLayout layout;
  final Set<String> initialAgentes;

  const _AgenteSeatDialog({required this.layout, required this.initialAgentes});

  @override
  State<_AgenteSeatDialog> createState() => _AgenteSeatDialogState();
}

class _AgenteSeatDialogState extends State<_AgenteSeatDialog> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialAgentes);
  }

  void _toggleSeat(String numero) {
    setState(() {
      if (_selected.contains(numero)) {
        _selected.remove(numero);
      } else {
        _selected.add(numero);
      }
    });
  }

  Widget _buildCelda(AsientoLayout? layout) {
    if (layout == null || layout.tipo == TipoAsiento.vacio) {
      return const SizedBox(width: 52, height: 52);
    }
    if (layout.tipo == TipoAsiento.bano) {
      return Container(
        width: 44,
        height: 40,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🚽', style: TextStyle(fontSize: 13)),
            Text(
              'Baño',
              style: TextStyle(fontSize: 7, color: Color(0xFF16A34A)),
            ),
          ],
        ),
      );
    }
    if (layout.tipo == TipoAsiento.conductor) {
      return Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_rounded, color: Colors.white54, size: 18),
            Text('Cond.', style: TextStyle(fontSize: 8, color: Colors.white54)),
          ],
        ),
      );
    }
    if (layout.tipo == TipoAsiento.entrada) {
      return Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.confirmation_num_rounded,
              color: Color(0xFF7C3AED),
              size: 18,
            ),
            Text(
              'Entrada',
              style: TextStyle(fontSize: 8, color: Color(0xFF7C3AED)),
            ),
          ],
        ),
      );
    }

    // Normal seat (or agente already set): tappable to toggle agente status.
    final isSelected = _selected.contains(layout.numero);
    final baseColor = isSelected
        ? const Color(0xFFF59E0B)
        : const Color(0xFF3B82F6);

    final cell = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 48,
      height: 48,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.white : baseColor.withValues(alpha: 0.5),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.airline_seat_recline_normal_rounded,
            size: 18,
            color: Colors.white,
          ),
          Text(
            layout.numero,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    return Tooltip(
      message: layout.numero,
      child: GestureDetector(
        onTap: () => _toggleSeat(layout.numero),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: cell),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.layout.configuracion!;
    final mitad = cfg.columnas ~/ 2;
    final maxFila = cfg.asientos.isEmpty
        ? 0
        : cfg.asientos.map((a) => a.fila).reduce((a, b) => a > b ? a : b);
    final layoutByPos = <(int, int), AsientoLayout>{
      for (final a in cfg.asientos) (a.fila, a.columna): a,
    };

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 520,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.saas.bgCanvas,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: context.saas.border)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_pin_rounded,
                      color: Color(0xFFF59E0B),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asientos de Agente',
                            style: TextStyle(
                              color: context.saas.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.layout.nombre,
                            style: TextStyle(
                              color: context.saas.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: context.saas.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              // Instrucción
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toca un asiento normal (azul) para marcarlo como agente (ámbar)',
                        style: TextStyle(
                          color: context.saas.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contador de seleccionados
              if (_selected.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${_selected.length} asiento${_selected.length == 1 ? '' : 's'} seleccionado${_selected.length == 1 ? '' : 's'}: ${_selected.join(', ')}',
                      style: const TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Mapa del bus
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          const _TourBusFront(),
                          const SizedBox(height: 8),
                          ...List.generate(maxFila + 1, (filaIdx) {
                            if (!cfg.asientos.any((a) => a.fila == filaIdx)) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    child: Text(
                                      filaIdx == 0 ? '' : '$filaIdx',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  for (int col = 0; col < cfg.columnas; col++)
                                    if (col == mitad)
                                      const SizedBox(width: 20)
                                    else
                                      _buildCelda(layoutByPos[(filaIdx, col)]),
                                  const SizedBox(width: 4),
                                  const SizedBox(width: 24),
                                ],
                              ),
                            );
                          }),
                          const _TourBusBack(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Botones
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _selected.clear()),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.saas.textSecondary,
                          side: BorderSide(color: context.saas.border),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pop(context, Set<String>.from(_selected)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'CONFIRMAR',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bus shape decorations ─────────────────────────────────────────────────────

class _TourBusFront extends StatelessWidget {
  const _TourBusFront();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_road_rounded, color: Colors.white38, size: 14),
          SizedBox(width: 8),
          Text(
            'FRENTE DEL BUS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.remove_road_rounded, color: Colors.white38, size: 14),
        ],
      ),
    );
  }
}

class _TourBusBack extends StatelessWidget {
  const _TourBusBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.remove_road_rounded, color: Colors.white38, size: 14),
          SizedBox(width: 8),
          Text(
            'PARTE TRASERA',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          SizedBox(width: 8),
          Icon(Icons.remove_road_rounded, color: Colors.white38, size: 14),
        ],
      ),
    );
  }
}
