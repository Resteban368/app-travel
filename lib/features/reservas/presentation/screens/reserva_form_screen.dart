import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/entities/integrante.dart';
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

  // Dynamic lists
  List<Integrante> _integrantes = [];
  List<int> _servicios = [];

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;

  bool get _isEditing => widget.reserva != null;

  @override
  void initState() {
    super.initState();

    _notasCtrl = TextEditingController(text: widget.reserva?.notas ?? '');

    if (_isEditing) {
      _estado = widget.reserva!.estado;
      _selectedClienteId = widget.reserva!.idResponsable;
      _selectedTourId = widget.reserva!.idTour.isNotEmpty
          ? widget.reserva!.idTour
          : null;
      _integrantes = List.from(widget.reserva!.integrantes);
      _servicios = List.from(widget.reserva!.serviciosIds);
      if (widget.reserva!.tour != null) {
        _tourSearchCtrl.text = widget.reserva!.tour!.name;
      }
      // Pre-cargar responsable embebido si el API lo devolvió
      if (widget.reserva!.responsable != null) {
        _selectedCliente = widget.reserva!.responsable;
      }
      _loadPagos();
    }

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
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _notasCtrl.dispose();
    _tourSearchCtrl.dispose();
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
      if (mounted)
        setState(() {
          _selectedCliente = cliente;
          _loadingResponsable = false;
        });
    } catch (e) {
      debugPrint('❌ [ReservaForm] Error loading responsable: $e');
      if (mounted) setState(() => _loadingResponsable = false);
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

    if (_selectedTourId == null) {
      _showMsg('Debe seleccionar un tour.', D.rose);
      return;
    }

    final reserva = Reserva(
      id: _isEditing ? widget.reserva!.id : null,
      idTour: _selectedTourId!,
      correo: _selectedCliente?.correo ?? widget.reserva?.correo ?? '',
      estado: _estado,
      notas: _notasCtrl.text.trim(),
      serviciosIds: _servicios.where((s) => s != 0).toList(),
      integrantes: _integrantes,
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          title: Text(
            _isEditing ? 'Editar Reserva' : 'Nueva Reserva',
            style: const TextStyle(fontWeight: FontWeight.w900, color: D.white),
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
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildBasicInfoSection(),
                          const SizedBox(height: 12),
                          _buildResponsableSection(),
                          const SizedBox(height: 12),
                          _buildIntegrantesSection(),
                          const SizedBox(height: 12),
                          _buildServiciosSection(),
                          const SizedBox(height: 12),
                          _buildNotasSection(),
                          const SizedBox(height: 12),
                          if (_isEditing) ...[
                            _buildPagosSection(),
                            const SizedBox(height: 12),
                          ],
                          _buildResumenSection(),
                          const SizedBox(height: 28),
                          Builder(
                            builder: (context) {
                              final authState = context.read<AuthBloc>().state;
                              final canWrite =
                                  authState is AuthAuthenticated &&
                                  authState.user.canWrite('reservas');
                              if (!canWrite && _isEditing)
                                return const SizedBox.shrink();
                              return _buildSubmitButton();
                            },
                          ),
                          const SizedBox(height: 50),
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

  Widget _buildBasicInfoSection() {
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
          _buildSectionHeader('DATOS DE LA RESERVA'),
          const SizedBox(height: 24),
          _buildTourDropdown(),
          const SizedBox(height: 24),
          _buildStatusDropdown(),
        ],
      ),
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
          // ── Imagen ──────────────────────────────────────────
          if (tour.imageUrl.isNotEmpty)
            Stack(
              children: [
                Image.network(
                  tour.imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 180,
                    color: D.surfaceHigh,
                    child: const Icon(
                      Icons.image_not_supported_rounded,
                      color: D.slate600,
                      size: 40,
                    ),
                  ),
                ),
                // Gradiente para leer el nombre sobre la imagen
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // Badges arriba-derecha
                Positioned(
                  top: 12,
                  right: 12,
                  child: Wrap(
                    spacing: 6,
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
                ),
                // Nombre del tour al fondo de la imagen
                Positioned(
                  bottom: 12,
                  left: 16,
                  right: 16,
                  child: Text(
                    tour.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),

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
          _buildSectionHeader('RESPONSABLE DE LA RESERVA'),
          const SizedBox(height: 8),
          Text(
            'Selecciona el cliente registrado que será el responsable.',
            style: TextStyle(color: D.slate600, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _buildClienteSelector(),
        ],
      ),
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
            if (tourState is ToursLoaded)
              tours = tourState.tours;
            else if (tourState is TourSaved && tourState.tours != null)
              tours = tourState.tours!;

            List<Service> allServices = [];
            if (serviceState is ServicesLoaded)
              allServices = serviceState.services;
            else if (serviceState is ServiceSaved &&
                serviceState.services != null)
              allServices = serviceState.services!;

            final tour = _selectedTourId != null
                ? tours.cast<Tour?>().firstWhere(
                    (t) => t?.id == _selectedTourId,
                    orElse: () => null,
                  )
                : null;

            final unitPrice = tour?.price ?? 0.0;
            final precioPorPareja = tour?.precioPorPareja ?? false;
            // 1 responsable + acompañantes
            final totalPersonas = 1 + _integrantes.length;

            // Cálculo según modalidad de precio
            final double tourSubtotal;
            final String precioLabel;
            if (precioPorPareja) {
              final parejas = (totalPersonas / 2).ceil();
              tourSubtotal = unitPrice * parejas;
              precioLabel =
                  'Tour (${currencyFmt.format(unitPrice)}/pareja × $parejas pareja${parejas != 1 ? "s" : ""})';
            } else {
              tourSubtotal = unitPrice * totalPersonas;
              precioLabel =
                  'Tour (${currencyFmt.format(unitPrice)}/persona × $totalPersonas persona${totalPersonas != 1 ? "s" : ""})';
            }

            double serviciosTotal = 0;
            for (final id in _servicios) {
              final svc = allServices.cast<Service?>().firstWhere(
                (s) => s?.id == id,
                orElse: () => null,
              );
              if (svc?.cost != null) serviciosTotal += svc!.cost!;
            }

            final valorTotal = tourSubtotal + serviciosTotal;

            final totalValidado = _pagos
                .where((p) => p.isValidated)
                .fold(0.0, (sum, p) => sum + p.monto);
            final saldoPendiente = valorTotal - totalValidado;

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
                  _buildSectionHeader('RESUMEN DE COSTOS'),
                  const SizedBox(height: 20),
                  _buildResumenRow(
                    precioLabel,
                    tourSubtotal,
                    currencyFmt,
                    isSubtitle: true,
                  ),
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
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: D.border),
                  ),
                  _buildResumenRow(
                    'TOTAL',
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
                      valueColor: saldoPendiente <= 0
                          ? D.emerald
                          : Colors.amber,
                    ),
                  ],
                ],
              ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('PAGOS REGISTRADOS'),
              if (_loadingPagos)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: D.skyBlue,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_loadingPagos && _pagos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No hay pagos registrados para esta reserva.',
                style: TextStyle(
                  color: D.slate600,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pagos.length,
              separatorBuilder: (_, _) =>
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
                                  : D.slate600.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.isValidated ? 'Validado' : 'Sin validar',
                              style: TextStyle(
                                color: p.isValidated ? D.emerald : D.slate400,
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
      ),
    );
  }

  Widget _buildIntegrantesSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('INTEGRANTES'),
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
                  style: TextStyle(color: D.skyBlue),
                ),
              ),
            ],
          ),
          if (_integrantes.isEmpty) ...[
            const SizedBox(height: 8),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: D.slate600,
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sin integrantes agregados',
                      style: TextStyle(color: D.slate400, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _integrantes.length,
              separatorBuilder: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: D.border),
              ),
              itemBuilder: (context, index) {
                return _IntegranteFormFields(
                  integrante: _integrantes[index],
                  isResponsable: _integrantes[index].esResponsable,
                  onChanged: (newIntegrante) {
                    setState(() => _integrantes[index] = newIntegrante);
                  },
                  onDelete: () {
                    setState(() => _integrantes.removeAt(index));
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiciosSection() {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('SERVICIOS ADICIONALES'),
              TextButton.icon(
                onPressed: () {
                  setState(() => _servicios.add(0));
                },
                icon: const Icon(Icons.add_rounded, color: D.skyBlue, size: 18),
                label: const Text(
                  'Agregar',
                  style: TextStyle(color: D.skyBlue),
                ),
              ),
            ],
          ),
          if (_servicios.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Sin servicios adicionales registrados.',
                style: TextStyle(color: D.slate600, fontSize: 13),
              ),
            ),
          const SizedBox(height: 16),
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
                            dropdownColor: D.surface,
                            isExpanded: true,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            hint: const Text(
                              'Servicio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            decoration: _inputDecoration(
                              Icons.room_service_outlined,
                              '',
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
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: D.rose,
                            size: 20,
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
      ),
    );
  }

  Widget _buildNotasSection() {
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
          _buildSectionHeader('NOTAS DE RESERVA'),
          const SizedBox(height: 24),
          _buildField(
            controller: _notasCtrl,
            label: 'Observaciones (Vuelos, necesidades especiales, etc.)',
            icon: Icons.notes_rounded,
            maxLines: 4,
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return BlocBuilder<ReservaBloc, ReservaState>(
      builder: (context, state) {
        final isSaving = state is ReservaSaving;
        return GestureDetector(
          onTap: isSaving ? null : _save,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: D.royalBlue.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          'GUARDAR RESERVA',
                          style: TextStyle(
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
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
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

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: D.white, size: 18),
      hintText: hint,

      hintStyle: TextStyle(color: D.white, fontSize: 13),
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
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayCliente.correo,
                        style: TextStyle(color: D.slate400, fontSize: 12),
                      ),
                      Text(
                        '${displayCliente.tipoDocumento.toUpperCase()} ${displayCliente.documento}',
                        style: TextStyle(color: D.slate600, fontSize: 11),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: D.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: _inputDecoration(icon, ''),
          validator: isRequired
              ? (v) => (v == null || v.isEmpty)
                    ? 'Este campo es obligatorio'
                    : null
              : null,
        ),
      ],
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

  static const _tiposDocumento = ['cedula', 'pasaporte', 'tarjeta identidad'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.integrante.nombre);
    _phoneCtrl = TextEditingController(text: widget.integrante.telefono);
    _documentoCtrl = TextEditingController(text: widget.integrante.documento);
    _dob = widget.integrante.fechaNacimiento;
    _tipoDocumento = widget.integrante.tipoDocumento;
  }

  @override
  void didUpdateWidget(_IntegranteFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.integrante != widget.integrante) {
      _nameCtrl.text = widget.integrante.nombre;
      _phoneCtrl.text = widget.integrante.telefono;
      _documentoCtrl.text = widget.integrante.documento;
      _dob = widget.integrante.fechaNacimiento;
      _tipoDocumento = widget.integrante.tipoDocumento;
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  widget.isResponsable
                      ? Icons.star_rounded
                      : Icons.person_outline,
                  color: widget.isResponsable ? Colors.amber : D.slate400,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Acompañante',
                  style: TextStyle(
                    color: widget.isResponsable ? Colors.amber : D.slate400,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _inputDecoration(
                Icons.person_rounded,
                'Nombre Completo',
              ),
              onChanged: (_) => _notifyChange(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa el nombre' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _inputDecoration(Icons.phone_rounded, 'Teléfono'),
              onChanged: (_) => _notifyChange(),
              validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
            ),
            const SizedBox(height: 12),
            // ── Tipo de documento ──────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
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
                              ? D.royalBlue.withValues(alpha: 0.15)
                              : D.bg.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? D.royalBlue.withValues(alpha: 0.6)
                                : D.border,
                          ),
                        ),
                        child: Text(
                          tipo[0].toUpperCase() + tipo.substring(1),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _documentoCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: _inputDecoration(
                Icons.badge_outlined,
                'Número de documento',
              ),
              onChanged: (_) => _notifyChange(),
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa el documento' : null,
            ),
            const SizedBox(height: 12),
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
                    Icon(Icons.cake_rounded, color: D.white, size: 18),
                    const SizedBox(width: 12),
                    Text(
                      _dob != null
                          ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                          : 'Fecha de nacimiento (Opcional)',
                      style: TextStyle(color: D.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (widget.onDelete != null)
          Positioned(
            top: -10,
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: D.rose, size: 20),
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
  List<Cliente> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.clientes;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.clientes
          : widget.clientes
                .where(
                  (c) =>
                      c.nombre.toLowerCase().contains(q) ||
                      c.correo.toLowerCase().contains(q) ||
                      c.telefono.contains(q) ||
                      c.documento.toString().contains(q),
                )
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
                        final c = _filtered[index];
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(context, c),
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
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: D.royalBlue.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        c.nombre.isNotEmpty
                                            ? c.nombre[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: D.skyBlue,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
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
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          c.correo,
                                          style: TextStyle(
                                            color: D.slate400,
                                            fontSize: 11,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    c.documento.toString(),
                                    style: TextStyle(
                                      color: D.slate600,
                                      fontSize: 11,
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
