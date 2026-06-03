import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:agente_viajes/core/widgets/saas_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as webLib;
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/entities/integrante.dart';
import '../../domain/entities/aerolinea.dart';
import '../../domain/entities/vuelo_reserva.dart';
import '../../domain/entities/hotel_reserva.dart';
import '../../domain/repositories/reserva_repository.dart';
import '../../../../features/hoteles/presentation/bloc/hotel_bloc.dart';
import '../../../../features/hoteles/presentation/bloc/hotel_event.dart';
import '../../../../features/hoteles/presentation/bloc/hotel_state.dart';
import '../../../../features/hoteles/domain/entities/hotel.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/platform_network_image.dart';
import '../bloc/reserva_bloc.dart';
import '../bloc/reserva_event.dart';
import '../bloc/reserva_state.dart';
import '../../../../features/tour/presentation/bloc/tour_bloc.dart';
import '../../../../features/tour/domain/entities/tour.dart';
import '../../../../features/tour/domain/entities/tour_precio.dart';
import '../../../../features/service/presentation/bloc/service_bloc.dart';
import '../../../../features/service/presentation/bloc/service_event.dart';
import '../../../../features/service/presentation/bloc/service_state.dart';
import '../../../../features/service/domain/entities/service.dart';
import '../../../../features/service/domain/repositories/service_repository.dart';
import '../../../../features/pagos_realizados/domain/entities/pago_realizado.dart';
import '../../../../features/pagos_realizados/domain/repositories/pago_realizado_repository.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../pdf/reserva_pdf_generator.dart';
import '../../../../core/widgets/dialog_loading_widget.dart';
import '../../../../features/clientes/presentation/bloc/cliente_bloc.dart';
import '../../../../features/clientes/presentation/bloc/cliente_event.dart';
import '../../../../features/clientes/presentation/bloc/cliente_state.dart';
import '../../../../features/clientes/domain/entities/cliente.dart';
import '../../../../features/clientes/domain/repositories/cliente_repository.dart';
import '../../../../features/tour/domain/entities/precio_grupal.dart';

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
  // Pagos de la reserva (solo en edición)
  List<PagoRealizado> _pagos = [];
  bool _loadingPagos = false;
  bool _generatingPdf = false;

  // Tour card expandida
  bool _tourCardExpanded = false;

  // Cliente responsable
  int? _selectedClienteId;
  Cliente? _selectedCliente;
  bool _loadingResponsable = false;

  // Tour control
  String? _selectedTourId;

  // Bus selection
  int? _selectedBusLayoutId;
  List<Map<String, dynamic>> _busesDisponibilidad = [];
  bool _loadingBuses = false;

  /// Prices per person: key -1 = responsable, key 0,1,2... = integrante index
  Map<int, TourPrecio?> _preciosPorPersona = {};
  bool _preciosInitialized = false;
  final _tourSearchCtrl = TextEditingController();
  final _idReservaCtrl = TextEditingController();

  // Aerolíneas y vuelos
  List<Aerolinea> _aerolineas = [];
  bool _loadingAerolineas = false;
  List<VueloReserva> _vuelos = [];

  // Hotel reservas (solo para tipo vuelos)
  List<HotelReserva> _hotelReservas = [];

  // Utilidad (solo para tipo vuelos)
  late final TextEditingController _utilidadCtrl;

  // Descuento por persona
  double _descuentoPorPersona = 0.0;
  late final TextEditingController _descuentoCtrl;

  // Dynamic lists
  List<Integrante> _integrantes = [];
  List<int> _servicios = [];

  late final AnimationController _entryCtrl;

  bool get _isEditing => widget.reserva != null;
  bool _loadingReserva = false;
  int? _precioResponsableId;
  Reserva? _currentReserva;

  @override
  void initState() {
    super.initState();

    _notasCtrl = TextEditingController();
    _utilidadCtrl = TextEditingController();
    _descuentoCtrl = TextEditingController();

    if (_isEditing) {
      // Poblar con datos básicos del widget mientras carga la versión completa
      _populateFromReserva(widget.reserva!);
      // Carga inicial unificada (Reserva + Buses)
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
    }

    _loadAerolineas();

    // Attempt to load tours if not loaded or empty
    final tourState = context.read<TourBloc>().state;
    debugPrint('🔍 [ReservaFormScreen] initState - TourBloc state: $tourState');
    if (tourState is TourInitial ||
        tourState is TourError ||
        (tourState is ToursLoaded && tourState.tours.isEmpty)) {
      debugPrint('🔄 [ReservaFormScreen] Dispatching LoadTours()...');
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

    final hotelState = context.read<HotelBloc>().state;
    if (hotelState is HotelInitial || hotelState is HotelError) {
      context.read<HotelBloc>().add(const LoadHoteles());
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

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _tryInitPrecios());
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    // Mostramos un único diálogo de carga premium
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DialogLoadingNetwork(
        titel: 'Cargando información de la reserva...',
      ),
    );

    try {
      // 1. Cargar reserva completa desde el API
      final fresh = await sl<ReservaRepository>().getReservaById(
        widget.reserva!.id!,
      );
      if (!mounted) return;

      // 2. Poblar datos básicos (saltando carga automática de buses para controlarla aquí)
      _populateFromReserva(fresh, skipBuses: true);

      // 3. Cargar buses sincronizadamente si es un tour
      final tourIdInt = int.tryParse(fresh.idTour ?? '');
      if (tourIdInt != null) {
        await _loadBusesDisponibilidad(tourIdInt);
      }
    } catch (e) {
      debugPrint('❌ [ReservaForm] _loadInitialData: $e');
    } finally {
      if (mounted) {
        // Cerramos el diálogo único
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  void _populateFromReserva(Reserva r, {bool skipBuses = false}) {
    _currentReserva = r;
    _estado = r.estado;
    _selectedClienteId = r.idResponsable;
    _selectedTourId = (r.idTour != null && r.idTour!.isNotEmpty)
        ? r.idTour
        : null;
    _selectedBusLayoutId = r.busLayoutId;
    _precioResponsableId = r.precioResponsableId;
    _descuentoPorPersona = r.descuentoPorPersona ?? 0.0;

    _notasCtrl.text = r.notas;
    _utilidadCtrl.text = r.utilidad != null
        ? r.utilidad!.toStringAsFixed(0)
        : '';
    _descuentoCtrl.text = _descuentoPorPersona > 0
        ? _descuentoPorPersona.toStringAsFixed(0)
        : '';
    _idReservaCtrl.text = r.idReserva ?? '';

    _integrantes = List.from(r.integrantes);
    _servicios = List.from(r.serviciosIds);
    _vuelos = List.from(r.vuelos);
    _hotelReservas = List.from(r.hoteles);

    if (r.tour != null) _tourSearchCtrl.text = r.tour!.name;
    if (r.responsable != null) _selectedCliente = r.responsable;

    // Initialize prices from the embedded tour directly — no TourBloc dependency
    if (r.tour != null && r.tour!.precios.isNotEmpty) {
      _buildPreciosMap(r.tour!);
    }

    final tourIdInt = int.tryParse(r.idTour ?? '');
    if (tourIdInt != null && !skipBuses) {
      Future.microtask(() => _loadBusesDisponibilidad(tourIdInt));
    }

    if (_selectedClienteId != null && _selectedCliente == null) {
      _loadingResponsable = true;
      _loadClienteResponsable(_selectedClienteId!);
    }

    _loadPagos();
    setState(() {});

    WidgetsBinding.instance.addPostFrameCallback((_) => _tryInitPrecios());
  }

  void _buildPreciosMap(Tour tour) {
    final newMap = <int, TourPrecio?>{};
    if (_precioResponsableId != null) {
      newMap[-1] = tour.precios.cast<TourPrecio?>().firstWhere(
        (p) => p?.id == _precioResponsableId,
        orElse: () => null,
      );
    }
    for (int i = 0; i < _integrantes.length; i++) {
      final precioId = _integrantes[i].tourPrecioId;
      if (precioId != null) {
        newMap[i] = tour.precios.cast<TourPrecio?>().firstWhere(
          (p) => p?.id == precioId,
          orElse: () => null,
        );
      }
    }
    _preciosPorPersona = newMap;
    _preciosInitialized = true;
  }

  void _tryInitPrecios() {
    if (_preciosInitialized || !_isEditing) return;
    if (_selectedTourId == null) return;

    // Priority 1: use the tour already embedded in the loaded reserva
    final embeddedTour = _currentReserva?.tour;
    if (embeddedTour != null && embeddedTour.precios.isNotEmpty) {
      setState(() => _buildPreciosMap(embeddedTour));
      return;
    }

    // Priority 2: fall back to TourBloc if it already has tours loaded
    final tourState = context.read<TourBloc>().state;
    List<Tour> tours = [];
    if (tourState is ToursLoaded) {
      tours = tourState.tours;
    } else if (tourState is TourSaving && tourState.tours != null) {
      tours = tourState.tours!;
    } else if (tourState is TourSaved && tourState.tours != null) {
      tours = tourState.tours!;
    }
    if (tours.isEmpty) return;

    final tour = tours.cast<Tour?>().firstWhere(
      (t) => t?.id == _selectedTourId,
      orElse: () => null,
    );
    if (tour == null || tour.precios.isEmpty) {
      setState(() => _preciosInitialized = true);
      return;
    }

    setState(() => _buildPreciosMap(tour));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _notasCtrl.dispose();
    _tourSearchCtrl.dispose();
    _idReservaCtrl.dispose();
    _utilidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPagos() async {
    final reservaId = _currentReserva?.id ?? widget.reserva?.id;
    final reservaIdInt = int.tryParse(reservaId ?? '');
    debugPrint('🔍 [_loadPagos] reserva.id=$reservaId, parsed=$reservaIdInt');
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

  Future<void> _loadBusesDisponibilidad(int tourId) async {
    setState(() {
      _loadingBuses = true;
      _busesDisponibilidad = [];
    });
    try {
      final buses = await sl<ReservaRepository>().getBusesDisponibilidad(
        tourId,
      );
      if (mounted) setState(() => _busesDisponibilidad = buses);
    } catch (e) {
      debugPrint('❌ [ReservaForm] loadBuses: $e');
    } finally {
      if (mounted) setState(() => _loadingBuses = false);
    }
  }

  Future<void> _generateAndShowPdf() async {
    final reserva = _currentReserva ?? widget.reserva;
    if (reserva == null) return;
    setState(() => _generatingPdf = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const DialogLoadingNetwork(titel: 'Generando PDF de Reserva'),
    );

    try {
      final fullReserva = reserva.id != null
          ? await sl<ReservaRepository>().getReservaById(reserva.id!)
          : reserva;
      final allServices = await sl<ServiceRepository>().getServices();
      final bytes = await ReservaPdfGenerator.generate(
        fullReserva,
        servicios: allServices,
      );
      if (!mounted) return;
      // Cerrar el diálogo de carga usando el rootNavigator para asegurar que cerramos el diálogo
      Navigator.of(context, rootNavigator: true).pop();

      final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final filename =
          'Reserva_${reserva.idReserva ?? reserva.id}_$dateStr.pdf';
      final uint8Bytes = Uint8List.fromList(bytes);

      void openInNewTab() {
        final blob = webLib.Blob(
          <JSAny>[uint8Bytes.buffer.toJS].toJS,
          webLib.BlobPropertyBag(type: 'application/pdf'),
        );
        final url = webLib.URL.createObjectURL(blob);
        webLib.window.open(url, '_blank', '');
      }

      void download() {
        final blob = webLib.Blob(
          <JSAny>[uint8Bytes.buffer.toJS].toJS,
          webLib.BlobPropertyBag(type: 'application/pdf'),
        );
        final url = webLib.URL.createObjectURL(blob);
        final anchor =
            webLib.document.createElement('a') as webLib.HTMLAnchorElement;
        anchor.href = url;
        anchor.download = filename;
        anchor.click();
        webLib.URL.revokeObjectURL(url);
      }

      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          insetPadding: const EdgeInsets.all(32),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  size: 48,
                  color: Color(0xFF2563EB),
                ),
                const SizedBox(height: 16),
                Text(
                  filename,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'El PDF fue generado exitosamente.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: openInNewTab,
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Ver PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2563EB),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: download,
                      icon: const Icon(Icons.download_rounded, size: 16),
                      label: const Text('Descargar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generando PDF: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
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

  Future<void> _onDeleteIntegrante(int index) async {
    final integrante = _integrantes[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: 'Eliminar integrante',
        body:
            '¿Deseas eliminar a ${integrante.nombre.isNotEmpty ? integrante.nombre : "este integrante"}? Esta acción no se puede deshacer.',
        confirmLabel: 'Eliminar',
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );
    if (confirmed != true) return;

    final reservaId = _currentReserva?.id ?? widget.reserva?.id;

    if (_isEditing && integrante.id != null && reservaId != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DialogLoadingNetwork(
          titel: 'Eliminando integrante...',
        ),
      );
      try {
        await sl<ReservaRepository>().deleteIntegrante(
          reservaId,
          integrante.id!,
        );
        final fresh = await sl<ReservaRepository>().getReservaById(reservaId);
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop();
        _preciosInitialized = false;
        _populateFromReserva(fresh);
        SaasSnackBar.showSuccess(
          context,
          'Integrante eliminado · Nuevo total: \$${(fresh.valorTotal ?? 0).toStringAsFixed(0)}',
        );
      } catch (e) {
        if (mounted) Navigator.of(context, rootNavigator: true).pop();
        if (mounted) SaasSnackBar.showError(context, e.toString());
      }
    } else {
      setState(() {
        _integrantes.removeAt(index);
        final newMap = <int, TourPrecio?>{};
        for (final entry in _preciosPorPersona.entries) {
          if (entry.key == index) continue;
          if (entry.key > index) {
            newMap[entry.key - 1] = entry.value;
          } else {
            newMap[entry.key] = entry.value;
          }
        }
        _preciosPorPersona = newMap;
      });
    }
  }

  Widget _buildCancelReservaButton(BuildContext ctx) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _confirmCancelReserva(ctx),
        icon: const Icon(
          Icons.cancel_outlined,
          size: 18,
          color: SaasPalette.warning,
        ),
        label: const Text(
          'CANCELAR RESERVA',
          style: TextStyle(
            color: SaasPalette.warning,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: SaasPalette.warning),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancelReserva(BuildContext ctx) async {
    final reserva = _currentReserva ?? widget.reserva;
    if (reserva?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => SaasConfirmDialog(
        title: 'Cancelar Reserva',
        body:
            'La reserva #${reserva!.idReserva ?? reserva.id} será marcada como cancelada '
            'y los asientos asignados quedarán liberados. '
            'Esta acción no se puede deshacer.',
        confirmLabel: 'Cancelar reserva',
        onConfirm: () => Navigator.pop(dialogCtx, true),
      ),
    );
    if (confirmed != true || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DialogLoadingNetwork(titel: 'Cancelando reserva...'),
    );

    try {
      await sl<ReservaRepository>().cancelReserva(reserva!.id!);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      context.read<ReservaBloc>().add(const LoadReservas());
      Navigator.pop(context);
      SaasSnackBar.showSuccess(context, 'Reserva cancelada correctamente');
    } catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      if (mounted) SaasSnackBar.showError(context, e.toString());
    }
  }

  void _save() {
    // Cliente requerido
    if (_selectedCliente == null) {
      SaasSnackBar.showWarning(context, 'Debe seleccionar un cliente.');
      return;
    }

    // Al menos un tour, vuelo u hotel
    if (_selectedTourId == null && _vuelos.isEmpty && _hotelReservas.isEmpty) {
      SaasSnackBar.showWarning(
        context,
        'Debe agregar al menos un tour, vuelo u hotel.',
      );
      return;
    }

    // Bus obligatorio si el tour tiene buses asignados
    if (_selectedTourId != null && _busesDisponibilidad.isNotEmpty) {
      if (_selectedBusLayoutId == null) {
        SaasSnackBar.showWarning(
          context,
          'Debe seleccionar un bus para esta reserva.',
        );
        return;
      }
    }

    // Validar cada vuelo agregado
    for (var vuelo in _vuelos) {
      if (vuelo.aerolinea == null) {
        SaasSnackBar.showWarning(context, 'Debe seleccionar una aerolínea.');
        return;
      }
      if (vuelo.origen.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe seleccionar un origen.');
        return;
      }
      if (vuelo.destino.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe seleccionar un destino.');
        return;
      }
      if (vuelo.fechaSalida.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe seleccionar una fecha de salida.');
        return;
      }
      if (vuelo.horaSalida.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe seleccionar una hora de salida.');
        return;
      }
      if (vuelo.fechaLlegada.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe seleccionar una fecha de llegada.');
        return;
      }
      if (vuelo.horaLlegada.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe seleccionar una hora de llegada.');
        return;
      }
      if (vuelo.precio == null) {
        SaasSnackBar.showWarning(context, 'Debe ingresar el precio del vuelo.');
        return;
      }
    }

    // Validar cada hotel agregado
    for (var hotel in _hotelReservas) {
      if (hotel.hotel == null) {
        SaasSnackBar.showWarning(context, 'Debe seleccionar un hotel.');
        return;
      }
      if (hotel.numeroReserva.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe ingresar el número de reserva del hotel.');
        return;
      }
      if (hotel.valor == null) {
        SaasSnackBar.showWarning(context, 'Debe ingresar el valor del hotel.');
        return;
      }
      if (hotel.fechaCheckin.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe seleccionar una fecha de check-in.');
        return;
      }
      if (hotel.fechaCheckout.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe seleccionar una fecha de check-out.');
        return;
      }
    }

    // Validar integrantes
    for (int i = 0; i < _integrantes.length; i++) {
      final integrante = _integrantes[i];
      final label = 'Integrante ${i + 1}';
      if (integrante.nombre.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe ingresar el nombre de $label.');
        return;
      }
      if (integrante.telefono.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe ingresar el teléfono de $label.');
        return;
      }
      if (integrante.documento.isEmpty) {
        SaasSnackBar.showWarning(context, 'Debe ingresar el número de documento de $label.');
        return;
      }
    }

    // ── Calcular componentes del total ──────────────────────────────────────
    final vuelosTotal = _vuelos.fold<double>(0.0, (sum, v) => sum + (v.precio ?? 0.0));
    final hotelesTotal = _hotelReservas.fold<double>(0.0, (sum, h) => sum + (h.valor ?? 0.0));

    double serviciosTotal = 0.0;
    final serviceState = context.read<ServiceBloc>().state;
    List<Service> allServices = [];
    if (serviceState is ServicesLoaded) {
      allServices = serviceState.services;
    } else if (serviceState is ServiceSaved && serviceState.services != null) {
      allServices = serviceState.services!;
    }
    for (final id in _servicios) {
      final svc = allServices.cast<Service?>().firstWhere(
        (s) => s?.id == id,
        orElse: () => null,
      );
      if (svc?.cost != null) serviciosTotal += svc!.cost!;
    }

    // Resolver tour si hay uno seleccionado
    Tour? selectedTour;
    if (_selectedTourId != null) {
      final tourState = context.read<TourBloc>().state;
      List<Tour> allTours = [];
      if (tourState is ToursLoaded) {
        allTours = tourState.tours;
      } else if (tourState is TourSaving && tourState.tours != null) {
        allTours = tourState.tours!;
      } else if (tourState is TourSaved && tourState.tours != null) {
        allTours = tourState.tours!;
      }
      selectedTour = allTours.cast<Tour?>().firstWhere(
        (t) => t?.id == _selectedTourId,
        orElse: () => null,
      );
    }

    // Calcular subtotal del tour
    double tourSubtotal = 0.0;
    double descuentoTotal = 0.0;
    if (selectedTour != null) {
      final int totalPersonas = 1 + _integrantes.length;

      final tourNN = selectedTour; // variable local para usar dentro de closures
      if (tourNN.modoPrecio == 'grupal' && tourNN.preciosGrupales.isNotEmpty) {
        // Precio grupal: el precio del tier es POR PERSONA × total personas
        final tier = tourNN.preciosGrupales
            .cast<PrecioGrupal?>()
            .firstWhere(
              (p) => p != null && totalPersonas >= p.minPersonas && totalPersonas <= p.maxPersonas,
              orElse: () => tourNN.preciosGrupales.isNotEmpty
                  ? tourNN.preciosGrupales.last
                  : null,
            );
        tourSubtotal = (tier?.precio ?? 0.0) * totalPersonas;
      } else {
        // Precio individual (por persona o por pareja)
        final allPersonKeys = [-1, ...List.generate(_integrantes.length, (i) => i)];
        double tourSum = 0.0;
        if (selectedTour.precioPorPareja) {
          for (int i = 0; i < allPersonKeys.length; i += 2) {
            tourSum += _preciosPorPersona[allPersonKeys[i]]?.precio ?? selectedTour.price;
          }
        } else {
          for (final key in allPersonKeys) {
            tourSum += _preciosPorPersona[key]?.precio ?? selectedTour.price;
          }
        }
        tourSubtotal = tourSum;
        final int units = selectedTour.precioPorPareja
            ? (totalPersonas / 2).ceil()
            : totalPersonas;
        descuentoTotal = _descuentoPorPersona * units;
      }
    }

    final double calculatedTotal =
        tourSubtotal + vuelosTotal + hotelesTotal + serviciosTotal - descuentoTotal;

    // Enriquecer integrantes con precio aplicado
    final integrantesConPrecio = _integrantes.asMap().entries.map((e) {
      final cat = _preciosPorPersona[e.key];
      return e.value.copyWith(
        tourPrecioId: cat?.id,
        precioAplicado: cat?.precio ?? selectedTour?.price,
      );
    }).toList();

    final catResponsable = _preciosPorPersona[-1];

    // Derivar tipo_reserva del contenido para compatibilidad con el backend
    final derivedTipo = _selectedTourId != null ? 'tour' : 'vuelos';

    final reserva = Reserva(
      id: _isEditing ? (_currentReserva?.id ?? widget.reserva!.id) : null,
      tipoReserva: derivedTipo,
      idTour: _selectedTourId,
      correo: _selectedCliente?.correo ?? _currentReserva?.correo ?? widget.reserva?.correo ?? '',
      estado: _estado,
      notas: _notasCtrl.text.trim(),
      descuentoPorPersona: selectedTour != null ? _descuentoPorPersona : 0.0,
      valorTotal: calculatedTotal,
      serviciosIds: _servicios.where((s) => s != 0).toList(),
      integrantes: integrantesConPrecio,
      vuelos: _vuelos,
      hoteles: _hotelReservas,
      utilidad: double.tryParse(_utilidadCtrl.text.trim()),
      idResponsable: _selectedClienteId,
      fechaCreacion: _isEditing
          ? (_currentReserva?.fechaCreacion ?? widget.reserva!.fechaCreacion)
          : DateTime.now(),
      fechaActualizacion: DateTime.now(),
      precioResponsableId: catResponsable?.id,
      precioResponsableAplicado: catResponsable?.precio ?? selectedTour?.price,
      busLayoutId: _selectedBusLayoutId,
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
      listener: (context, state) async {
        if (state is ReservaActionSuccess) {
          context.read<ReservaBloc>().add(const LoadReservas());

          if (!_isEditing &&
              state.createdReserva != null &&
              state.createdReserva!.tipoReserva == 'tour') {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) =>
                  _ReservaCreatedDialog(reserva: state.createdReserva!),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isEditing ? 'Reserva actualizada' : 'Reserva creada',
                ),
                backgroundColor: SaasPalette.success,
              ),
            );
          }

          if (!mounted) return;
          Navigator.pop(context);
        } else if (state is ReservaError) {
          showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: SaasPalette.bgCanvas,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: SaasPalette.danger.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: SaasPalette.danger.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.error_rounded,
                        color: SaasPalette.danger,
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
                      style: const TextStyle(
                        color: SaasPalette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: SaasPalette.danger,
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
        backgroundColor: SaasPalette.bgApp,
        body: Stack(
          children: [
            if (_loadingReserva)
              const Positioned.fill(
                child: AbsorbPointer(
                  child: ColoredBox(
                    color: Colors.black12,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: SaasPalette.brand600,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
              ),
            CustomScrollView(
              slivers: [
                PremiumSliverAppBar(
                  title: _isEditing ? 'Editar Reserva' : 'Nueva Reserva',
                  actions:
                      //flecha de atras
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                            _buildResponsableSection(),
                            const SizedBox(height: 24),
                            _buildBasicInfoSection(),
                            const SizedBox(height: 24),
                            _buildVuelosSection(),
                            const SizedBox(height: 24),
                            _buildHotelReservaSection(),
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
                            if (_isEditing) ...[
                              const SizedBox(height: 16),
                              _buildPdfButton(),
                            ],
                            const SizedBox(height: 32),
                            Builder(
                              builder: (context) {
                                final authState = context
                                    .read<AuthBloc>()
                                    .state;
                                final canWrite =
                                    authState is AuthAuthenticated &&
                                    authState.user.canWrite('reservas');
                                if (!canWrite && _isEditing) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    _buildSubmitButton(),
                                    if (_isEditing &&
                                        (_currentReserva ?? widget.reserva)
                                                ?.estado !=
                                            'cancelada') ...[
                                      const SizedBox(height: 16),
                                      _buildCancelReservaButton(context),
                                    ],
                                  ],
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
        _buildTourDropdown(),
        if (_busesDisponibilidad.isNotEmpty || _loadingBuses) ...[
          const SizedBox(height: 24),
          _buildBusSelector(),
        ],
        _buildAsientosDisplay(),
        const SizedBox(height: 24),
        _buildStatusDropdown(),
      ],
    );
  }

  Widget _buildAsientosDisplay() {
    final res = _currentReserva ?? widget.reserva;
    if (res == null) return const SizedBox.shrink();

    final hasAsientos = res.asientosBus.isNotEmpty;
    final hasLink = res.seleccionLink != null && res.seleccionLink!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        if (hasAsientos) ...[
          Text(
            'ASIENTOS ASIGNADOS',
            style: TextStyle(
              color: SaasPalette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: res.asientosBus.map((asiento) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: SaasPalette.brand600.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: SaasPalette.brand600.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.event_seat_rounded,
                      color: SaasPalette.brand600,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      asiento,
                      style: const TextStyle(
                        color: SaasPalette.brand600,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SaasPalette.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SaasPalette.danger.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: SaasPalette.danger,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  'Falta por asignar asientos',
                  style: TextStyle(
                    color: SaasPalette.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (hasLink) ...[
          const SizedBox(height: 24),
          Text(
            'LINK DE SELECCIÓN',
            style: TextStyle(
              color: SaasPalette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: SaasPalette.brand50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: SaasPalette.brand600.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  color: SaasPalette.brand600,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    res.seleccionLink!,
                    style: const TextStyle(
                      color: SaasPalette.brand600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: res.seleccionLink!),
                      );
                      SaasSnackBar.showSuccess(
                        context,
                        'Link copiado al portapapeles',
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.copy_rounded,
                        color: SaasPalette.brand600,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTourDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tour o Promoción (opcional)',
          style: TextStyle(
            color: SaasPalette.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<TourBloc, TourState>(
          builder: (context, state) {
            if (!_preciosInitialized && state is ToursLoaded) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => _tryInitPrecios(),
              );
            }

            final isLoading =
                state is TourLoading ||
                state is TourInitial ||
                state is TourSaving;
            final isError = state is TourError;
            final errorMessage = isError ? state.message : null;

            List<Tour> tours = [];
            if (state is ToursLoaded) {
              tours = state.tours;
            } else if (state is TourSaved && state.tours != null) {
              tours = state.tours!;
            } else if (state is TourSaving && state.tours != null) {
              tours = state.tours!;
            }

            debugPrint(
              '🎨 [ReservaFormScreen] _buildTourDropdown - State: $state, Tours: ${tours.length}, isLoading: $isLoading',
            );

            final selectedTour = _selectedTourId != null
                ? tours.firstWhere(
                    (t) => t.id == _selectedTourId,
                    orElse: () => Tour(
                      id: _selectedTourId!,
                      idTour: 0,
                      name: _tourSearchCtrl.text,
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
                    ),
                  )
                : null;
            final isTourFound =
                selectedTour != null && selectedTour.name.isNotEmpty;
            final isEmpty = state is ToursLoaded && tours.isEmpty;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Botón selector
                FormField<String>(
                  validator: (_) => null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: (isLoading || (isError && !isLoading))
                            ? (isError
                                  ? () => context.read<TourBloc>().add(
                                      LoadTours(),
                                    )
                                  : null)
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
                                    _preciosPorPersona = {};
                                    _selectedBusLayoutId = null;
                                    _busesDisponibilidad = [];
                                  });
                                  field.didChange(result.id);
                                  final tourIdInt = int.tryParse(result.id);
                                  if (tourIdInt != null) {
                                    _loadBusesDisponibilidad(tourIdInt);
                                  }
                                }
                              },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: SaasPalette.bgSubtle,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: field.hasError
                                  ? SaasPalette.danger
                                  : isTourFound
                                  ? SaasPalette.brand600
                                  : SaasPalette.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isError
                                    ? Icons.error_outline_rounded
                                    : Icons.tour_rounded,
                                color: isError
                                    ? SaasPalette.danger
                                    : isTourFound
                                    ? SaasPalette.brand600
                                    : SaasPalette.textTertiary,
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isError
                                      ? 'Error al cargar tours (Toca para reintentar)'
                                      : isEmpty
                                      ? 'No hay tours disponibles'
                                      : isTourFound
                                      ? _tourSearchCtrl.text
                                      : 'Seleccionar tour...',
                                  style: TextStyle(
                                    color: isError
                                        ? SaasPalette.danger
                                        : isTourFound
                                        ? SaasPalette.textPrimary
                                        : SaasPalette.textTertiary,
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
                                    color: SaasPalette.brand600,
                                  ),
                                )
                              else if (isTourFound)
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _selectedTourId = null;
                                    _tourSearchCtrl.clear();
                                    _preciosPorPersona = {};
                                  }),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: SaasPalette.textTertiary,
                                    size: 18,
                                  ),
                                )
                              else ...[
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: SaasPalette.textTertiary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                if (!isLoading)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                    ),
                                    onPressed: () => context
                                        .read<TourBloc>()
                                        .add(LoadTours()),
                                    color: SaasPalette.textTertiary,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Refrescar tours',
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, left: 4),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                              color: SaasPalette.danger,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      if (field.hasError) ...[
                        const SizedBox(height: 6),
                        Text(
                          field.errorText!,
                          style: const TextStyle(
                            color: SaasPalette.danger,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Tour info card
                if (isTourFound) ...[
                  const SizedBox(height: 16),
                  _buildTourInfoCard(selectedTour),
                  // Selector de categoría solo cuando hay precios individuales y no es modo grupal
                  if (selectedTour.precios.isNotEmpty &&
                      !(selectedTour.modoPrecio == 'grupal' && selectedTour.preciosGrupales.isNotEmpty)) ...[
                    const SizedBox(height: 12),
                    _buildPersonaPrecioSelector(
                      tour: selectedTour,
                      personaKey: -1,
                      label: 'Precio responsable',
                    ),
                  ],
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildPersonaPrecioSelector({
    required Tour tour,
    required int personaKey,
    required String label,
  }) {
    final currencyFmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final selected = _preciosPorPersona[personaKey];
    final unit = tour.precioPorPareja ? '/pareja' : '/persona';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected != null ? SaasPalette.brand600 : SaasPalette.border,
          width: selected != null ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sell_rounded,
            color: selected != null
                ? SaasPalette.brand600
                : SaasPalette.textTertiary,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<TourPrecio?>(
                    value: selected,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: SaasPalette.bgCanvas,
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 13,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: SaasPalette.brand600,
                      size: 18,
                    ),
                    items: [
                      DropdownMenuItem<TourPrecio?>(
                        value: null,
                        child: Text(
                          'Base — ${currencyFmt.format(tour.price)}$unit',
                          style: const TextStyle(
                            color: SaasPalette.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...tour.precios.map((p) {
                        final edadStr = (p.edadMin != null || p.edadMax != null)
                            ? ' (${p.edadMin ?? 0}-${p.edadMax ?? '∞'} años)'
                            : '';
                        return DropdownMenuItem<TourPrecio?>(
                          value: p,
                          child: Text(
                            '${p.descripcion}$edadStr — ${currencyFmt.format(p.precio)}',
                            style: const TextStyle(
                              color: SaasPalette.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(
                      () =>
                          _preciosPorPersona = Map.from(_preciosPorPersona)
                            ..[personaKey] = val,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BUS ASIGNADO *',
          style: TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        if (_loadingBuses)
          const SizedBox(
            height: 48,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          DropdownButtonFormField<int>(
            value:
                _busesDisponibilidad.any(
                  (b) =>
                      (b['bus_layout_id'] as num?)?.toInt() ==
                      _selectedBusLayoutId,
                )
                ? _selectedBusLayoutId
                : null,
            dropdownColor: SaasPalette.bgCanvas,
            style: const TextStyle(
              color: SaasPalette.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.directions_bus_rounded,
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
            hint: const Text(
              'Selecciona un bus',
              style: TextStyle(color: SaasPalette.textTertiary, fontSize: 13),
            ),
            items: _busesDisponibilidad.map((bus) {
              final disponibles = (bus['disponibles'] as num?)?.toInt() ?? 0;
              final total =
                  (bus['total_asientos_cliente'] as num?)?.toInt() ?? 0;
              final color = disponibles == 0
                  ? Colors.red
                  : disponibles <= 5
                  ? Colors.orange
                  : Colors.green;
              return DropdownMenuItem<int>(
                value: (bus['bus_layout_id'] as num).toInt(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        bus['nombre'] as String? ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '$disponibles/$total libres',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) => setState(() => _selectedBusLayoutId = val),
            validator: (v) => v == null && _busesDisponibilidad.isNotEmpty
                ? 'Requerido'
                : null,
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
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (tour.isPromotion)
                      _TourBadge(
                        label: 'PROMO',
                        color: SaasPalette.warning,
                        icon: Icons.star_rounded,
                      ),
                    if (tour.precioPorPareja)
                      _TourBadge(
                        label: 'POR PAREJA',
                        color: SaasPalette.brand600,
                        icon: Icons.people_rounded,
                      ),
                    if (!tour.isActive)
                      _TourBadge(
                        label: 'INACTIVO',
                        color: SaasPalette.danger,
                        icon: Icons.block_rounded,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  tour.name,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Precios ──────────────────────────────────
                const Divider(color: SaasPalette.border),
                const SizedBox(height: 12),

                // Precio base (individual)
                if (tour.price > 0) ...[
                  _PrecioSectionHeader(
                    icon: Icons.sell_rounded,
                    label: tour.precioPorPareja ? 'PRECIO BASE (POR PAREJA)' : 'PRECIO BASE (POR PERSONA)',
                  ),
                  const SizedBox(height: 8),
                  _PrecioRow(
                    label: tour.precioPorPareja ? 'Por pareja' : 'Por persona',
                    precio: currencyFmt.format(tour.price),
                    destacado: true,
                  ),
                  const SizedBox(height: 12),
                ],

                // Categorías de precio individual
                if (tour.precios.isNotEmpty) ...[
                  _PrecioSectionHeader(
                    icon: Icons.loyalty_rounded,
                    label: 'CATEGORÍAS DE PRECIO',
                  ),
                  const SizedBox(height: 8),
                  ...tour.precios.map((p) {
                    final parts = <String>[];
                    if (p.edadMin != null || p.edadMax != null) {
                      parts.add('${p.edadMin ?? 0}–${p.edadMax ?? '∞'} años');
                    }
                    if (p.puntoPartida != null) parts.add('desde ${p.puntoPartida}');
                    return _PrecioRow(
                      label: p.descripcion,
                      sublabel: parts.isEmpty ? null : parts.join(' · '),
                      precio: currencyFmt.format(p.precio),
                    );
                  }),
                  const SizedBox(height: 12),
                ],

                // Precios grupales
                if (tour.preciosGrupales.isNotEmpty) ...[
                  _PrecioSectionHeader(
                    icon: Icons.groups_rounded,
                    label: 'PRECIOS POR GRUPO',
                  ),
                  const SizedBox(height: 8),
                  ...tour.preciosGrupales.map((g) => _PrecioRow(
                    label: g.descripcion ?? 'Grupo',
                    sublabel: '${g.minPersonas}–${g.maxPersonas} personas',
                    precio: currencyFmt.format(g.precio),
                  )),
                  const SizedBox(height: 12),
                ],

                const Divider(color: SaasPalette.border),
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
                      '${dateFmt.format(tour.startDate ?? DateTime.now())} → ${dateFmt.format(tour.endDate ?? DateTime.now())}',
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
                          color: SaasPalette.brand600,
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
                          color: SaasPalette.brand600,
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
                    const Divider(color: SaasPalette.border),
                    const SizedBox(height: 12),
                    _buildListSection(
                      title: 'INCLUYE',
                      color: SaasPalette.success,
                      icon: Icons.check_circle_outline_rounded,
                      items: tour.inclusions,
                    ),
                  ],

                  // ── Exclusiones ────────────────────────────
                  if (tour.exclusions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildListSection(
                      title: 'NO INCLUYE',
                      color: SaasPalette.danger,
                      icon: Icons.cancel_outlined,
                      items: tour.exclusions,
                    ),
                  ],

                  // ── Itinerario ─────────────────────────────
                  if (tour.itinerary.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(color: SaasPalette.border),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 12,
                          decoration: BoxDecoration(
                            color: SaasPalette.brand600,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ITINERARIO',
                          style: TextStyle(
                            color: SaasPalette.textTertiary,
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
                                color: SaasPalette.brand600.withValues(
                                  alpha: 0.15,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${day.dayNumber}',
                                  style: const TextStyle(
                                    color: SaasPalette.brand600,
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
                                      color: SaasPalette.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (day.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      day.description,
                                      style: TextStyle(
                                        color: SaasPalette.textSecondary,
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
                    const Divider(color: SaasPalette.border),
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
                            color: SaasPalette.danger,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ver PDF del tour',
                            style: TextStyle(
                              color: SaasPalette.brand600,
                              fontSize: 13,
                              decoration: TextDecoration.underline,
                              decorationColor: SaasPalette.brand600,
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
                color: SaasPalette.textTertiary,
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
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 13,
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

  InputDecoration _inputDecoration(IconData icon, String hint) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: SaasPalette.textPrimary, size: 18),
      hintText: hint,
      hintStyle: const TextStyle(color: SaasPalette.textTertiary, fontSize: 13),
      filled: true,
      fillColor: SaasPalette.bgSubtle,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SaasPalette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: SaasPalette.brand600),
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
            color: SaasPalette.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _estado,
          dropdownColor: D.white,
          style: const TextStyle(color: SaasPalette.textPrimary, fontSize: 14),
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
                  Icon(Icons.circle, color: SaasPalette.danger, size: 12),
                  SizedBox(width: 8),
                  Text('Cancelado'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'cancelada',
              child: Row(
                children: const [
                  Icon(Icons.circle, color: SaasPalette.danger, size: 12),
                  SizedBox(width: 8),
                  Text('Cancelada'),
                ],
              ),
            ),
          ],
          onChanged: (_estado == 'cancelada' || _estado == 'cancelado')
              ? null
              : (v) {
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

            final double basePrice = tour?.price ?? 0.0;

            double vuelosTotal = 0;
            for (final v in _vuelos) {
              vuelosTotal += v.precio ?? 0.0;
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

            double hotelesTotal = 0;
            for (final h in _hotelReservas) {
              hotelesTotal += h.valor ?? 0.0;
            }

            final bool precioPorPareja = tour?.precioPorPareja ?? false;
            final int currentPersonas = 1 + _integrantes.length;
            final int currentUnits = precioPorPareja
                ? (currentPersonas / 2).ceil()
                : currentPersonas;

            final double descuentoTotal;
            final double tourSubtotalFinal;
            final String tourUnitLabel;
            final List<({String label, double price})> tourBreakdown;

            if (tour == null) {
              descuentoTotal = 0;
              tourSubtotalFinal = 0;
              tourUnitLabel = '';
              tourBreakdown = [];
            } else if (tour.modoPrecio == 'grupal' && tour.preciosGrupales.isNotEmpty) {
              // ── Tour Grupal: precio por persona según tier del grupo ───────
              final tier = tour.preciosGrupales
                  .cast<PrecioGrupal?>()
                  .firstWhere(
                    (p) => p != null && currentPersonas >= p.minPersonas && currentPersonas <= p.maxPersonas,
                    orElse: () => tour.preciosGrupales.isNotEmpty ? tour.preciosGrupales.last : null,
                  );
              final precioTier = tier?.precio ?? 0.0;

              // Desglose por persona (responsable + integrantes)
              final List<({String label, double price})> rows = [];
              rows.add((label: 'Responsable', price: precioTier));
              for (int i = 0; i < _integrantes.length; i++) {
                rows.add((label: 'Integrante ${i + 1}', price: precioTier));
              }
              tourBreakdown = rows;
              tourSubtotalFinal = precioTier * currentPersonas;
              descuentoTotal = 0;
              tourUnitLabel = tier != null
                  ? '${tier.descripcion ?? "Precio grupal"} · ${currencyFmt.format(precioTier)}/persona × $currentPersonas personas'
                  : 'Precio grupal';
            } else {
              // ── Tour Individual: precio por unidad con snapshot al editar ─
              final reservaRef = _currentReserva ?? widget.reserva;

              // Hay precio si hay TourPrecio en el mapa O si hay precioAplicado
              // guardado en el responsable/integrantes (evita usar el snapshot
              // cuando sí existen precios por persona definidos).
              final bool hasPrecioSeleccionado =
                  _preciosPorPersona.values.any((p) => p != null) ||
                  reservaRef?.precioResponsableAplicado != null ||
                  _integrantes.any((i) => i.precioAplicado != null);

              // Devuelve el precio efectivo para cada persona:
              //   1. TourPrecio seleccionado en el mapa (dropdown)
              //   2. precioAplicado guardado en integrante / reserva
              //   3. precio base genérico del tour
              double resolvePrecio(int key) {
                if (key == -1) {
                  return _preciosPorPersona[-1]?.precio ??
                      reservaRef?.precioResponsableAplicado ??
                      basePrice;
                }
                return _preciosPorPersona[key]?.precio ??
                    _integrantes[key].precioAplicado ??
                    basePrice;
              }

              final snapshotTotal = (_isEditing && !hasPrecioSeleccionado)
                  ? (reservaRef?.valorSinDescuento ??
                        reservaRef?.valorTotal ??
                        0.0)
                  : null;
              final useSnapshot = snapshotTotal != null && snapshotTotal > 0;

              final double efectiveUnitPrice;
              final double tourSub;

              if (useSnapshot) {
                // Sin precios por persona: usar el snapshot del tour puro.
                // valorPersonas es el subtotal tour sin servicios guardado en
                // la API; si no está disponible se resta el costo de servicios
                // ORIGINALES (los que venían en la reserva al cargarla) para
                // aislar el componente tour y no alterar el total al agregar
                // servicios nuevos.
                final tourBase = reservaRef?.valorPersonas ??
                    (() {
                      final origSvcCost = allServices
                          .where((s) => (reservaRef?.serviciosIds ?? []).contains(s.id))
                          .fold<double>(0.0, (sum, s) => sum + (s.cost ?? 0));
                      return snapshotTotal - origSvcCost;
                    })();
                final originalPersonas = 1 + _integrantes.length;
                final originalUnits = precioPorPareja
                    ? (originalPersonas / 2).ceil()
                    : originalPersonas;
                efectiveUnitPrice = originalUnits > 0
                    ? tourBase / originalUnits
                    : 0.0;
                tourSub = efectiveUnitPrice * currentUnits;
                tourBreakdown = [];
              } else {
                // ── Lógica de desglose y cálculo de subtotal ─────────────────
                String personLabel(int key) {
                  if (key == -1) {
                    final cat = _preciosPorPersona[-1];
                    return cat != null
                        ? 'Responsable (${cat.descripcion})'
                        : 'Responsable';
                  }
                  final base = 'Integrante ${key + 1}';
                  final cat = _preciosPorPersona[key];
                  return cat != null ? '$base (${cat.descripcion})' : base;
                }

                final allPersonKeys = [
                  -1,
                  ...List.generate(_integrantes.length, (i) => i),
                ];
                final List<({String label, double price})> rows = [];

                if (precioPorPareja) {
                  // 1. Agrupar por categoría de precio (ID de TourPrecio)
                  final groups = <int?, List<int>>{};
                  for (final key in allPersonKeys) {
                    final catId = _preciosPorPersona[key]?.id;
                    groups.putIfAbsent(catId, () => []).add(key);
                  }

                  double pairSum = 0.0;
                  final leftovers = <int>[];

                  // 2. Formar parejas de la misma categoría
                  groups.forEach((catId, keys) {
                    final categoryPrice = resolvePrecio(keys.first);
                    for (int i = 0; i < keys.length; i += 2) {
                      if (i + 1 < keys.length) {
                        rows.add((
                          label:
                              '${personLabel(keys[i])} + ${personLabel(keys[i + 1])}',
                          price: categoryPrice,
                        ));
                        pairSum += categoryPrice;
                      } else {
                        leftovers.add(keys[i]);
                      }
                    }
                  });

                  // 3. Formar parejas con los "sobrantes" de categorías distintas
                  for (int i = 0; i < leftovers.length; i += 2) {
                    if (i + 1 < leftovers.length) {
                      final k1 = leftovers[i];
                      final k2 = leftovers[i + 1];
                      final cat1 = _preciosPorPersona[k1];
                      final cat2 = _preciosPorPersona[k2];
                      final double price = (cat1?.id == cat2?.id)
                          ? resolvePrecio(k1)
                          : basePrice;
                      rows.add((
                        label: '${personLabel(k1)} + ${personLabel(k2)}',
                        price: price,
                      ));
                      pairSum += price;
                    } else {
                      final k = leftovers[i];
                      final price = resolvePrecio(k);
                      rows.add((label: personLabel(k), price: price));
                      pairSum += price;
                    }
                  }
                  tourSub = pairSum;
                } else {
                  // ── Tour Normal (por persona) ──────────────────────────────
                  double personSum = 0.0;
                  for (final key in allPersonKeys) {
                    final price = resolvePrecio(key);
                    rows.add((label: personLabel(key), price: price));
                    personSum += price;
                  }
                  tourSub = personSum;
                }

                tourBreakdown = rows;
                efectiveUnitPrice = currentUnits > 0
                    ? tourSub / currentUnits
                    : 0.0;
              }

              tourSubtotalFinal = tourSub;
              descuentoTotal = _descuentoPorPersona * currentUnits;

              if (precioPorPareja) {
                tourUnitLabel =
                    'Tour (${currencyFmt.format(efectiveUnitPrice)}/pareja'
                    ' × $currentUnits pareja${currentUnits != 1 ? "s" : ""})';
              } else {
                tourUnitLabel =
                    'Tour (${currencyFmt.format(efectiveUnitPrice)}/persona'
                    ' × $currentPersonas persona${currentPersonas != 1 ? "s" : ""})';
              }
            }
            final valorSinDescuento =
                tourSubtotalFinal + vuelosTotal + hotelesTotal + serviciosTotal;
            final valorTotal = valorSinDescuento - descuentoTotal;

            final totalValidado = _pagos
                .where((p) => p.isValidated)
                .fold(0.0, (sum, p) => sum + p.monto);
            final saldoPendiente = valorTotal - totalValidado;

            return PremiumSectionCard(
              title: 'RESUMEN DE COSTOS',
              icon: Icons.payments_rounded,
              children: [
                // Desglose del tour por persona / pareja
                if (tour != null) ...[
                  if (tourBreakdown.isNotEmpty) ...[
                    ...tourBreakdown.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: _buildResumenRow(
                          item.label,
                          item.price,
                          currencyFmt,
                          isSubtitle: true,
                          icon: precioPorPareja
                              ? Icons.people_rounded
                              : Icons.person_rounded,
                          iconColor: SaasPalette.brand600,
                        ),
                      ),
                    ),
                    if (tourBreakdown.length > 1) ...[
                      const Divider(
                        color: SaasPalette.border,
                        height: 12,
                        indent: 22,
                      ),
                      _buildResumenRow(
                        'Subtotal tour',
                        tourSubtotalFinal,
                        currencyFmt,
                      ),
                    ],
                  ] else
                    _buildResumenRow(
                      tourUnitLabel,
                      tourSubtotalFinal,
                      currencyFmt,
                      isSubtitle: true,
                    ),
                ],
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
                        nombre,
                        svc?.cost ?? 0,
                        currencyFmt,
                        isSubtitle: true,
                        icon: Icons.room_service_rounded,
                        iconColor: SaasPalette.success,
                      ),
                    );
                  }),
                ],
                // Hoteles — detalle por hotel reserva
                if (_hotelReservas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._hotelReservas.map((h) {
                    final nombre = h.hotel?.nombre ?? 'Hotel';
                    final ciudad = h.hotel?.ciudad ?? '';
                    final label = ciudad.isNotEmpty
                        ? '$nombre ($ciudad)'
                        : nombre;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildResumenRow(
                        label,
                        h.valor ?? 0,
                        currencyFmt,
                        isSubtitle: true,
                        icon: Icons.hotel_rounded,
                        iconColor: SaasPalette.brand600,
                      ),
                    );
                  }),
                ],
                // Vuelos — detalle por vuelo
                if (_vuelos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._vuelos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final v = entry.value;
                    final aerolinea = v.aerolinea?.nombre ?? 'Vuelo ${i + 1}';
                    final ruta = v.origen.isNotEmpty && v.destino.isNotEmpty
                        ? '${v.origen} → ${v.destino}'
                        : '';
                    final esVuelta = v.tipoVuelo == 'vuelta';
                    final tipo = esVuelta ? 'Vuelta' : 'Ida';
                    final label = ruta.isNotEmpty
                        ? '$aerolinea · $ruta ($tipo)'
                        : '$aerolinea ($tipo)';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildResumenRow(
                        label,
                        v.precio ?? 0,
                        currencyFmt,
                        isSubtitle: true,
                        icon: esVuelta
                            ? Icons.flight_land_rounded
                            : Icons.flight_takeoff_rounded,
                        iconColor: esVuelta
                            ? SaasPalette.warning
                            : SaasPalette.brand600,
                      ),
                    );
                  }),
                ],
                // Campo de descuento por persona (solo si hay tour)
                if (tour != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          precioPorPareja
                              ? '− Descuento por pareja'
                              : '− Descuento por persona',
                          style: const TextStyle(
                            color: SaasPalette.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: SaasPalette.bgSubtle,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        width: 130,
                        child: TextFormField(
                          controller: _descuentoCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: const InputDecoration(
                            isDense: true,
                            prefixText: '\$ ',
                            prefixStyle: TextStyle(
                              color: SaasPalette.textTertiary,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _descuentoPorPersona = double.tryParse(v) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: SaasPalette.border),
                  if (descuentoTotal > 0) ...[
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '− ${currencyFmt.format(descuentoTotal)} total ($currentUnits ${precioPorPareja ? "pareja${currentUnits != 1 ? "s" : ""}" : "persona${currentUnits != 1 ? "s" : ""}"})',
                        style: const TextStyle(
                          color: SaasPalette.danger,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: SaasPalette.border),
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
                    valueColor: SaasPalette.danger,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: SaasPalette.border),
                  ),
                  _buildResumenRow(
                    'SALDO PENDIENTE',
                    saldoPendiente,
                    currencyFmt,
                    isTotal: true,
                    valueColor: saldoPendiente <= 0
                        ? SaasPalette.success
                        : SaasPalette.warning,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: SaasPalette.border),
                ),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Utilidad',
                        style: TextStyle(
                          color: SaasPalette.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: SaasPalette.bgSubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: 130,
                      child: TextFormField(
                        controller: _utilidadCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 13,
                        ),
                        decoration: const InputDecoration(
                          isDense: true,
                          prefixText: '\$ ',
                          prefixStyle: TextStyle(
                            color: SaasPalette.textTertiary,
                            fontSize: 13,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
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
    IconData? icon,
    Color? iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: iconColor ?? SaasPalette.textTertiary),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isTotal
                  ? SaasPalette.textPrimary
                  : SaasPalette.textSecondary,
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          fmt.format(value),
          style: TextStyle(
            color:
                valueColor ??
                (isTotal ? SaasPalette.success : SaasPalette.textSecondary),
            fontSize: isTotal ? 16 : 13,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHotelReservaSection() {
    return BlocBuilder<HotelBloc, HotelState>(
      builder: (context, hotelState) {
        final hoteles = hotelState is HotelLoaded
            ? hotelState.hoteles
            : <Hotel>[];

        return PremiumSectionCard(
          title: 'HOTEL RESERVA',
          icon: Icons.hotel_rounded,
          children: [
            if (_hotelReservas.isEmpty)
              const PremiumEmptyIndicator(
                msg: 'No hay hoteles agregados a esta reserva.',
                icon: Icons.hotel_rounded,
              ),
            ..._hotelReservas.asMap().entries.map((entry) {
              final idx = entry.key;
              final hr = entry.value;
              return _HotelReservaRow(
                hotelReserva: hr,
                hoteles: hoteles,
                onChanged: (updated) {
                  setState(() => _hotelReservas[idx] = updated);
                },
                onRemove: () {
                  setState(() => _hotelReservas.removeAt(idx));
                },
              );
            }),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _hotelReservas.add(
                    const HotelReserva(
                      numeroReserva: '',
                      fechaCheckin: '',
                      fechaCheckout: '',
                    ),
                  );
                });
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Agregar Hotel'),
              style: TextButton.styleFrom(
                foregroundColor: SaasPalette.brand600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPagosSection() {
    return PremiumSectionCard(
      title: 'PAGOS REALIZADOS',
      icon: Icons.payments_rounded,
      children: [
        if (_loadingPagos)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: SaasPalette.brand600),
            ),
          )
        else if (_pagos.isEmpty)
          const PremiumEmptyIndicator(
            msg: 'No hay pagos registrados para esta reserva.',
            icon: Icons.receipt_long_rounded,
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pagos.length,
            separatorBuilder: (_, __) =>
                const Divider(color: SaasPalette.border, height: 1),
            itemBuilder: (context, index) {
              final pago = _pagos[index];
              return _PagoCard(pago: pago);
            },
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: SaasPalette.brand600, size: 14),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              color: SaasPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIntegrantesSection() {
    // Resolve selected tour for per-person pricing
    Tour? selectedTour;
    if (_selectedTourId != null) {
      final tourState = context.read<TourBloc>().state;
      List<Tour> tours = [];
      if (tourState is ToursLoaded) {
        tours = tourState.tours;
      } else if (tourState is TourSaving && tourState.tours != null) {
        tours = tourState.tours!;
      } else if (tourState is TourSaved && tourState.tours != null) {
        tours = tourState.tours!;
      }
      selectedTour = tours.cast<Tour?>().firstWhere(
        (t) => t?.id == _selectedTourId,
        orElse: () => null,
      );
    }
    // Solo se asignan categorías individuales si el tour tiene precios por categoría
    // y NO es modo grupal con precios grupales definidos
    final bool esGrupal = selectedTour != null &&
        selectedTour.modoPrecio == 'grupal' &&
        selectedTour.preciosGrupales.isNotEmpty;
    final List<TourPrecio>? categorias =
        (selectedTour != null && selectedTour.precios.isNotEmpty && !esGrupal)
        ? selectedTour.precios
        : null;

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
              icon: const Icon(
                Icons.add_rounded,
                color: SaasPalette.brand600,
                size: 18,
              ),
              label: const Text(
                'Agregar',
                style: TextStyle(
                  color: SaasPalette.brand600,
                  fontWeight: FontWeight.bold,
                ),
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
              child: Divider(color: SaasPalette.border, height: 1),
            ),
            itemBuilder: (context, index) {
              return _IntegranteFormFields(
                integrante: _integrantes[index],
                isResponsable: false,
                onChanged: (val) {
                  setState(() => _integrantes[index] = val);
                },
                onDelete: () => _onDeleteIntegrante(index),
                categoriasDisponibles: categorias,
                selectedPrecio: categorias != null
                    ? _preciosPorPersona[index]
                    : null,
                onPrecioChanged: categorias != null
                    ? (val) => setState(
                        () =>
                            _preciosPorPersona = Map.from(_preciosPorPersona)
                              ..[index] = val,
                      )
                    : null,
                tourBasePrice: selectedTour?.price,
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
              icon: const Icon(
                Icons.add_rounded,
                color: SaasPalette.brand600,
                size: 18,
              ),
              label: const Text(
                'Agregar',
                style: TextStyle(
                  color: SaasPalette.brand600,
                  fontWeight: FontWeight.bold,
                ),
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
                            initialValue: _servicios[index] == 0
                                ? null
                                : _servicios[index],
                            dropdownColor: SaasPalette.bgCanvas,
                            isExpanded: true,
                            style: const TextStyle(
                              color: SaasPalette.textPrimary,
                              fontSize: 14,
                            ),
                            hint: const Text(
                              'Seleccionar servicio',
                              style: TextStyle(
                                color: SaasPalette.textTertiary,
                                fontSize: 14,
                              ),
                            ),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.room_service_outlined,
                                color: SaasPalette.brand600,
                              ),
                              filled: true,
                              fillColor: SaasPalette.bgSubtle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
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
                            color: SaasPalette.danger,
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
              'Vuelos (opcionales)',
              style: TextStyle(color: SaasPalette.textSecondary, fontSize: 12),
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
              icon: const Icon(
                Icons.add_rounded,
                color: SaasPalette.brand600,
                size: 18,
              ),
              label: const Text(
                'Agregar vuelo',
                style: TextStyle(
                  color: SaasPalette.brand600,
                  fontWeight: FontWeight.bold,
                ),
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
              child: Divider(color: SaasPalette.border, height: 1),
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

  Widget _buildPdfButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2563EB), width: 1),
      ),
      child: InkWell(
        onTap: _generatingPdf ? null : _generateAndShowPdf,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_generatingPdf)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2563EB),
                  ),
                )
              else
                const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              const SizedBox(width: 10),
              Text(
                _generatingPdf
                    ? 'Generando PDF...'
                    : 'Generar PDF de la reserva',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
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
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: SaasPalette.bgCanvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: SaasPalette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayCliente.nombre,
                        style: const TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              Icons.email_outlined,
                              displayCliente.correo,
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
                    color: SaasPalette.brand600,
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
              color: SaasPalette.brand50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SaasPalette.brand600.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: SaasPalette.brand600.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SaasPalette.brand600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: const Text(
                    'Cargando responsable...',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 14,
                    ),
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
                    color: SaasPalette.bgSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: field.hasError
                          ? SaasPalette.danger
                          : SaasPalette.border,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_search_rounded,
                        color: SaasPalette.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isLoading
                              ? 'Cargando clientes...'
                              : 'Seleccionar cliente *',
                          style: const TextStyle(
                            color: SaasPalette.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SaasPalette.brand600,
                          ),
                        )
                      else
                        const Icon(
                          Icons.search_rounded,
                          color: SaasPalette.textTertiary,
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
                  style: const TextStyle(
                    color: SaasPalette.danger,
                    fontSize: 12,
                  ),
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
  final List<TourPrecio>? categoriasDisponibles;
  final TourPrecio? selectedPrecio;
  final ValueChanged<TourPrecio?>? onPrecioChanged;
  final double? tourBasePrice;

  const _IntegranteFormFields({
    required this.integrante,
    required this.isResponsable,
    required this.onChanged,
    this.onDelete,
    this.categoriasDisponibles,
    this.selectedPrecio,
    this.onPrecioChanged,
    this.tourBasePrice,
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
  late bool _ocupaAsiento;

  static const _tiposDocumento = ['CC', 'TI', 'Pasaporte'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.integrante.nombre);
    _phoneCtrl = TextEditingController(text: widget.integrante.telefono);
    _documentoCtrl = TextEditingController(text: widget.integrante.documento);
    _dob = widget.integrante.fechaNacimiento;
    _tipoDocumento = widget.integrante.tipoDocumento.isNotEmpty
        ? widget.integrante.tipoDocumento
        : 'CC';
    _ocupaAsiento = widget.integrante.ocupaAsiento;
  }

  // static String _normalizeTipoDocumento(String raw) {
  //   switch (raw.toLowerCase().trim()) {
  //     case 'cc':
  //     case 'cedula':
  //     case 'cédula':
  //       return 'CC';
  //     case 'ti':
  //     case 'tarjeta identidad':
  //     case 'tarjeta de identidad':
  //       return 'TI';
  //     case 'pasaporte':
  //       return 'Pasaporte';
  //     default:
  //       return _tiposDocumento.contains(raw) ? raw : 'CC';
  //   }
  // }

  @override
  void didUpdateWidget(_IntegranteFormFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.integrante != widget.integrante) {
      if (_nameCtrl.text != widget.integrante.nombre) {
        _nameCtrl.text = widget.integrante.nombre;
      }
      if (_phoneCtrl.text != widget.integrante.telefono) {
        _phoneCtrl.text = widget.integrante.telefono;
      }
      if (_documentoCtrl.text != widget.integrante.documento) {
        _documentoCtrl.text = widget.integrante.documento;
      }
      _dob = widget.integrante.fechaNacimiento;
      _tipoDocumento = widget.integrante.tipoDocumento.isNotEmpty
          ? widget.integrante.tipoDocumento
          : 'CC';
      _ocupaAsiento = widget.integrante.ocupaAsiento;
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
        tourPrecioId: widget.integrante.tourPrecioId,
        precioAplicado: widget.integrante.precioAplicado,
        ocupaAsiento: _ocupaAsiento,
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
        );
      },
    );
    if (picked != null) {
      setState(() => _dob = picked);
      _notifyChange();
    }
  }

  Widget _buildPrecioSelector() {
    final currencyFmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final basePrice = widget.tourBasePrice ?? 0.0;
    final selected = widget.selectedPrecio;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected != null ? SaasPalette.brand600 : SaasPalette.border,
          width: selected != null ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sell_rounded,
            color: selected != null
                ? SaasPalette.brand600
                : SaasPalette.textTertiary,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRECIO',
                  style: TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<TourPrecio?>(
                    value: selected,
                    isExpanded: true,
                    isDense: true,
                    dropdownColor: SaasPalette.bgCanvas,
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 13,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: SaasPalette.brand600,
                      size: 18,
                    ),
                    items: [
                      DropdownMenuItem<TourPrecio?>(
                        value: null,
                        child: Text(
                          'Base — ${currencyFmt.format(basePrice)}',
                          style: const TextStyle(
                            color: SaasPalette.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...widget.categoriasDisponibles!.map((p) {
                        final edadStr = (p.edadMin != null || p.edadMax != null)
                            ? ' (${p.edadMin ?? 0}-${p.edadMax ?? '∞'} años)'
                            : '';
                        return DropdownMenuItem<TourPrecio?>(
                          value: p,
                          child: Text(
                            '${p.descripcion}$edadStr — ${currencyFmt.format(p.precio)}',
                            style: const TextStyle(
                              color: SaasPalette.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                    ],
                    onChanged: widget.onPrecioChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                const Icon(
                  Icons.person_outline,
                  color: SaasPalette.warning,
                  size: 18,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Acompañante',
                  style: TextStyle(
                    color: SaasPalette.warning,
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
                    color: SaasPalette.textTertiary,
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
                              ? SaasPalette.brand50
                              : SaasPalette.bgSubtle,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selected
                                ? SaasPalette.brand600.withValues(alpha: 0.6)
                                : SaasPalette.border,
                          ),
                        ),
                        child: Text(
                          tipo,
                          style: TextStyle(
                            color: selected
                                ? SaasPalette.brand600
                                : SaasPalette.textSecondary,
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
              onChanged: (_) => _notifyChange(),
            ),
            if (widget.categoriasDisponibles != null &&
                widget.categoriasDisponibles!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildPrecioSelector(),
            ],
            const SizedBox(height: 20),
            // ── Ocupa asiento ──────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OCUPA ASIENTO',
                  style: TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _AsientoChip(
                      label: 'Sí',
                      selected: _ocupaAsiento,
                      onTap: () {
                        setState(() => _ocupaAsiento = true);
                        _notifyChange();
                      },
                    ),
                    _AsientoChip(
                      label: 'No',
                      selected: !_ocupaAsiento,
                      onTap: () {
                        setState(() => _ocupaAsiento = false);
                        _notifyChange();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FECHA DE NACIMIENTO',
                  style: TextStyle(
                    color: SaasPalette.textTertiary,
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
                      border: Border.all(color: SaasPalette.border),
                      color: SaasPalette.bgSubtle,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cake_rounded,
                          color: SaasPalette.brand600,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _dob != null
                              ? '${_dob!.day}/${_dob!.month}/${_dob!.year}'
                              : 'Seleccionar fecha (Opcional)',
                          style: const TextStyle(
                            color: SaasPalette.textPrimary,
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
                color: SaasPalette.danger,
                size: 22,
              ),
              onPressed: widget.onDelete,
            ),
          ),
      ],
    );
  }
}

class _AsientoChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AsientoChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? SaasPalette.brand50 : SaasPalette.bgSubtle,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? SaasPalette.brand600.withValues(alpha: 0.6)
                : SaasPalette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? SaasPalette.brand600
                : SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
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
              color: SaasPalette.bgCanvas,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: SaasPalette.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
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
                        color: SaasPalette.brand600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Seleccionar Cliente',
                          style: TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: SaasPalette.textTertiary,
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
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 14,
                    ),
                    onChanged: (v) =>
                        setState(() {}), // Forzar re-filtrado local
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre, correo o documento...',
                      hintStyle: const TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: SaasPalette.brand600,
                        size: 18,
                      ),
                      filled: true,
                      fillColor: SaasPalette.bgSubtle,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: SaasPalette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: SaasPalette.brand600,
                        ),
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
                            style: TextStyle(
                              color: SaasPalette.textTertiary,
                              fontSize: 13,
                            ),
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
                                      color: SaasPalette.textPrimary.withValues(
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
                                          color: SaasPalette.brand600
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            c.nombre.isNotEmpty
                                                ? c.nombre[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: SaasPalette.brand600,
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
                                                color: SaasPalette.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              '${c.tipoDocumento} ${c.documento}',
                                              style: TextStyle(
                                                color:
                                                    SaasPalette.textSecondary,
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
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: SaasPalette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.tour_rounded,
                    color: SaasPalette.brand600,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Seleccionar Tour',
                      style: TextStyle(
                        color: SaasPalette.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: SaasPalette.textTertiary,
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
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre del tour...',
                  hintStyle: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: SaasPalette.brand600,
                    size: 18,
                  ),
                  filled: true,
                  fillColor: SaasPalette.bgSubtle,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SaasPalette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: SaasPalette.brand600),
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
                        style: TextStyle(
                          color: SaasPalette.textTertiary,
                          fontSize: 13,
                        ),
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
                                  color: SaasPalette.border.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.tour_rounded,
                                    color: SaasPalette.brand600,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      t.name,
                                      style: const TextStyle(
                                        color: SaasPalette.textPrimary,
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

// ─── Precio helpers ───────────────────────────────────────────────────────────

class _PrecioSectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PrecioSectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: SaasPalette.brand600, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _PrecioRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final String precio;
  final bool destacado;

  const _PrecioRow({
    required this.label,
    this.sublabel,
    required this.precio,
    this.destacado = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: destacado ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: const TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            precio,
            style: TextStyle(
              color: SaasPalette.success,
              fontSize: destacado ? 15 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PagoCard extends StatelessWidget {
  final PagoRealizado pago;

  const _PagoCard({required this.pago});

  @override
  Widget build(BuildContext context) {
    final currencyFmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: pago.isValidated
                  ? SaasPalette.success.withValues(alpha: 0.1)
                  : SaasPalette.textTertiary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              pago.isValidated ? Icons.verified_rounded : Icons.history_rounded,
              color: pago.isValidated
                  ? SaasPalette.success
                  : SaasPalette.textTertiary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pago.metodoPago.isNotEmpty
                      ? pago.metodoPago
                      : 'Pago #${pago.id}',
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  pago.referencia.isNotEmpty
                      ? pago.referencia
                      : 'Sin referencia',
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  pago.fechaDocumento.isNotEmpty
                      ? pago.fechaDocumento
                      : 'Sin fecha',
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            currencyFmt.format(pago.monto),
            style: const TextStyle(
              color: SaasPalette.success,
              fontSize: 15,
              fontWeight: FontWeight.w700,
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
        Icon(icon, color: SaasPalette.textTertiary, size: 15),
        const SizedBox(width: 10),
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: SaasPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: SaasPalette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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
  late TextEditingController _reservaVueloCtrl;
  int? _aerolineaId;
  late String _clase;
  late String _tipoVuelo;

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
    _precioCtrl = TextEditingController(
      text: v.precio != null
          ? NumberFormat.decimalPattern('es_CO').format(v.precio)
          : '',
    );
    _reservaVueloCtrl = TextEditingController(text: v.reservaVuelo);
    _aerolineaId = v.aerolineaId ?? v.aerolinea?.id;
    _clase = v.clase.isNotEmpty ? v.clase : 'economy';
    _tipoVuelo = v.tipoVuelo.isNotEmpty ? v.tipoVuelo : 'ida';
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
    _reservaVueloCtrl.dispose();
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
        precio: double.tryParse(
          _precioCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.'),
        ),
        reservaVuelo: _reservaVueloCtrl.text.trim(),
        tipoVuelo: _tipoVuelo,
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
    prefixIcon: Icon(icon, color: SaasPalette.brand600, size: 18),
    hintText: hint,
    hintStyle: const TextStyle(color: SaasPalette.textTertiary, fontSize: 13),
    filled: true,
    fillColor: SaasPalette.bgSubtle,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: SaasPalette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: SaasPalette.brand600),
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
                const Icon(
                  Icons.flight_rounded,
                  color: SaasPalette.brand600,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Vuelo ${widget.index + 1}',
                  style: const TextStyle(
                    color: SaasPalette.brand600,
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
              style: const TextStyle(
                color: SaasPalette.textSecondary,
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
                  color: SaasPalette.bgSubtle,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SaasPalette.border),
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
                            color: SaasPalette.brand600,
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
                            color: SaasPalette.textPrimary,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ] else ...[
                      Icon(
                        Icons.business_rounded,
                        color: SaasPalette.textTertiary.withValues(alpha: 0.5),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.loadingAerolineas
                              ? 'Cargando aerolíneas...'
                              : 'Seleccionar aerolínea',
                          style: const TextStyle(
                            color: SaasPalette.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: SaasPalette.textTertiary,
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
              style: const TextStyle(
                color: SaasPalette.textPrimary,
                fontSize: 14,
              ),
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
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: _dec('Origen', Icons.flight_takeoff_rounded),
                    onChanged: (_) => _notify(),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: SaasPalette.textTertiary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _destinoCtrl,
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 14,
                    ),
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
                          color: Colors.black,
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
                          color: Colors.black,
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
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 14,
                    ),
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
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 14,
                    ),
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
              dropdownColor: SaasPalette.bgCanvas,
              style: const TextStyle(
                color: SaasPalette.textPrimary,
                fontSize: 14,
              ),
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
            // Tipo de vuelo (ida / vuelta)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de vuelo *',
                  style: TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _TipoVueloChip(
                      label: 'Ida',
                      icon: Icons.flight_takeoff_rounded,
                      selected: _tipoVuelo == 'ida',
                      onTap: () {
                        setState(() => _tipoVuelo = 'ida');
                        _notify();
                      },
                    ),
                    const SizedBox(width: 10),
                    _TipoVueloChip(
                      label: 'Vuelta',
                      icon: Icons.flight_land_rounded,
                      selected: _tipoVuelo == 'vuelta',
                      onTap: () {
                        setState(() => _tipoVuelo = 'vuelta');
                        _notify();
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Precio del vuelo (solo si tipo reserva es vuelos o si se desea poner)
            // TextFormField(
            //   controller: _precioCtrl,
            //   style: const TextStyle(
            //     color: SaasPalette.textPrimary,
            //     fontSize: 14,
            //   ),
            //   decoration: _dec('Precio del vuelo ', Icons.attach_money_rounded),
            //   inputFormatters: [ThousandsSeparatorInputFormatter()],
            //   keyboardType: const TextInputType.numberWithOptions(
            //     decimal: true,
            //   ),
            //   onChanged: (_) => _notify(),
            // ),
            PremiumTextField(
              controller: _precioCtrl,
              label: 'Costo del vuelo',
              icon: Icons.attach_money_rounded,
              inputFormatters: [ThousandsSeparatorInputFormatter()],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (_) => null,
              onChanged: (_) => _notify(),
            ),

            const SizedBox(height: 12),
            // Reserva vuelo (obligatorio)
            TextFormField(
              controller: _reservaVueloCtrl,
              style: const TextStyle(
                color: SaasPalette.textPrimary,
                fontSize: 14,
              ),
              decoration: _dec(
                'Reserva vuelo (ej. ABC-2026-001)',
                Icons.confirmation_number_rounded,
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'La reserva del vuelo es requerida'
                  : null,
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
              color: SaasPalette.danger,
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
            color: Colors.white.withValues(alpha: 0.95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: D.bg)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.business_rounded,
                        color: SaasPalette.brand600,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Seleccionar Aerolínea',
                        style: TextStyle(
                          color: D.bg,
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
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o código IATA...',
                      hintStyle: const TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: SaasPalette.brand600,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: SaasPalette.bgSubtle,
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
                                                color: SaasPalette.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              a.pais ?? 'Internacional',
                                              style: const TextStyle(
                                                color:
                                                    SaasPalette.textSecondary,
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
                                          color: SaasPalette.brand50,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          a.codigoIata,
                                          style: const TextStyle(
                                            color: SaasPalette.brand600,
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
        color: SaasPalette.brand50,
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Text(
        iata,
        style: TextStyle(
          color: SaasPalette.brand600,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
        overflow: TextOverflow.clip,
      ),
    );
  }
}

// ─── Tipo Vuelo Chip ─────────────────────────────────────────────────────────

class _TipoVueloChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TipoVueloChip({
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? SaasPalette.brand600 : SaasPalette.bgSubtle,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? SaasPalette.brand600 : SaasPalette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: selected ? Colors.white : SaasPalette.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : SaasPalette.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hotel Reserva Row Widget ──────────────────────────────────────────────

class _HotelReservaRow extends StatefulWidget {
  final HotelReserva hotelReserva;
  final List<Hotel> hoteles;
  final ValueChanged<HotelReserva> onChanged;
  final VoidCallback onRemove;

  const _HotelReservaRow({
    required this.hotelReserva,
    required this.hoteles,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_HotelReservaRow> createState() => _HotelReservaRowState();
}

class _HotelReservaRowState extends State<_HotelReservaRow> {
  late final TextEditingController _numeroCtrl;
  late final TextEditingController _checkinCtrl;
  late final TextEditingController _checkoutCtrl;
  late final TextEditingController _valorCtrl;
  int? _selectedHotelId;

  @override
  void initState() {
    super.initState();
    _numeroCtrl = TextEditingController(
      text: widget.hotelReserva.numeroReserva,
    );
    _checkinCtrl = TextEditingController(
      text: widget.hotelReserva.fechaCheckin,
    );
    _checkoutCtrl = TextEditingController(
      text: widget.hotelReserva.fechaCheckout,
    );
    _valorCtrl = TextEditingController(
      text: widget.hotelReserva.valor != null
          ? NumberFormat.decimalPattern(
              'es_CO',
            ).format(widget.hotelReserva.valor)
          : '',
    );
    _selectedHotelId =
        widget.hotelReserva.hotelId ?? widget.hotelReserva.hotel?.id;
  }

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _checkinCtrl.dispose();
    _checkoutCtrl.dispose();
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _openHotelPicker(BuildContext ctx) async {
    final result = await showDialog<Hotel>(
      context: ctx,
      builder: (_) => _HotelPickerDialog(hoteles: widget.hoteles),
    );
    if (result != null) {
      setState(() => _selectedHotelId = result.id);
      _notify();
    }
  }

  void _notify() {
    final hotel = widget.hoteles.cast<Hotel?>().firstWhere(
      (h) => h?.id == _selectedHotelId,
      orElse: () => null,
    );
    widget.onChanged(
      HotelReserva(
        id: widget.hotelReserva.id,
        hotelId: _selectedHotelId,
        hotel: hotel,
        numeroReserva: _numeroCtrl.text.trim(),
        fechaCheckin: _checkinCtrl.text.trim(),
        fechaCheckout: _checkoutCtrl.text.trim(),
        valor: double.tryParse(
          _valorCtrl.text.trim().replaceAll('.', '').replaceAll(',', '.'),
        ),
      ),
    );
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
      _notify();
    }
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    prefixIcon: Icon(icon, color: SaasPalette.brand600, size: 18),
    hintText: hint,
    hintStyle: const TextStyle(color: SaasPalette.textTertiary, fontSize: 13),
    filled: true,
    fillColor: SaasPalette.bgSubtle,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: SaasPalette.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: SaasPalette.brand600),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: SaasPalette.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: SaasPalette.danger),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: SaasPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: SaasPalette.brand600.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.hotel_rounded,
                      color: SaasPalette.brand600,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Hotel Reserva',
                    style: TextStyle(
                      color: SaasPalette.brand600,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Selector de hotel
              FormField<int>(
                validator: (_) =>
                    _selectedHotelId == null ? 'Seleccione un hotel' : null,
                builder: (field) {
                  final selectedHotel = widget.hoteles
                      .cast<Hotel?>()
                      .firstWhere(
                        (h) => h?.id == _selectedHotelId,
                        orElse: () => null,
                      );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _openHotelPicker(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: SaasPalette.bgSubtle,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: field.hasError
                                  ? SaasPalette.danger
                                  : SaasPalette.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.hotel_rounded,
                                size: 18,
                                color: selectedHotel != null
                                    ? SaasPalette.brand600
                                    : SaasPalette.brand600,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: selectedHotel != null
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedHotel.nombre,
                                            style: const TextStyle(
                                              color: SaasPalette.textPrimary,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            selectedHotel.ciudad,
                                            style: const TextStyle(
                                              color: SaasPalette.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Seleccionar hotel',
                                        style: TextStyle(
                                          color: SaasPalette.textTertiary,
                                          fontSize: 13,
                                        ),
                                      ),
                              ),
                              const Icon(
                                Icons.search_rounded,
                                size: 18,
                                color: SaasPalette.brand600,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (field.hasError) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 14),
                          child: Text(
                            field.errorText!,
                            style: const TextStyle(
                              color: SaasPalette.danger,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),

              // Número de reserva
              TextFormField(
                controller: _numeroCtrl,
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 14,
                ),
                decoration: _dec(
                  'Número de reserva (ej. HTL-2026-001)',
                  Icons.confirmation_number_rounded,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El número es requerido'
                    : null,
                onChanged: (_) => _notify(),
              ),
              const SizedBox(height: 12),

              // Valor
              // TextField(
              //   controller: _valorCtrl,
              //   keyboardType: const TextInputType.numberWithOptions(
              //     decimal: true,
              //   ),
              //   inputFormatters: [
              //     FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              //   ],
              //   style: const TextStyle(
              //     color: SaasPalette.textPrimary,
              //     fontSize: 14,
              //   ),
              //   decoration: _dec('Valor del hotel', Icons.attach_money_rounded),
              //   onChanged: (_) => _notify(),
              // ),
              PremiumTextField(
                controller: _valorCtrl,
                label: 'Valor del hotel',
                icon: Icons.attach_money_rounded,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (_) => null,
                onChanged: (_) => _notify(),
              ),

              const SizedBox(height: 12),

              // Fechas check-in / check-out
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(_checkinCtrl),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _checkinCtrl,
                          style: const TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: _dec(
                            'Check-in',
                            Icons.calendar_today_rounded,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _pickDate(_checkoutCtrl),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _checkoutCtrl,
                          style: const TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: _dec(
                            'Check-out',
                            Icons.calendar_today_rounded,
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Requerido'
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Botón eliminar — esquina superior derecha
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: SaasPalette.danger,
              size: 20,
            ),
            onPressed: widget.onRemove,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }
}

// ─── Hotel Picker Dialog ──────────────────────────────────────────────────────

class _HotelPickerDialog extends StatefulWidget {
  final List<Hotel> hoteles;

  const _HotelPickerDialog({required this.hoteles});

  @override
  State<_HotelPickerDialog> createState() => _HotelPickerDialogState();
}

class _HotelPickerDialogState extends State<_HotelPickerDialog> {
  final _searchCtrl = TextEditingController();
  List<Hotel> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.hoteles.where((h) => h.isActive).toList();
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.hoteles
          .where((h) => h.isActive)
          .where(
            (h) =>
                h.nombre.toLowerCase().contains(q) ||
                h.ciudad.toLowerCase().contains(q),
          )
          .toList();
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
            color: Colors.white.withValues(alpha: 0.95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: SaasPalette.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hotel_rounded,
                        color: SaasPalette.brand600,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Seleccionar Hotel',
                          style: TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          Navigator.pop(context);
                          await Navigator.of(
                            context,
                          ).pushNamed(AppRouter.hotelCreate);
                        },
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Nuevo'),
                        style: TextButton.styleFrom(
                          foregroundColor: SaasPalette.brand600,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: SaasPalette.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o ciudad...',
                      hintStyle: const TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: SaasPalette.brand600,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: SaasPalette.bgSubtle,
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
                            msg: 'No se encontraron hoteles',
                            icon: Icons.search_off_rounded,
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, index) {
                            final h = _filtered[index];
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.pop(context, h),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: SaasPalette.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: SaasPalette.brand50,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.hotel_rounded,
                                          color: SaasPalette.brand600,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              h.nombre,
                                              style: const TextStyle(
                                                color: SaasPalette.textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              h.ciudad,
                                              style: const TextStyle(
                                                color:
                                                    SaasPalette.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: SaasPalette.textTertiary,
                                        size: 18,
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

// ─────────────────────────────────────────────────────────────────────────────
//  DIÁLOGO RESERVA CREADA
// ─────────────────────────────────────────────────────────────────────────────
class _ReservaCreatedDialog extends StatefulWidget {
  final Reserva reserva;
  const _ReservaCreatedDialog({required this.reserva});

  @override
  State<_ReservaCreatedDialog> createState() => _ReservaCreatedDialogState();
}

class _ReservaCreatedDialogState extends State<_ReservaCreatedDialog> {
  bool _copied = false;

  void _copyLink() {
    final link = widget.reserva.seleccionLink ?? '';
    Clipboard.setData(ClipboardData(text: link));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  void _openLink() {
    final link = widget.reserva.seleccionLink ?? '';
    if (link.isNotEmpty) webLib.window.open(link, '_blank', '');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;
    final nombreResponsable = r.responsable?.nombre ?? 'Sin nombre';
    final documento = '${r.responsable?.documento ?? ''}'.trim();
    final tourNombre = r.tour?.name ?? 'Tour';
    final link = r.seleccionLink ?? '';

    return Dialog(
      backgroundColor: SaasPalette.bgCanvas,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: SaasPalette.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: SaasPalette.success,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Reserva Creada!',
                style: TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                r.idReserva ?? '',
                style: const TextStyle(
                  color: SaasPalette.textTertiary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: SaasPalette.bgSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SaasPalette.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DialogInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Responsable',
                      value: nombreResponsable,
                    ),
                    const SizedBox(height: 8),
                    _DialogInfoRow(
                      icon: Icons.badge_outlined,
                      label: 'Documento',
                      value: documento.isEmpty ? 'N/A' : documento,
                      copiable: documento.isNotEmpty,
                    ),
                    const SizedBox(height: 8),
                    _DialogInfoRow(
                      icon: Icons.tour_outlined,
                      label: 'Tour',
                      value: tourNombre,
                    ),
                    if (r.asientosBus.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.event_seat_rounded,
                            size: 14,
                            color: SaasPalette.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Asientos: ',
                            style: TextStyle(
                              color: SaasPalette.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          Flexible(
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: r.asientosBus
                                  .map(
                                    (asiento) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: SaasPalette.brand600.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: SaasPalette.brand600
                                              .withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        asiento,
                                        style: const TextStyle(
                                          color: SaasPalette.brand600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (link.isNotEmpty) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Link de Selección de Asientos',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: SaasPalette.brand50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: SaasPalette.brand600.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        color: SaasPalette.brand600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          link,
                          style: const TextStyle(
                            color: SaasPalette.brand600,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 16,
                        ),
                        label: Text(_copied ? 'Copiado' : 'Copiar link'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _copied
                              ? SaasPalette.success
                              : SaasPalette.brand600,
                          side: BorderSide(
                            color: _copied
                                ? SaasPalette.success
                                : SaasPalette.brand600,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _copyLink,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, size: 16),
                        label: const Text('Abrir link'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SaasPalette.brand600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _openLink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(color: SaasPalette.textTertiary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogInfoRow extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copiable;

  const _DialogInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.copiable = false,
  });

  @override
  State<_DialogInfoRow> createState() => _DialogInfoRowState();
}

class _DialogInfoRowState extends State<_DialogInfoRow> {
  bool _copied = false;

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.value));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(widget.icon, size: 14, color: SaasPalette.textTertiary),
        const SizedBox(width: 8),
        Text(
          '${widget.label}: ',
          style: const TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 13,
          ),
        ),
        Flexible(
          child: Text(
            widget.value,
            style: const TextStyle(
              color: SaasPalette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (widget.copiable) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _copy,
            child: Tooltip(
              message: _copied ? 'Copiado' : 'Copiar',
              child: Icon(
                _copied ? Icons.check_rounded : Icons.copy_rounded,
                size: 14,
                color: _copied ? SaasPalette.success : SaasPalette.textTertiary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
