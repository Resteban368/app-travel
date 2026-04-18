import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/entities/integrante.dart';
import '../../domain/entities/aerolinea.dart';
import '../../domain/entities/vuelo_reserva.dart';
import '../../domain/repositories/reserva_repository.dart';
import '../../../../core/widgets/platform_network_image.dart';
import '../bloc/reserva_bloc.dart';
import '../bloc/reserva_event.dart';
import '../bloc/reserva_state.dart';
import '../../../../features/tour/presentation/bloc/tour_bloc.dart';
import '../../../../features/tour/domain/entities/tour.dart';
import '../../../../features/service/presentation/bloc/service_bloc.dart';
import '../../../../features/service/presentation/bloc/service_event.dart';
import '../../../../features/service/presentation/bloc/service_state.dart';
import '../../../../features/service/domain/entities/service.dart';
import '../../../../features/pagos_realizados/domain/entities/pago_realizado.dart';
import '../../../../features/pagos_realizados/domain/repositories/pago_realizado_repository.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../../features/clientes/presentation/bloc/cliente_bloc.dart';
import '../../../../features/clientes/presentation/bloc/cliente_event.dart';
import '../../../../features/clientes/presentation/bloc/cliente_state.dart';
import '../../../../features/clientes/domain/entities/cliente.dart';
import '../../../../features/clientes/domain/repositories/cliente_repository.dart';
import '../../../../features/clientes/presentation/screens/cliente_form_screen.dart';
import 'dart:ui';

class ReservaFormScreen extends StatefulWidget {
  final Reserva? reserva;
  const ReservaFormScreen({super.key, this.reserva});

  @override
  State<ReservaFormScreen> createState() => _ReservaFormScreenState();
}

class _ReservaFormScreenState extends State<ReservaFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  // Basic info control
  late final TextEditingController _notasCtrl;
  String _estado = 'pendiente';
  String _tipoReserva = 'tour';

  // Pagos de la reserva (solo en edición)
  List<PagoRealizado> _pagos = [];
  bool _loadingPagos = false;

  // Tour card expandida
  bool _tourCardExpanded = false;

  // Cliente responsable
  int? _selectedClienteId;
  Cliente? _selectedCliente;
  bool _loadingResponsable = false;

  // Tour control
  String? _selectedTourId;
  final _tourSearchCtrl = TextEditingController();
  final _idReservaCtrl = TextEditingController();

  // Aerolíneas y vuelos
  List<Aerolinea> _aerolineas = [];
  bool _loadingAerolineas = false;
  List<VueloReserva> _vuelos = [];

  // Dynamic lists
  List<Integrante> _integrantes = [];
  List<int> _servicios = [];

  late final AnimationController _entryCtrl;

  bool get _isEditing => widget.reserva != null;

  @override
  void initState() {
    super.initState();

    _notasCtrl = TextEditingController(text: widget.reserva?.notas ?? '');

    if (_isEditing) {
      _estado = widget.reserva!.estado;
      _tipoReserva = widget.reserva!.tipoReserva;
      _selectedClienteId = widget.reserva!.idResponsable;
      _selectedTourId =
          (widget.reserva!.idTour != null && widget.reserva!.idTour!.isNotEmpty)
          ? widget.reserva!.idTour
          : null;
      _integrantes = List.from(widget.reserva!.integrantes);
      _servicios = List.from(widget.reserva!.serviciosIds);
      _vuelos = List.from(widget.reserva!.vuelos);
      if (widget.reserva!.tour != null) {
        _tourSearchCtrl.text = widget.reserva!.tour!.name;
      }
      _idReservaCtrl.text = widget.reserva!.idReserva ?? '';
      // Pre-cargar responsable embebido si el API lo devolvió
      if (widget.reserva!.responsable != null) {
        _selectedCliente = widget.reserva!.responsable;
      }
      _loadPagos();
    }

    _loadAerolineas();

    // Attempt to load tours if not loaded
    final tourState = context.read<TourBloc>().state;
    if (tourState is TourInitial || tourState is TourError) {
      context.read<TourBloc>().add(LoadTours());
    }

    final serviceState = context.read<ServiceBloc>().state;
    if (serviceState is ServiceInitial || serviceState is ServiceError) {
      context.read<ServiceBloc>().add(LoadServices());
    }

    final clienteState = context.read<ClienteBloc>().state;
    if (clienteState is ClienteInitial || clienteState is ClienteError) {
      context.read<ClienteBloc>().add(LoadClientes());
    }

    // Si editamos y hay responsable asignado, cargarlo directamente por ID
    debugPrint(
      '🔍 [ReservaForm] isEditing=$_isEditing, idResponsable=${widget.reserva?.idResponsable}, _selectedClienteId=$_selectedClienteId, responsableEmbedded=${_selectedCliente?.nombre}',
    );
    if (_isEditing && _selectedClienteId != null && _selectedCliente == null) {
      _loadingResponsable = true;
      _loadClienteResponsable(_selectedClienteId!);
    }

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _notasCtrl.dispose();
    _tourSearchCtrl.dispose();
    _idReservaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPagos() async {
    final reservaIdInt = int.tryParse(widget.reserva?.id ?? '');
    debugPrint(
      '🔍 [_loadPagos] widget.reserva.id=${widget.reserva?.id}, parsed=$reservaIdInt',
    );
    if (reservaIdInt == null) return;
    setState(() => _loadingPagos = true);
    try {
      final pagos = await sl<PagoRealizadoRepository>().getPagosByReserva(
        reservaIdInt,
      );
      setState(
        () => _pagos = pagos.where((p) => p.reservaId == reservaIdInt).toList(),
      );
      debugPrint('✅ [_loadPagos] Loaded ${_pagos.length} pagos');
    } catch (e, stack) {
      debugPrint('❌ [_loadPagos] Error Loading Pagos: $e\n$stack');
      // Silencioso UI
    } finally {
      setState(() => _loadingPagos = false);
    }
  }

  Future<void> _loadClienteResponsable(int id) async {
    debugPrint('🔍 [ReservaForm] Loading responsable by id=$id');
    try {
      final cliente = await sl<ClienteRepository>().getClienteById(id);
      debugPrint(
        '✅ [ReservaForm] Got responsable: ${cliente.nombre} (id=${cliente.id})',
      );
      if (mounted) {
        setState(() {
          _selectedCliente = cliente;
          _loadingResponsable = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [ReservaForm] Error loading responsable: $e');
      if (mounted) setState(() => _loadingResponsable = false);
    }
  }

  Future<void> _loadAerolineas() async {
    if (mounted) setState(() => _loadingAerolineas = true);
    try {
      final aerolineas = await sl<ReservaRepository>().getAerolineas();
      if (mounted) setState(() => _aerolineas = aerolineas);
    } catch (e) {
      debugPrint('❌ [ReservaForm] Error loading aerolíneas: $e');
    } finally {
      if (mounted) setState(() => _loadingAerolineas = false);
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    if (_tipoReserva == 'tour' && _selectedTourId == null) {
      _showMsg('Debe seleccionar un tour.', D.rose);
      return;
    }

    final reserva = Reserva(
      id: _isEditing ? widget.reserva!.id : null,
      tipoReserva: _tipoReserva,
      idTour: _tipoReserva == 'tour' ? _selectedTourId : null,
      correo: _selectedCliente?.correo ?? widget.reserva?.correo ?? '',
      estado: _estado,
      notas: _notasCtrl.text.trim(),
      serviciosIds: _servicios.where((s) => s != 0).toList(),
      integrantes: _integrantes,
      vuelos: _vuelos,
      idResponsable: _selectedClienteId,
      fechaCreacion: _isEditing
          ? widget.reserva!.fechaCreacion
          : DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );

    if (_isEditing) {
      context.read<ReservaBloc>().add(UpdateReserva(reserva));
    } else {
      context.read<ReservaBloc>().add(CreateReserva(reserva));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReservaBloc, ReservaState>(
      listener: (context, state) {
        if (state is ReservaActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing ? 'Reserva actualizada' : 'Reserva creada',
              ),
              backgroundColor: D.emerald,
            ),
          );

          context.read<ReservaBloc>().add(const LoadReservas());
          Navigator.pop(context);
        } else if (state is ReservaError) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: D.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: D.rose.withValues(alpha: 0.4)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: D.rose.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_rounded,
                        color: D.rose,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error al guardar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: D.slate400, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: D.rose,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
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
                  title: _isEditing ? 'Editar Reserva' : 'Nueva Reserva',
                  actions:
                      //flecha de atras
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: D.white),
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
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 900),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildResponsableSection(),
                              const SizedBox(height: 24),
                              _buildBasicInfoSection(),
                              const SizedBox(height: 24),
                              _buildVuelosSection(),
                              const SizedBox(height: 24),
                              _buildIntegrantesSection(),
                              const SizedBox(height: 24),
                              _buildServiciosSection(),
                              const SizedBox(height: 24),
                              _buildNotasSection(),
                              const SizedBox(height: 24),
                              if (_isEditing) ...[
                                _buildPagosSection(),
                                const SizedBox(height: 24),
                              ],
                              _buildResumenSection(),
                              const SizedBox(height: 32),
                              Builder(
                                builder: (context) {
                                  final authState = context
                                      .read<AuthBloc>()
                                      .state;
                                  final canWrite =
                                      authState is AuthAuthenticated &&
                                      authState.user.canWrite('reservas');
                                  if (!canWrite && _isEditing)
                                    return const SizedBox.shrink();
                                  return _buildSubmitButton();
                                },
                              ),
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
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return PremiumSectionCard(
      title: 'DATOS DE LA RESERVA',
      icon: Icons.assignment_rounded,
      children: [
        if (_isEditing) ...[
          PremiumTextField(
            controller: _idReservaCtrl,
            label: 'ID de Reserva',
            icon: Icons.qr_code_rounded,
            readOnly: true,
          ),
          const SizedBox(height: 24),
        ],
        _buildTipoReservaSelector(),
        const SizedBox(height: 24),
        if (_tipoReserva == 'tour') ...[
          _buildTourDropdown(),
          const SizedBox(height: 24),
        ],
        _buildStatusDropdown(),
      ],
    );
  }

  Widget _buildTipoReservaSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Reserva *',
          style: TextStyle(
            color: D.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _TipoReservaChip(
              label: 'Tour',
              icon: Icons.terrain_rounded,
              selected: _tipoReserva == 'tour',
              onTap: () => setState(() {
                _tipoReserva = 'tour';
              }),
            ),
            const SizedBox(width: 12),
            _TipoReservaChip(
              label: 'Vuelos',
              icon: Icons.flight_rounded,
              selected: _tipoReserva == 'vuelos',
              onTap: () => setState(() {
                _tipoReserva = 'vuelos';
                _selectedTourId = null;
                _tourSearchCtrl.clear();
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTourDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tour o Promoción *',
          style: TextStyle(
            color: D.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<TourBloc, TourState>(
          builder: (context, state) {
            final isLoading = state is TourLoading;
            List<Tour> tours = [];
            if (state is ToursLoaded) {
              tours = state.tours;
            } else if (state is TourSaved && state.tours != null) {
              tours = state.tours!;
            }

            final selectedTour = _selectedTourId != null
                ? tours.firstWhere(
                    (t) => t.id == _selectedTourId,
                    orElse: () => Tour(
                      id: '',
                      idTour: 0,
                      name: '',
                      agency: '',
                      startDate: DateTime.now(),
                      endDate: DateTime.now(),
                      price: 0,
                      departurePoint: '',
                      departureTime: '',
                      arrival: '',
                      pdfLink: '',
                      inclusions: [],
                      exclusions: [],
                      itinerary: [],
                      imageUrl: '',
                    ),
                  )
                : null;
            final isTourFound =
                selectedTour != null && selectedTour.id.isNotEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botón selector
                FormField<String>(
                  validator: (_) =>
                      _selectedTourId == null ? 'Selecciona un tour' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: isLoading
                            ? null
                            : () async {
                                final result = await showDialog<Tour>(
                                  context: context,
                                  builder: (_) =>
                                      _TourPickerDialog(tours: tours),
                                );
                                if (result != null) {
                                  setState(() {
                                    _selectedTourId = result.id;
                                    _tourSearchCtrl.text = result.name;
                                    _tourCardExpanded = false;
                                  });
                                  field.didChange(result.id);
                                }
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: D.bg.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: field.hasError
                                  ? D.rose
                                  : isTourFound
                                  ? D.skyBlue
                                  : D.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tour_rounded,
                                color: isTourFound ? D.skyBlue : D.slate600,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isTourFound
                                      ? _tourSearchCtrl.text
                                      : 'Seleccionar tour...',
                                  style: TextStyle(
                                    color: isTourFound
                                        ? Colors.white
                                        : D.slate400,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLoading)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: D.skyBlue,
                                  ),
                                )
                              else if (isTourFound)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedTourId = null;
                                    _tourSearchCtrl.clear();
                                  }),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: D.slate400,
                                    size: 18,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.search_rounded,
                                  color: D.slate600,
                                  size: 18,
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 6),
                        Text(
                          field.errorText!,
                          style: TextStyle(color: D.rose, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),

                // Tour info card
                if (isTourFound) ...[
                  const SizedBox(height: 16),
                  _buildTourInfoCard(selectedTour),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTourInfoCard(Tour tour) {
    final currencyFmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd MMM yyyy', 'es_CO');

    return Container(
      decoration: BoxDecoration(
        color: D.bg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: D.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Si no hay imagen, mostrar nombre y badges aquí
                if (tour.imageUrl.isEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (tour.isPromotion)
                        _TourBadge(
                          label: 'PROMO',
                          color: D.gold,
                          icon: Icons.star_rounded,
                        ),
                      if (tour.precioPorPareja)
                        _TourBadge(
                          label: 'POR PAREJA',
                          color: D.skyBlue,
                          icon: Icons.people_rounded,
                        ),
                      if (!tour.isActive)
                        _TourBadge(
                          label: 'INACTIVO',
                          color: D.rose,
                          icon: Icons.block_rounded,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    tour.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Precio ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      currencyFmt.format(tour.price),
                      style: const TextStyle(
                        color: D.emerald,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      tour.precioPorPareja ? 'por pareja' : 'por persona',
                      style: TextStyle(color: D.slate400, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: D.border),
                const SizedBox(height: 12),

                // ── Datos logísticos ─────────────────────────
                _TourInfoRow(
                  icon: Icons.business_rounded,
                  label: 'Agencia',
                  value: tour.agency,
                ),
                const SizedBox(height: 10),
                _TourInfoRow(
                  icon: Icons.date_range_rounded,
                  label: 'Fechas',
                  value:
                      '${dateFmt.format(tour.startDate)} → ${dateFmt.format(tour.endDate)}',
                ),
                const SizedBox(height: 10),
                _TourInfoRow(
                  icon: Icons.location_on_rounded,
                  label: 'Punto de partida',
                  value: tour.departurePoint,
                ),
                const SizedBox(height: 10),
                _TourInfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Hora de salida',
                  value: tour.departureTime,
                ),
                const SizedBox(height: 10),
                _TourInfoRow(
                  icon: Icons.flag_rounded,
                  label: 'Llegada',
                  value: tour.arrival,
                ),

                // ── Botón expandir / colapsar ────────────────
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () =>
                      setState(() => _tourCardExpanded = !_tourCardExpanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _tourCardExpanded ? 'Ver menos' : 'Ver más detalles',
                        style: const TextStyle(
                          color: D.skyBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _tourCardExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: D.skyBlue,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Contenido expandible ─────────────────────
                if (_tourCardExpanded) ...[
                  // ── Inclusiones ────────────────────────────
                  if (tour.inclusions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: D.border),
                    const SizedBox(height: 12),
                    _buildListSection(
                      title: 'INCLUYE',
                      color: D.emerald,
                      icon: Icons.check_circle_outline_rounded,
                      items: tour.inclusions,
                    ),
                  ],

                  // ── Exclusiones ────────────────────────────
                  if (tour.exclusions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildListSection(
                      title: 'NO INCLUYE',
                      color: D.rose,
                      icon: Icons.cancel_outlined,
                      items: tour.exclusions,
                    ),
                  ],

                  // ── Itinerario ─────────────────────────────
                  if (tour.itinerary.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: D.border),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            color: D.skyBlue,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ITINERARIO',
                          style: TextStyle(
                            color: D.slate400,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...tour.itinerary.map(
                      (day) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: D.royalBlue.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.dayNumber}',
                                  style: const TextStyle(
                                    color: D.skyBlue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    day.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (day.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      day.description,
                                      style: TextStyle(
                                        color: D.slate400,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // ── PDF link ───────────────────────────────
                  if (tour.pdfLink.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: D.border),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(tour.pdfLink);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_rounded,
                            color: D.rose,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ver PDF del tour',
                            style: TextStyle(
                              color: D.skyBlue,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              decorationColor: D.skyBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection({
    required String title,
    required Color color,
    required IconData icon,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: D.slate400,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: D.white, size: 18),
      hintText: hint,
      hintStyle: const TextStyle(color: D.white, fontSize: 13),
      filled: true,
      fillColor: D.bg.withOpacity(0.3),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: D.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: D.skyBlue),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estado *',
          style: TextStyle(
            color: D.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _estado,
          dropdownColor: D.surface,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration(
            Icons.label_outline_rounded,
            'Estado de la reserva',
          ),
          items: [
            DropdownMenuItem(
              value: 'pendiente',
              child: Row(
                children: const [
                  Icon(Icons.circle, color: Colors.amber, size: 12),
                  SizedBox(width: 8),
                  Text('Pendiente'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'al dia',
              child: Row(
                children: const [
                  Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                  SizedBox(width: 8),
                  Text('Al Día'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'cancelado',
              child: Row(
                children: const [
                  Icon(Icons.circle, color: Colors.redAccent, size: 12),
                  SizedBox(width: 8),
                  Text('Cancelado'),
                ],
              ),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _estado = v);
          },
        ),
      ],
    );
  }

  Widget _buildResponsableSection() {
    return PremiumSectionCard(
      title: 'RESPONSABLE',
      icon: Icons.person_rounded,
      children: [_buildClienteSelector()],
    );
  }

  Widget _buildResumenSection() {
    final currencyFmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return BlocBuilder<TourBloc, TourState>(
      builder: (context, tourState) {
        return BlocBuilder<ServiceBloc, ServiceState>(
          builder: (context, serviceState) {
            List<Tour> tours = [];
            if (tourState is ToursLoaded) {
              tours = tourState.tours;
            } else if (tourState is TourSaved && tourState.tours != null) {
              tours = tourState.tours!;
            }

            List<Service> allServices = [];
            if (serviceState is ServicesLoaded) {
              allServices = serviceState.services;
            } else if (serviceState is ServiceSaved &&
                serviceState.services != null) {
              allServices = serviceState.services!;
            }

            final tour = _selectedTourId != null
                ? tours.cast<Tour?>().firstWhere(
                    (t) => t?.id == _selectedTourId,
                    orElse: () => null,
                  )
                : null;

            final unitPrice = tour?.price ?? 0.0;

            double vuelosTotal = 0;
            for (final v in _vuelos) {
              vuelosTotal += v.precio ?? 0.0;
            }

            // ── Precio unitario ──────────────────────────────────────────────
            // Al editar: derivar el precio-por-unidad del snapshot para no
            // aplicar cambios futuros del tour a reservas ya acordadas.
            // Al crear: usar el precio actual del tour.
            final snapshotTotal =
                _isEditing ? (widget.reserva?.valorTotal ?? 0.0) : null;
            final useSnapshot = snapshotTotal != null && snapshotTotal > 0;

            final precioPorPareja = tour?.precioPorPareja ?? false;
            final currentPersonas = 1 + _integrantes.length;
            final currentUnits = precioPorPareja
                ? (currentPersonas / 2).ceil()
                : currentPersonas;

            final double efectiveUnitPrice;
            final double tourSubtotalFinal;

            if (useSnapshot) {
              // Costo de los servicios ORIGINALES de la reserva (snapshot)
              final originalIds = widget.reserva!.serviciosIds.toSet();
              final originalSvcCost = allServices
                  .where((s) => originalIds.contains(s.id))
                  .fold<double>(0.0, (sum, s) => sum + (s.cost ?? 0));
              final tourBaseSnapshot = snapshotTotal - originalSvcCost;

              final originalPersonas =
                  1 + widget.reserva!.integrantes.length;
              final originalUnits = precioPorPareja
                  ? (originalPersonas / 2).ceil()
                  : originalPersonas;

              efectiveUnitPrice = originalUnits > 0
                  ? tourBaseSnapshot / originalUnits
                  : 0.0;
              tourSubtotalFinal = efectiveUnitPrice * currentUnits;
            } else {
              efectiveUnitPrice = unitPrice;
              tourSubtotalFinal = precioPorPareja
                  ? unitPrice * currentUnits
                  : unitPrice * currentPersonas;
            }

            final String tourUnitLabel;
            if (precioPorPareja) {
              tourUnitLabel =
                  'Tour (${currencyFmt.format(efectiveUnitPrice)}/pareja'
                  ' × $currentUnits pareja${currentUnits != 1 ? "s" : ""})';
            } else {
              tourUnitLabel =
                  'Tour (${currencyFmt.format(efectiveUnitPrice)}/persona'
                  ' × $currentPersonas persona${currentPersonas != 1 ? "s" : ""})';
            }

            // ── Totales ──────────────────────────────────────────────────────
            double serviciosTotal = 0;
            for (final id in _servicios) {
              final svc = allServices.cast<Service?>().firstWhere(
                (s) => s?.id == id,
                orElse: () => null,
              );
              if (svc?.cost != null) serviciosTotal += svc!.cost!;
            }

            final valorTotal =
                tourSubtotalFinal + serviciosTotal + vuelosTotal;

            final totalValidado = _pagos
                .where((p) => p.isValidated)
                .fold(0.0, (sum, p) => sum + p.monto);
            final saldoPendiente = valorTotal - totalValidado;

            return PremiumSectionCard(
              title: 'RESUMEN DE COSTOS',
              icon: Icons.payments_rounded,
              children: [
                // Fila del tour con precio por unidad
                if (_tipoReserva == 'tour')
                  _buildResumenRow(
                    tourUnitLabel,
                    tourSubtotalFinal,
                    currencyFmt,
                    isSubtitle: true,
                  ),
                // Servicios adicionales
                if (_servicios.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._servicios.map((id) {
                    final svc = allServices.cast<Service?>().firstWhere(
                      (s) => s?.id == id,
                      orElse: () => null,
                    );
                    final nombre = svc?.name ?? 'Servicio';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildResumenRow(
                        '+ $nombre',
                        svc?.cost ?? 0,
                        currencyFmt,
                        isSubtitle: true,
                      ),
                    );
                  }),
                ],
                // Vuelos
                if (vuelosTotal > 0) ...[
                  const SizedBox(height: 8),
                  _buildResumenRow(
                    '+ Vuelos',
                    vuelosTotal,
                    currencyFmt,
                    isSubtitle: true,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: D.border),
                ),
                _buildResumenRow(
                  'TOTAL DE LA RESERVA',
                  valorTotal,
                  currencyFmt,
                  isTotal: true,
                ),
                if (_isEditing && totalValidado > 0) ...[
                  const SizedBox(height: 8),
                  _buildResumenRow(
                    '− Pagos validados',
                    totalValidado,
                    currencyFmt,
                    isSubtitle: true,
                    valueColor: D.rose,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: D.border),
                  ),
                  _buildResumenRow(
                    'SALDO PENDIENTE',
                    saldoPendiente,
                    currencyFmt,
                    isTotal: true,
                    valueColor: saldoPendiente <= 0 ? D.emerald : Colors.amber,
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildResumenRow(
    String label,
    double value,
    NumberFormat fmt, {
    bool isSubtitle = false,
    bool isTotal = false,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : D.slate400,
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          fmt.format(value),
          style: TextStyle(
            color: valueColor ?? (isTotal ? D.emerald : D.slate400),
            fontSize: isTotal ? 18 : 13,
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPagosSection() {
    final currencyFmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return PremiumSectionCard(
      title: 'PAGOS REGISTRADOS',
      icon: Icons.payments_rounded,
      children: [
        if (_loadingPagos)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(color: D.skyBlue),
            ),
          )
        else if (_pagos.isEmpty)
          const PremiumEmptyIndicator(
            msg: 'No hay pagos registrados para esta reserva.',
            icon: Icons.pending_actions_rounded,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pagos.length,
            separatorBuilder: (_, __) =>
                const Divider(color: D.border, height: 24),
            itemBuilder: (_, index) {
              final p = _pagos[index];
              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.isValidated
                          ? D.emerald.withValues(alpha: 0.15)
                          : D.slate600.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      p.isValidated
                          ? Icons.verified_rounded
                          : Icons.pending_rounded,
                      color: p.isValidated ? D.emerald : D.slate400,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.metodoPago.isNotEmpty
                              ? p.metodoPago
                              : 'Pago #${p.id}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          p.fechaDocumento.isNotEmpty
                              ? p.fechaDocumento
                              : 'Sin fecha',
                          style: TextStyle(color: D.slate600, fontSize: 11),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.isValidated
                                ? D.emerald.withValues(alpha: 0.15)
                                : p.isRechazado
                                ? D.rose.withValues(alpha: 0.15)
                                : D.slate600.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p.isValidated
                                ? 'Validado'
                                : p.isRechazado
                                ? 'Rechazado'
                                : 'Por validar',
                            style: TextStyle(
                              color: p.isValidated
                                  ? D.emerald
                                  : p.isRechazado
                                  ? D.rose
                                  : D.slate400,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currencyFmt.format(p.monto),
                    style: const TextStyle(
                      color: D.emerald,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              );
            },
          ),
        if (_pagos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: D.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total validado',
                style: TextStyle(
                  color: D.slate400,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                currencyFmt.format(
                  _pagos
                      .where((p) => p.isValidated)
                      .fold(0.0, (sum, p) => sum + p.monto),
                ),
                style: const TextStyle(
                  color: D.skyBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: D.skyBlue, size: 14),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: D.slate400,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildIntegrantesSection() {
    return PremiumSectionCard(
      title: 'INTEGRANTES',
      icon: Icons.group_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(
                  () => _integrantes.add(
                    const Integrante(
                      nombre: '',
                      telefono: '',
                      esResponsable: false,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, color: D.skyBlue, size: 18),
              label: const Text(
                'Agregar',
                style: TextStyle(color: D.skyBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (_integrantes.isEmpty)
          const PremiumEmptyIndicator(
            msg: 'Sin integrantes agregados',
            icon: Icons.person_add_alt_1_rounded,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _integrantes.length,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: D.border, height: 1),
            ),
            itemBuilder: (context, index) {
              return _IntegranteFormFields(
                integrante: _integrantes[index],
                isResponsable: _integrantes[index].esResponsable,
                onChanged: (val) {
                  setState(() => _integrantes[index] = val);
                },
                onDelete: () {
                  setState(() => _integrantes.removeAt(index));
                },
              );
            },
          ),
      ],
    );
  }

  Widget _buildServiciosSection() {
    return PremiumSectionCard(
      title: 'SERVICIOS ADICIONALES',
      icon: Icons.room_service_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() => _servicios.add(0));
              },
              icon: const Icon(Icons.add_rounded, color: D.skyBlue, size: 18),
              label: const Text(
                'Agregar',
                style: TextStyle(color: D.skyBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (_servicios.isEmpty)
          const PremiumEmptyIndicator(
            msg: 'Sin servicios adicionales registrados.',
            icon: Icons.layers_clear_rounded,
          )
        else
          BlocBuilder<ServiceBloc, ServiceState>(
            builder: (context, state) {
              List<Service> services = [];
              if (state is ServicesLoaded) {
                services = state.services;
              } else if (state is ServiceSaved && state.services != null) {
                services = state.services!;
              }

              return Column(
                children: List.generate(_servicios.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _servicios[index] == 0
                                ? null
                                : _servicios[index],
                            dropdownColor: D.surfaceHigh,
                            isExpanded: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            hint: const Text(
                              'Seleccionar servicio',
                              style: TextStyle(color: D.slate400, fontSize: 14),
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.room_service_outlined,
                                color: D.skyBlue,
                              ),
                              filled: true,
                              fillColor: D.surfaceHigh.withOpacity(0.5),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: services
                                .map(
                                  (s) => DropdownMenuItem(
                                    value: s.id,
                                    child: Text(
                                      '${s.name}${s.cost != null ? ' (\$${s.cost!.toStringAsFixed(0)})' : ''}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _servicios[index] = v);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: D.rose,
                          ),
                          onPressed: () =>
                              setState(() => _servicios.removeAt(index)),
                        ),
                      ],
                    ),
                  );
                }),
              );
            },
          ),
      ],
    );
  }

  Widget _buildVuelosSection() {
    return PremiumSectionCard(
      title: 'VUELOS',
      icon: Icons.flight_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _tipoReserva == 'vuelos'
                  ? 'Vuelos de la reserva'
                  : 'Vuelos del tour (opcional)',
              style: TextStyle(color: D.slate400, fontSize: 12),
            ),
            TextButton.icon(
              onPressed: () {
                setState(
                  () => _vuelos.add(
                    VueloReserva(
                      numeroVuelo: '',
                      origen: '',
                      destino: '',
                      fechaSalida: '',
                      fechaLlegada: '',
                      horaSalida: '',
                      horaLlegada: '',
                      clase: 'economy',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add_rounded, color: D.skyBlue, size: 18),
              label: const Text(
                'Agregar vuelo',
                style: TextStyle(color: D.skyBlue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (_vuelos.isEmpty)
          const PremiumEmptyIndicator(
            msg: 'Sin vuelos agregados',
            icon: Icons.airplanemode_inactive_rounded,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _vuelos.length,
            separatorBuilder: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: D.border, height: 1),
            ),
            itemBuilder: (context, index) {
              return _VueloFormFields(
                vuelo: _vuelos[index],
                aerolineas: _aerolineas,
                loadingAerolineas: _loadingAerolineas,
                index: index,
                onChanged: (val) => setState(() => _vuelos[index] = val),
                onDelete: () => setState(() => _vuelos.removeAt(index)),
              );
            },
          ),
      ],
    );
  }

  Widget _buildNotasSection() {
    return PremiumSectionCard(
      title: 'NOTAS DE RESERVA',
      icon: Icons.notes_rounded,
      children: [
        PremiumTextField(
          controller: _notasCtrl,
          label: 'Observaciones (necesidades especiales, etc.)',
          icon: Icons.edit_note_rounded,
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<ReservaBloc, ReservaState>(
      builder: (context, state) {
        return PremiumActionButton(
          label: _isEditing ? 'ACTUALIZAR RESERVA' : 'CONFIRMAR RESERVA',
          icon: _isEditing ? Icons.update_rounded : Icons.check_circle_rounded,
          isLoading: state is ReservaSaving,
          onTap: _save,
        );
      },
    );
  }

  Widget _buildClienteSelector() {
    return BlocBuilder<ClienteBloc, ClienteState>(
      builder: (context, state) {
        final isLoading = state is ClienteLoading;
        List<Cliente> clientes = [];
        if (state is ClienteLoaded) clientes = state.clientes;
        if (state is ClienteActionSuccess) clientes = state.clientes;
        if (state is ClienteSaving) clientes = state.clientes ?? [];

        // Si el _selectedCliente es null pero tenemos la lista, intentar resolverlo
        if (_selectedCliente == null &&
            _selectedClienteId != null &&
            clientes.isNotEmpty) {
          final found = clientes.cast<Cliente?>().firstWhere(
            (c) => c!.id == _selectedClienteId,
            orElse: () => null,
          );
          if (found != null) {
            // Asignar sin setState para evitar rebuild recursivo; ya estamos en builder
            _selectedCliente = found;
            _loadingResponsable = false;
          }
        }

        final Cliente? displayCliente = _selectedCliente;

        debugPrint(
          '🧩 [ClienteSelector] state=${state.runtimeType}, '
          'clientes=${clientes.length}, '
          '_selectedClienteId=$_selectedClienteId, '
          '_selectedCliente=${_selectedCliente?.nombre}, '
          '_loadingResponsable=$_loadingResponsable, '
          'displayCliente=${displayCliente?.nombre}',
        );

        Future<void> openPicker() async {
          final result = await showDialog<Cliente>(
            context: context,
            builder: (_) => _ClientePickerDialog(clientes: clientes),
          );
          if (result != null) {
            setState(() {
              _selectedClienteId = result.id;
              _selectedCliente = result;
            });
          }
        }

        if (displayCliente != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: D.royalBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: D.skyBlue.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: D.royalBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      displayCliente.nombre.isNotEmpty
                          ? displayCliente.nombre[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: D.skyBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayCliente.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Filas de información
                      _buildInfoRow(
                        Icons.email_outlined,
                        displayCliente.correo,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              Icons.phone_outlined,
                              displayCliente.telefono,
                            ),
                          ),
                          if (displayCliente.fechaNacimiento != null)
                            Expanded(
                              child: _buildInfoRow(
                                Icons.cake_outlined,
                                DateFormat(
                                  'dd MMM yyyy',
                                  'es_CO',
                                ).format(displayCliente.fechaNacimiento!),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildInfoRow(
                        Icons.badge_outlined,
                        '${displayCliente.tipoDocumento.toUpperCase()}: ${displayCliente.documento}',
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.swap_horiz_rounded,
                    color: D.skyBlue,
                    size: 20,
                  ),
                  onPressed: isLoading ? null : openPicker,
                  tooltip: 'Cambiar cliente',
                ),
              ],
            ),
          );
        }

        // Responsable en edición pero aún cargando
        if (_loadingResponsable && _selectedClienteId != null) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: D.royalBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: D.skyBlue.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: D.royalBlue.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: D.skyBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cargando responsable...',
                    style: TextStyle(color: D.slate400, fontSize: 14),
                  ),
                ),
              ],
            ),
          );
        }

        // Sin cliente resuelto: mostrar botón de búsqueda
        return FormField<int>(
          validator: (_) =>
              _selectedClienteId == null ? 'Selecciona un cliente' : null,
          builder: (field) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: isLoading ? null : openPicker,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: D.bg.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: field.hasError ? D.rose : D.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.person_search_rounded,
                        color: D.slate600,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isLoading
                              ? 'Cargando clientes...'
                              : 'Seleccionar cliente *',
                          style: TextStyle(color: D.slate400, fontSize: 14),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: D.skyBlue,
                          ),
                        )
                      else
                        const Icon(
                          Icons.search_rounded,
                          color: D.slate600,
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
              if (field.hasError) ...[
                const SizedBox(height: 6),
                Text(
                  field.errorText!,
                  style: TextStyle(color: D.rose, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _IntegranteFormFields extends StatefulWidget {
  final Integrante integrante;
  final bool isResponsable;
  final ValueChanged<Integrante> onChanged;
  final VoidCallback? onDelete;

  const _IntegranteFormFields({
    required this.integrante,
    required this.isResponsable,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_IntegranteFormFields> createState() => _IntegranteFormFieldsState();
}

class _IntegranteFormFieldsState extends State<_IntegranteFormFields> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _documentoCtrl;
  DateTime? _dob;
  late String _tipoDocumento;

  static const _tiposDocumento = ['CC', 'TI', 'Pasaporte'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.integrante.nombre);
    _phoneCtrl = TextEditingController(text: widget.integrante.telefono);
    _documentoCtrl = TextEditingController(text: widget.integrante.documento);
    _dob = widget.integrante.fechaNacimiento;
    _tipoDocumento = _normalizeTipoDocumento(widget.integrante.tipoDocumento);
  }

  static String _normalizeTipoDocumento(String raw) {
    switch (raw.toLowerCase().trim()) {
      case 'cc':
      case 'cedula':
      case 'cédula':
        return 'CC';
      case 'ti':
      case 'tarjeta identidad':
      case 'tarjeta de identidad':
        return 'TI';
      case 'pasaporte':
        return 'Pasaporte';
      default:
        return _tiposDocumento.contains(raw) ? raw : 'CC';
    }
  }

  @override
  void didUpdateWidget(_IntegranteFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.integrante != widget.integrante) {
      _nameCtrl.text = widget.integrante.nombre;
      _phoneCtrl.text = widget.integrante.telefono;
      _documentoCtrl.text = widget.integrante.documento;
      _dob = widget.integrante.fechaNacimiento;
      _tipoDocumento = _normalizeTipoDocumento(widget.integrante.tipoDocumento);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _documentoCtrl.dispose();
    super.dispose();
  }

  void _notifyChange() {
    widget.onChanged(
      Integrante(
        nombre: _nameCtrl.text,
        telefono: _phoneCtrl.text,
        fechaNacimiento: _dob,
        esResponsable: widget.isResponsable,
        tipoDocumento: _tipoDocumento,
        documento: _documentoCtrl.text,
      ),
    );
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
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
        );
      },
    );
    if (picked != null) {
      setState(() => _dob = picked);
      _notifyChange();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: Colors.amber, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Acompañante',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PremiumTextField(
              controller: _nameCtrl,
              label: 'Nombre Completo *',
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 20),
            PremiumTextField(
              controller: _phoneCtrl,
              label: 'Teléfono / WhatsApp',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              isNumeric: true,
            ),
            const SizedBox(height: 20),
            // ── Tipo de documento ──────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIPO DE DOCUMENTO',
                  style: TextStyle(
                    color: D.slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _tiposDocumento.map((tipo) {
                    final selected = _tipoDocumento == tipo;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _tipoDocumento = tipo);
                        _notifyChange();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? D.royalBlue.withOpacity(0.15)
                              : D.bg.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? D.royalBlue.withOpacity(0.6)
                                : D.border,
                          ),
                        ),
                        child: Text(
                          tipo,
                          style: TextStyle(
                            color: selected ? D.royalBlue : D.slate400,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PremiumTextField(
              controller: _documentoCtrl,
              label: 'Número de documento *',
              icon: Icons.badge_outlined,
              keyboardType: TextInputType.number,
              isNumeric: true,
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FECHA DE NACIMIENTO',
                  style: TextStyle(
                    color: D.slate400,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDob,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: D.border),
                      color: D.bg.withOpacity(0.3),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cake_rounded,
                          color: D.skyBlue,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _dob != null
                              ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                              : 'Seleccionar fecha (Opcional)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (widget.onDelete != null && !widget.isResponsable)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: D.rose,
                size: 22,
              ),
              onPressed: widget.onDelete,
            ),
          ),
      ],
    );
  }
}

// ─── Cliente Picker Dialog ────────────────────────────────────────────────────

class _ClientePickerDialog extends StatefulWidget {
  final List<Cliente> clientes;
  const _ClientePickerDialog({required this.clientes});

  @override
  State<_ClientePickerDialog> createState() => _ClientePickerDialogState();
}

class _ClientePickerDialogState extends State<_ClientePickerDialog> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: BlocBuilder<ClienteBloc, ClienteState>(
        builder: (context, state) {
          List<Cliente> currentList = widget.clientes;
          if (state is ClienteLoaded) currentList = state.clientes;
          if (state is ClienteActionSuccess) currentList = state.clientes;

          // Filtrado reactivo
          final q = _searchCtrl.text.toLowerCase().trim();
          final filtered = q.isEmpty
              ? currentList
              : currentList
                    .where(
                      (c) =>
                          c.nombre.toLowerCase().contains(q) ||
                          c.correo.toLowerCase().contains(q) ||
                          c.telefono.contains(q) ||
                          c.documento.toString().contains(q),
                    )
                    .toList();

          return Container(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
            decoration: BoxDecoration(
              color: D.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: D.border),
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_search_rounded,
                        color: D.skyBlue,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Seleccionar Cliente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.person_add_rounded,
                          color: D.skyBlue,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ClienteFormScreen(),
                            ),
                          );
                        },
                        tooltip: 'Nuevo Cliente',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: D.slate400,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (v) =>
                        setState(() {}), // Forzar re-filtrado local
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, correo o documento...',
                      hintStyle: TextStyle(color: D.slate600, fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: D.slate600,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: D.bg.withValues(alpha: 0.5),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: D.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: D.skyBlue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'Sin resultados',
                            style: TextStyle(color: D.slate600, fontSize: 13),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (context, i) =>
                              const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            final c = filtered[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => Navigator.pop(context, c),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: D.royalBlue.withValues(
                                            alpha: 0.1,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            c.nombre.isNotEmpty
                                                ? c.nombre[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: D.skyBlue,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              c.nombre,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '${c.tipoDocumento} ${c.documento}',
                                              style: TextStyle(
                                                color: D.slate400,
                                                fontSize: 12,
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
                          },
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─── Tour Picker Dialog ───────────────────────────────────────────────────────

class _TourPickerDialog extends StatefulWidget {
  final List<Tour> tours;
  const _TourPickerDialog({required this.tours});

  @override
  State<_TourPickerDialog> createState() => _TourPickerDialogState();
}

class _TourPickerDialogState extends State<_TourPickerDialog> {
  final _searchCtrl = TextEditingController();
  List<Tour> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.tours;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.tours
          : widget.tours
                .where((t) => t.name.toLowerCase().contains(q))
                .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 560),
        decoration: BoxDecoration(
          color: D.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: D.border),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  const Icon(Icons.tour_rounded, color: D.skyBlue, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Seleccionar Tour',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: D.slate400,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre del tour...',
                  hintStyle: TextStyle(color: D.slate600, fontSize: 13),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: D.slate600,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: D.bg.withValues(alpha: 0.5),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: D.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: D.skyBlue),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // List
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Sin resultados',
                        style: TextStyle(color: D.slate600, fontSize: 13),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: _filtered.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final t = _filtered[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(context, t),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: D.border.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tour_rounded,
                                    color: D.skyBlue,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      t.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _TourBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _TourBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TourInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: D.slate600, size: 15),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(
              color: D.slate400,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

// ─── Tipo Reserva Chip ───────────────────────────────────────────────────────

class _TipoReservaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TipoReservaChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? D.royalBlue.withValues(alpha: 0.15)
              : D.bg.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? D.royalBlue : D.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? D.skyBlue : D.slate400, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : D.slate400,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vuelo Form Fields ───────────────────────────────────────────────────────

class _VueloFormFields extends StatefulWidget {
  final VueloReserva vuelo;
  final List<Aerolinea> aerolineas;
  final bool loadingAerolineas;
  final int index;
  final ValueChanged<VueloReserva> onChanged;
  final VoidCallback onDelete;

  const _VueloFormFields({
    required this.vuelo,
    required this.aerolineas,
    required this.loadingAerolineas,
    required this.index,
    required this.onChanged,
    required this.onDelete,
  });

  @override
  State<_VueloFormFields> createState() => _VueloFormFieldsState();
}

class _VueloFormFieldsState extends State<_VueloFormFields> {
  late TextEditingController _numeroCtrl;
  late TextEditingController _origenCtrl;
  late TextEditingController _destinoCtrl;
  late TextEditingController _fechaSalidaCtrl;
  late TextEditingController _fechaLlegadaCtrl;
  late TextEditingController _horaSalidaCtrl;
  late TextEditingController _horaLlegadaCtrl;
  late TextEditingController _precioCtrl;
  int? _aerolineaId;
  late String _clase;

  static const _clases = ['economy', 'premium_economy', 'business', 'first'];
  static const _clasesLabel = {
    'economy': 'Economy',
    'premium_economy': 'Premium Economy',
    'business': 'Business',
    'first': 'Primera Clase',
  };

  @override
  void initState() {
    super.initState();
    final v = widget.vuelo;
    _numeroCtrl = TextEditingController(text: v.numeroVuelo);
    _origenCtrl = TextEditingController(text: v.origen);
    _destinoCtrl = TextEditingController(text: v.destino);
    _fechaSalidaCtrl = TextEditingController(text: v.fechaSalida);
    _fechaLlegadaCtrl = TextEditingController(text: v.fechaLlegada);
    _horaSalidaCtrl = TextEditingController(text: v.horaSalida);
    _horaLlegadaCtrl = TextEditingController(text: v.horaLlegada);
    _precioCtrl = TextEditingController(text: v.precio?.toString() ?? '');
    _aerolineaId = v.aerolineaId ?? v.aerolinea?.id;
    _clase = v.clase.isNotEmpty ? v.clase : 'economy';
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _origenCtrl.dispose();
    _destinoCtrl.dispose();
    _fechaSalidaCtrl.dispose();
    _fechaLlegadaCtrl.dispose();
    _horaSalidaCtrl.dispose();
    _horaLlegadaCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  void _notify() {
    final aerolinea = _aerolineaId != null
        ? widget.aerolineas.cast<Aerolinea?>().firstWhere(
            (a) => a?.id == _aerolineaId,
            orElse: () => null,
          )
        : null;
    widget.onChanged(
      VueloReserva(
        id: widget.vuelo.id,
        aerolinea: aerolinea,
        aerolineaId: _aerolineaId,
        numeroVuelo: _numeroCtrl.text.trim(),
        origen: _origenCtrl.text.trim(),
        destino: _destinoCtrl.text.trim(),
        fechaSalida: _fechaSalidaCtrl.text.trim(),
        fechaLlegada: _fechaLlegadaCtrl.text.trim(),
        horaSalida: _horaSalidaCtrl.text.trim(),
        horaLlegada: _horaLlegadaCtrl.text.trim(),
        clase: _clase,
        precio: double.tryParse(_precioCtrl.text.trim().replaceAll(',', '.')),
      ),
    );
  }

  Future<void> _openAerolineaPicker() async {
    final result = await showDialog<Aerolinea>(
      context: context,
      builder: (_) => _AerolineaPickerDialog(aerolineas: widget.aerolineas),
    );
    if (result != null) {
      setState(() => _aerolineaId = result.id);
      _notify();
    }
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: D.royalBlue,
            onPrimary: Colors.white,
            surface: D.surface,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
      _notify();
    }
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, color: D.slate400, size: 18),
    hintText: hint,
    hintStyle: TextStyle(color: D.slate600, fontSize: 13),
    filled: true,
    fillColor: D.bg.withValues(alpha: 0.3),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: D.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: D.skyBlue),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.flight_rounded, color: D.skyBlue, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Vuelo ${widget.index + 1}',
                  style: const TextStyle(
                    color: D.skyBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            // Aerolínea Selector
            Text(
              'Aerolínea *',
              style: TextStyle(
                color: D.slate400,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.loadingAerolineas ? null : _openAerolineaPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: D.bg.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: D.border),
                ),
                child: Row(
                  children: [
                    if (_aerolineaId != null) ...[
                      // Mostrar logo si existe
                      Builder(
                        builder: (context) {
                          final a = widget.aerolineas
                              .cast<Aerolinea?>()
                              .firstWhere(
                                (al) => al?.id == _aerolineaId,
                                orElse: () => null,
                              );
                          if (a != null) {
                            return _AerolineaLogo(aerolinea: a, size: 28);
                          }
                          return const Icon(
                            Icons.business_rounded,
                            color: D.skyBlue,
                            size: 18,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.aerolineas
                                  .cast<Aerolinea?>()
                                  .firstWhere((al) => al?.id == _aerolineaId)
                                  ?.nombre ??
                              'Seleccionar aerolínea',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.business_rounded,
                        color: D.slate400.withValues(alpha: 0.5),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.loadingAerolineas
                              ? 'Cargando aerolíneas...'
                              : 'Seleccionar aerolínea',
                          style: TextStyle(color: D.slate600, fontSize: 14),
                        ),
                      ),
                    ],
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: D.slate400,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Número de vuelo
            TextField(
              controller: _numeroCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _dec(
                'Número de vuelo (ej. LA1234)',
                Icons.tag_rounded,
              ),
              onChanged: (_) => _notify(),
            ),
            const SizedBox(height: 12),
            // Origen / Destino
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _origenCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _dec('Origen', Icons.flight_takeoff_rounded),
                    onChanged: (_) => _notify(),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: D.slate400,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _destinoCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _dec('Destino', Icons.flight_land_rounded),
                    onChanged: (_) => _notify(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Fechas
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(_fechaSalidaCtrl),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _fechaSalidaCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: _dec(
                          'Fecha salida',
                          Icons.calendar_today_rounded,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickDate(_fechaLlegadaCtrl),
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _fechaLlegadaCtrl,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: _dec(
                          'Fecha llegada',
                          Icons.calendar_today_rounded,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Horas
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _horaSalidaCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _dec(
                      'Hora salida (06:00)',
                      Icons.schedule_rounded,
                    ),
                    onChanged: (_) => _notify(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _horaLlegadaCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: _dec('Hora llegada', Icons.schedule_rounded),
                    onChanged: (_) => _notify(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Clase
            DropdownButtonFormField<String>(
              initialValue: _clase,
              dropdownColor: D.surfaceHigh,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _dec(
                'Clase',
                Icons.airline_seat_recline_extra_rounded,
              ),
              items: _clases
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(_clasesLabel[c] ?? c),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _clase = v);
                  _notify();
                }
              },
            ),
            const SizedBox(height: 12),
            // Precio del vuelo (solo si tipo reserva es vuelos o si se desea poner)
            TextField(
              controller: _precioCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _dec('Precio del vuelo ', Icons.attach_money_rounded),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              onChanged: (_) => _notify(),
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: D.rose,
              size: 22,
            ),
            onPressed: widget.onDelete,
          ),
        ),
      ],
    );
  }
}

// ─── Aerolínea Picker Dialog ────────────────────────────────────────────────

class _AerolineaPickerDialog extends StatefulWidget {
  final List<Aerolinea> aerolineas;

  const _AerolineaPickerDialog({required this.aerolineas});

  @override
  State<_AerolineaPickerDialog> createState() => _AerolineaPickerDialogState();
}

class _AerolineaPickerDialogState extends State<_AerolineaPickerDialog> {
  final _searchCtrl = TextEditingController();
  List<Aerolinea> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.aerolineas;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.aerolineas.where((a) {
        return a.nombre.toLowerCase().contains(query) ||
            a.codigoIata.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: D.surface.withValues(alpha: 0.95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business_rounded, color: D.skyBlue),
                      const SizedBox(width: 12),
                      const Text(
                        'Seleccionar Aerolínea',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: D.slate400,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o código IATA...',
                      hintStyle: TextStyle(color: D.slate600, fontSize: 13),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: D.skyBlue,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: D.bg.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                // List
                Flexible(
                  child: _filtered.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40),
                          child: PremiumEmptyIndicator(
                            msg: 'No se encontraron aerolíneas',
                            icon: Icons.search_off_rounded,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final a = _filtered[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context, a),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Logo
                                      _AerolineaLogo(aerolinea: a, size: 40),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              a.nombre,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              a.pais ?? 'Internacional',
                                              style: TextStyle(
                                                color: D.slate400,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: D.royalBlue.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          a.codigoIata,
                                          style: const TextStyle(
                                            color: D.skyBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Aerolínea Logo Widget ───────────────────────────────────────────────────

class _AerolineaLogo extends StatelessWidget {
  final Aerolinea aerolinea;
  final double size;

  const _AerolineaLogo({required this.aerolinea, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final innerSize = size - 12; // descontar padding (6 por lado)
    final hasLogo = aerolinea.logoUrl != null && aerolinea.logoUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: hasLogo
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: buildPlatformNetworkImage(
                aerolinea.logoUrl!,
                height: innerSize,
                fit: BoxFit.contain,
              ),
            )
          : _IataBadge(iata: aerolinea.codigoIata, size: innerSize),
    );
  }
}

class _IataBadge extends StatelessWidget {
  final String iata;
  final double size;

  const _IataBadge({required this.iata, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: D.royalBlue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        iata,
        style: TextStyle(
          color: D.royalBlue,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        overflow: TextOverflow.clip,
      ),
    );
  }
}
