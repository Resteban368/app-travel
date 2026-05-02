import 'dart:ui';

import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/core/di/injection_container.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/platform_network_image.dart';
import 'package:agente_viajes/core/widgets/premium_form_widgets.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:agente_viajes/features/reservas/domain/entities/aerolinea.dart';
import 'package:agente_viajes/features/reservas/domain/repositories/reserva_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/cotizacion.dart';
import '../../domain/entities/respuesta_cotizacion.dart';
import '../../domain/repositories/cotizacion_repository.dart';
import '../../domain/repositories/respuesta_cotizacion_repository.dart';

import '../../../../core/widgets/saas_ui_components.dart';
import '../../../../config/app_router.dart';

// ── Mutable state helpers ─────────────────────────────────────────────────────

class _VueloData {
  int? aerolineaId;
  Aerolinea? aerolinea;
  String tipoVuelo = 'ida'; // 'ida' | 'vuelta'
  final numeroVueloCtrl = TextEditingController();
  final origenCtrl = TextEditingController();
  final destinoCtrl = TextEditingController();
  final horaSalidaCtrl = TextEditingController();
  final horaLlegadaCtrl = TextEditingController();
  final costoCtrl = TextEditingController();
  final numeroPasajerosCtrl = TextEditingController(text: '1');
  DateTime? fecha;

  void dispose() {
    numeroVueloCtrl.dispose();
    origenCtrl.dispose();
    destinoCtrl.dispose();
    horaSalidaCtrl.dispose();
    horaLlegadaCtrl.dispose();
    costoCtrl.dispose();
    numeroPasajerosCtrl.dispose();
  }
}

class _HotelData {
  final nombreCtrl = TextEditingController();
  String tipoHabitacion = 'Individual (1 persona)';
  final List<String> queIncluye = [];
  DateTime? fechaEntrada;
  DateTime? fechaSalida;
  final precioAdultoCtrl = TextEditingController();
  final precioMenorCtrl = TextEditingController();
  final precioTotalCtrl = TextEditingController();
  // Multi-foto
  final List<String> fotos = [];
  final fotoUrlCtrl = TextEditingController();
  int activeFotoIndex = 0;

  void dispose() {
    nombreCtrl.dispose();
    precioAdultoCtrl.dispose();
    precioMenorCtrl.dispose();
    precioTotalCtrl.dispose();
    fotoUrlCtrl.dispose();
  }
}

class _AdicionalData {
  final nombreCtrl = TextEditingController();
  final descripcionCtrl = TextEditingController();
  final precioCtrl = TextEditingController();

  void dispose() {
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    precioCtrl.dispose();
  }
}

// ── Main screen ───────────────────────────────────────────────────────────────

class RespuestaCotizacionFormScreen extends StatefulWidget {
  final Cotizacion? cotizacion;
  final RespuestaCotizacion? respuesta;
  const RespuestaCotizacionFormScreen({
    super.key,
    this.cotizacion,
    this.respuesta,
  });

  @override
  State<RespuestaCotizacionFormScreen> createState() =>
      _RespuestaCotizacionFormScreenState();
}

class _RespuestaCotizacionFormScreenState
    extends State<RespuestaCotizacionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Aerolineas
  List<Aerolinea> _aerolineas = [];
  bool _loadingAerolineas = false;

  // Cotizacion vinculada (si se carga asincrónicamente)
  Cotizacion? _loadedCotizacion;
  bool _loadingCotizacion = false;

  // Título
  final _tituloCtrl = TextEditingController();

  // Imágenes
  final _imagenUrlCtrl = TextEditingController();
  final List<String> _imagenes = [];
  int _activeImageIndex = 0;

  // Items incluidos
  final _itemCtrl = TextEditingController();
  final List<String> _itemsIncluidos = [];

  // Items no incluidos
  final _itemNoIncluidoCtrl = TextEditingController();
  final List<String> _itemsNoIncluidos = [];

  // Vuelos
  final List<_VueloData> _vuelos = [];

  // Hoteles
  final List<_HotelData> _hoteles = [];

  // Adicionales
  final List<_AdicionalData> _adicionales = [];

  // Condiciones generales
  final _condicionesCtrl = TextEditingController();

  static const _tipoHabitacionOpciones = [
    'Individual (1 persona)',
    'Doble - Cama Matrimonial',
    'Doble - Dos Camas',
    'Triple (3 personas)',
    'Cuádruple / Familiar (4+ personas)',
    'Suite Júnior',
    'Suite Ejecutiva',
    'Suite Presidencial',
  ];

  static const _incluyeOpciones = [
    'Todo Incluido',
    'Todas las Comidas',
    'Desayuno',
    'Almuerzo',
    'Cena',
    'Snacks',
    'Bebidas Alcohólicas',
    'Bebidas No Alcohólicas',
    'Servicio a la Habitación',
    'Acceso a Zonas Comunes',
  ];

  static final _dateFmt = DateFormat('dd MMM yyyy', 'es_CO');

  @override
  void initState() {
    super.initState();
    _loadAerolineas();
    if (widget.respuesta != null) {
      _populateFromRespuesta(widget.respuesta!);
      if (widget.respuesta!.cotizacionId != null && widget.cotizacion == null) {
        _loadLinkedCotizacion(widget.respuesta!.cotizacionId!);
      }
    } else if (widget.cotizacion != null) {
      _populateFromCotizacion(widget.cotizacion!);
    }
  }

  Future<void> _loadLinkedCotizacion(int id) async {
    setState(() => _loadingCotizacion = true);
    try {
      final cot = await sl<CotizacionRepository>().getCotizacion(id);
      if (mounted) setState(() => _loadedCotizacion = cot);
    } catch (_) {
      // silencioso
    } finally {
      if (mounted) setState(() => _loadingCotizacion = false);
    }
  }

  void _populateFromCotizacion(Cotizacion c) {
    // _tituloCtrl.text = 'Propuesta de Viaje - ${c.nombreCompleto}';
    // _condicionesCtrl.text =
    //     'Esta propuesta se basa en los detalles proporcionados: ${c.detallesPlan}.';

    // Si tiene origen/destino, podemos pre-cargar un tramo de vuelo
    if ((c.origen != null && c.origen!.isNotEmpty) ||
        (c.destino != null && c.destino!.isNotEmpty)) {
      final data = _VueloData();
      data.origenCtrl.text = c.origen ?? '';
      data.destinoCtrl.text = c.destino ?? '';
      data.numeroPasajerosCtrl.text = c.numeroPasajeros.toString();
      if (c.fechaSalida != null && c.fechaSalida!.isNotEmpty) {
        data.fecha = DateTime.tryParse(c.fechaSalida!);
      }
      data.costoCtrl.addListener(_refreshResumen);
      data.origenCtrl.addListener(_refreshResumen);
      data.destinoCtrl.addListener(_refreshResumen);
      _vuelos.add(data);
    }

    // // Si tiene más de un pasajero o especificaciones, podríamos agregarlas a condiciones
    // if (c.especificaciones != null && c.especificaciones!.isNotEmpty) {
    //   _condicionesCtrl.text += '\n\nEspecificaciones: ${c.especificaciones}';
    // }
  }

  void _populateFromRespuesta(RespuestaCotizacion r) {
    _tituloCtrl.text = r.tituloViaje;
    _imagenes.addAll(r.imagenesDestino);
    _itemsIncluidos.addAll(r.itemsIncluidos);
    _itemsNoIncluidos.addAll(r.itemsNoIncluidos);
    _condicionesCtrl.text = r.condicionesGenerales;

    for (final v in r.vuelos) {
      final data = _VueloData()
        ..tipoVuelo = v.tipo
        ..aerolineaId = v.aerolineaId
        ..fecha = v.fecha.isNotEmpty ? DateTime.tryParse(v.fecha) : null;
      data.numeroVueloCtrl.text = v.numeroVuelo;
      data.origenCtrl.text = v.origen;
      data.destinoCtrl.text = v.destino;
      data.horaSalidaCtrl.text = v.horaSalida;
      data.horaLlegadaCtrl.text = v.horaLlegada;
      data.costoCtrl.text = v.costo > 0 ? v.costo.toStringAsFixed(0) : '';
      data.numeroPasajerosCtrl.text = v.numeroPasajeros.toString();
      data.costoCtrl.addListener(_refreshResumen);
      data.origenCtrl.addListener(_refreshResumen);
      data.destinoCtrl.addListener(_refreshResumen);
      _vuelos.add(data);
    }

    for (final h in r.opcionesHotel) {
      final data = _HotelData()
        ..tipoHabitacion = h.tipoHabitacion
        ..queIncluye.addAll(h.queIncluye)
        ..fotos.addAll(h.fotos)
        ..fechaEntrada = h.fechaEntrada.isNotEmpty
            ? DateTime.tryParse(h.fechaEntrada)
            : null
        ..fechaSalida = h.fechaSalida.isNotEmpty
            ? DateTime.tryParse(h.fechaSalida)
            : null;
      data.nombreCtrl.text = h.nombre;
      data.precioAdultoCtrl.text = h.precioAdulto > 0
          ? h.precioAdulto.toStringAsFixed(0)
          : '';
      data.precioMenorCtrl.text = h.precioMenor > 0
          ? h.precioMenor.toStringAsFixed(0)
          : '';
      data.precioTotalCtrl.text = h.precioTotal > 0
          ? h.precioTotal.toStringAsFixed(0)
          : '';
      data.precioTotalCtrl.addListener(_refreshResumen);
      data.precioAdultoCtrl.addListener(_refreshResumen);
      data.nombreCtrl.addListener(_refreshResumen);
      _hoteles.add(data);
    }

    for (final a in r.adicionales) {
      final data = _AdicionalData();
      data.nombreCtrl.text = a.nombre;
      data.descripcionCtrl.text = a.descripcion;
      data.precioCtrl.text = a.precio > 0 ? a.precio.toStringAsFixed(0) : '';
      data.precioCtrl.addListener(_refreshResumen);
      data.nombreCtrl.addListener(_refreshResumen);
      _adicionales.add(data);
    }
  }

  Future<void> _loadAerolineas() async {
    setState(() => _loadingAerolineas = true);
    try {
      final list = await sl<ReservaRepository>().getAerolineas();
      if (mounted) setState(() => _aerolineas = list);
    } catch (_) {
      // silently ignore
    } finally {
      if (mounted) setState(() => _loadingAerolineas = false);
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _imagenUrlCtrl.dispose();
    _itemCtrl.dispose();
    _itemNoIncluidoCtrl.dispose();
    for (final v in _vuelos) {
      v.dispose();
    }
    for (final h in _hoteles) {
      h.dispose();
    }
    for (final a in _adicionales) {
      a.dispose();
    }
    _condicionesCtrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate({DateTime? initial}) => showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now().add(const Duration(days: 1)),
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
    builder: (context, child) => Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: SaasPalette.brand600,
          onPrimary: Colors.white,
          surface: SaasPalette.bgCanvas,
          onSurface: SaasPalette.textPrimary,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: SaasPalette.bgCanvas,
        ),
      ),
      child: child!,
    ),
  );

  Future<void> _openAerolineaPicker(_VueloData data) async {
    final result = await showDialog<Aerolinea>(
      context: context,
      builder: (_) => _AerolineaPickerDialog(aerolineas: _aerolineas),
    );
    if (result != null) {
      setState(() {
        data.aerolineaId = result.id;
        data.aerolinea = result;
      });
    }
  }

  void _addImagen() {
    final url = _imagenUrlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _imagenes.add(url);
      _imagenUrlCtrl.clear();
    });
  }

  void _addItem() {
    final item = _itemCtrl.text.trim();
    if (item.isEmpty) return;
    setState(() {
      _itemsIncluidos.add(item);
      _itemCtrl.clear();
    });
  }

  void _addVuelo() {
    final data = _VueloData();
    data.costoCtrl.addListener(_refreshResumen);
    data.numeroPasajerosCtrl.addListener(_refreshResumen);
    data.origenCtrl.addListener(_refreshResumen);
    data.destinoCtrl.addListener(_refreshResumen);
    setState(() => _vuelos.add(data));
  }

  void _refreshResumen() => setState(() {});

  void _removeVuelo(int i) {
    setState(() {
      _vuelos[i].dispose();
      _vuelos.removeAt(i);
    });
  }

  void _addHotel() {
    final data = _HotelData();
    data.precioTotalCtrl.addListener(_refreshResumen);
    data.precioAdultoCtrl.addListener(_refreshResumen);
    data.nombreCtrl.addListener(_refreshResumen);
    setState(() => _hoteles.add(data));
  }

  void _removeHotel(int i) {
    setState(() {
      _hoteles[i].dispose();
      _hoteles.removeAt(i);
    });
  }

  void _addAdicional() {
    final data = _AdicionalData();
    data.precioCtrl.addListener(_refreshResumen);
    data.nombreCtrl.addListener(_refreshResumen);
    setState(() => _adicionales.add(data));
  }

  void _removeAdicional(int i) {
    setState(() {
      _adicionales[i].dispose();
      _adicionales.removeAt(i);
    });
  }

  void _toggleIncluye(_HotelData hotel, String option) {
    setState(() {
      if (hotel.queIncluye.contains(option)) {
        hotel.queIncluye.remove(option);
      } else {
        hotel.queIncluye.add(option);
      }
    });
  }

  RespuestaCotizacion _buildCurrentRespuesta() {
    return RespuestaCotizacion(
      id: widget.respuesta?.id,
      cotizacionId: widget.respuesta?.cotizacionId ?? widget.cotizacion?.id,
      token: widget.respuesta?.token,
      tituloViaje: _tituloCtrl.text.trim(),
      imagenesDestino: List.from(_imagenes),
      itemsIncluidos: List.from(_itemsIncluidos),
      itemsNoIncluidos: List.from(_itemsNoIncluidos),
      vuelos: _vuelos
          .map(
            (v) => VueloItinerario(
              tipo: v.tipoVuelo,
              aerolineaId: v.aerolineaId,
              aerolinea: v.aerolinea?.nombre ?? '',
              numeroVuelo: v.numeroVueloCtrl.text.trim(),
              origen: v.origenCtrl.text.trim(),
              destino: v.destinoCtrl.text.trim(),
              fecha: v.fecha != null
                  ? DateFormat('yyyy-MM-dd').format(v.fecha!)
                  : '',
              horaSalida: v.horaSalidaCtrl.text.trim(),
              horaLlegada: v.horaLlegadaCtrl.text.trim(),
              costo: double.tryParse(v.costoCtrl.text.trim()) ?? 0,
              numeroPasajeros:
                  int.tryParse(v.numeroPasajerosCtrl.text.trim()) ?? 1,
            ),
          )
          .toList(),
      opcionesHotel: _hoteles
          .map(
            (h) => OpcionHotel(
              nombre: h.nombreCtrl.text.trim(),
              tipoHabitacion: h.tipoHabitacion,
              queIncluye: List.from(h.queIncluye),
              fechaEntrada: h.fechaEntrada != null
                  ? DateFormat('yyyy-MM-dd').format(h.fechaEntrada!)
                  : '',
              fechaSalida: h.fechaSalida != null
                  ? DateFormat('yyyy-MM-dd').format(h.fechaSalida!)
                  : '',
              precioAdulto:
                  double.tryParse(h.precioAdultoCtrl.text.trim()) ?? 0,
              precioMenor: double.tryParse(h.precioMenorCtrl.text.trim()) ?? 0,
              precioTotal: double.tryParse(h.precioTotalCtrl.text.trim()) ?? 0,
              fotos: List.from(h.fotos),
            ),
          )
          .toList(),
      adicionales: _adicionales
          .map(
            (a) => AdicionalViaje(
              nombre: a.nombreCtrl.text.trim(),
              descripcion: a.descripcionCtrl.text.trim(),
              precio: double.tryParse(a.precioCtrl.text.trim()) ?? 0,
            ),
          )
          .toList(),
      condicionesGenerales: _condicionesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );
  }

  void _openPreview() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _PropuestaPreviewDialog(
        respuesta: _buildCurrentRespuesta(),
        cotizacion: widget.cotizacion ?? _loadedCotizacion,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    //validaciones
    //validamos el titulo no puede estar vacio
    if (_tituloCtrl.text.trim().isEmpty) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(context, 'El titulo es requerido');
      return;
    }

    //validamos que haya al menos una imagen
    if (_imagenes.isEmpty) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(context, 'La imagen principal es requerida');
      return;
    }
    //validamos si hay un hotel agregado debe tener como minimo, nombre, fecha entrada, fecha salida y precio total
    if (_hoteles.any((h) => h.nombreCtrl.text.trim().isEmpty)) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(context, 'El nombre del hotel es requerido');
      return;
    }
    if (_hoteles.any((h) => h.fechaEntrada == null)) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(
        context,
        'La fecha de entrada del hotel es requerida',
      );
      return;
    }
    if (_hoteles.any((h) => h.fechaSalida == null)) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(
        context,
        'La fecha de salida del hotel es requerida',
      );
      return;
    }
    if (_hoteles.any((h) => h.precioTotalCtrl.text.trim().isEmpty)) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(
        context,
        'El precio total del hotel es requerido',
      );
      return;
    }
    //validamos si hay un vuelo agregado debe tener como minimo, origen, destino, fecha, aerolinea, costo, numero de pasajeros
    if (_vuelos.any((v) => v.origenCtrl.text.trim().isEmpty)) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(context, 'El origen del vuelo es requerido');
      return;
    }
    if (_vuelos.any((v) => v.destinoCtrl.text.trim().isEmpty)) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(context, 'El destino del vuelo es requerido');
      return;
    }
    if (_vuelos.any((v) => v.fecha == null)) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(context, 'La fecha del vuelo es requerida');
      return;
    }
    if (_vuelos.any((v) => v.aerolineaId == null)) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(context, 'La aerolinea del vuelo es requerida');
      return;
    }
    if (_vuelos.any((v) => v.costoCtrl.text.trim().isEmpty)) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(context, 'El costo del vuelo es requerido');
      return;
    }
    if (_vuelos.any((v) => v.numeroPasajerosCtrl.text.trim().isEmpty)) {
      setState(() => _saving = false);
      SaasSnackBar.showWarning(
        context,
        'El numero de pasajeros del vuelo es requerido',
      );
      return;
    }

    final respuesta = RespuestaCotizacion(
      id: widget.respuesta?.id,
      cotizacionId: widget.respuesta?.cotizacionId ?? widget.cotizacion?.id,
      token: widget.respuesta?.token,
      tituloViaje: _tituloCtrl.text.trim(),
      imagenesDestino: List.from(_imagenes),
      itemsIncluidos: List.from(_itemsIncluidos),
      itemsNoIncluidos: List.from(_itemsNoIncluidos),
      vuelos: _vuelos.map((v) {
        return VueloItinerario(
          tipo: v.tipoVuelo,
          aerolineaId: v.aerolineaId,
          aerolinea: v.aerolinea?.nombre ?? '',
          numeroVuelo: v.numeroVueloCtrl.text.trim(),
          origen: v.origenCtrl.text.trim(),
          destino: v.destinoCtrl.text.trim(),
          fecha: v.fecha != null
              ? DateFormat('yyyy-MM-dd').format(v.fecha!)
              : '',
          horaSalida: v.horaSalidaCtrl.text.trim(),
          horaLlegada: v.horaLlegadaCtrl.text.trim(),
          costo: double.tryParse(v.costoCtrl.text.trim()) ?? 0,
          numeroPasajeros: int.tryParse(v.numeroPasajerosCtrl.text.trim()) ?? 1,
        );
      }).toList(),
      opcionesHotel: _hoteles.map((h) {
        return OpcionHotel(
          nombre: h.nombreCtrl.text.trim(),
          tipoHabitacion: h.tipoHabitacion,
          queIncluye: List.from(h.queIncluye),
          fechaEntrada: h.fechaEntrada != null
              ? DateFormat('yyyy-MM-dd').format(h.fechaEntrada!)
              : '',
          fechaSalida: h.fechaSalida != null
              ? DateFormat('yyyy-MM-dd').format(h.fechaSalida!)
              : '',
          precioAdulto: double.tryParse(h.precioAdultoCtrl.text.trim()) ?? 0,
          precioMenor: double.tryParse(h.precioMenorCtrl.text.trim()) ?? 0,
          precioTotal: double.tryParse(h.precioTotalCtrl.text.trim()) ?? 0,
          fotos: List.from(h.fotos),
        );
      }).toList(),
      adicionales: _adicionales.map((a) {
        return AdicionalViaje(
          nombre: a.nombreCtrl.text.trim(),
          descripcion: a.descripcionCtrl.text.trim(),
          precio: double.tryParse(a.precioCtrl.text.trim()) ?? 0,
        );
      }).toList(),
      condicionesGenerales: _condicionesCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      final repo = sl<RespuestaCotizacionRepository>();
      if (widget.respuesta != null) {
        await repo.updateRespuesta(respuesta);
      } else {
        await repo.createRespuesta(respuesta);
      }
      if (!mounted) return;

      SaasSnackBar.showSuccess(
        context,
        widget.respuesta != null
            ? 'Respuesta actualizada exitosamente'
            : 'Respuesta guardada exitosamente',
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      SaasSnackBar.showError(
        context,
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            PremiumSliverAppBar(
              title: widget.respuesta != null
                  ? 'Editar Propuesta'
                  : widget.cotizacion != null
                  ? 'Responder Cotización'
                  : 'Nueva Propuesta de Viaje',
              actions: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 60),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (widget.cotizacion != null ||
                      _loadedCotizacion != null) ...[
                    _CotizacionBanner(
                      cotizacion: widget.cotizacion ?? _loadedCotizacion!,
                    ),
                    const SizedBox(height: 20),
                  ] else if (_loadingCotizacion) ...[
                    const SaasBannerSkeleton(),
                    const SizedBox(height: 20),
                  ],
                  _buildDatosGenerales(),
                  const SizedBox(height: 20),
                  _buildImagenesSection(),
                  const SizedBox(height: 20),
                  _buildItemsIncluidosSection(),
                  const SizedBox(height: 20),
                  _buildItemsNoIncluidosSection(),
                  const SizedBox(height: 20),
                  _buildVuelosSection(),
                  const SizedBox(height: 20),
                  _buildHotelesSection(),
                  const SizedBox(height: 20),
                  _buildAdicionalesSection(),
                  const SizedBox(height: 20),
                  _buildCondicionesGeneralesSection(),
                  const SizedBox(height: 20),
                  _buildResumenCostos(),
                  if (widget.respuesta?.token != null) ...[
                    const SizedBox(height: 20),
                    _buildLinkCard(widget.respuesta!.token!),
                  ],
                  const SizedBox(height: 32),
                  PremiumActionButton(
                    label: widget.respuesta != null
                        ? 'ACTUALIZAR PROPUESTA'
                        : 'GUARDAR RESPUESTA',
                    icon: Icons.save_rounded,
                    isLoading: _saving,
                    onTap: _save,
                  ),
                  const SizedBox(height: 12),

                  // Botón vista previa en vivo
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Datos generales ───────────────────────────────────────────────────────
  Widget _buildDatosGenerales() {
    return PremiumSectionCard(
      title: 'DATOS GENERALES',
      icon: Icons.travel_explore_rounded,
      children: [
        PremiumTextField(
          controller: _tituloCtrl,
          label: 'Título del viaje *',
          icon: Icons.title_rounded,
        ),
      ],
    );
  }

  // ── Imágenes ──────────────────────────────────────────────────────────────
  Widget _buildImagenesSection() {
    return PremiumSectionCard(
      title: 'IMÁGENES DEL DESTINO',
      icon: Icons.photo_library_rounded,
      children: [
        if (_imagenes.isNotEmpty) ...[
          // Imagen principal activa
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _imagenes[_activeImageIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, e) => Container(
                      color: SaasPalette.bgSubtle,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: SaasPalette.textTertiary,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '\${_activeImageIndex + 1} / \${_imagenes.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Thumbnails — todos visibles en fila horizontal
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _imagenes.length,
              separatorBuilder: (_, i) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final isActive = i == _activeImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _activeImageIndex = i),
                  child: Stack(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive
                                ? SaasPalette.brand600
                                : SaasPalette.border,
                            width: isActive ? 2.5 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(7),
                          child: Image.network(
                            _imagenes[i],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, e) => Container(
                              color: SaasPalette.bgSubtle,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: SaasPalette.textTertiary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Botón eliminar
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _imagenes.removeAt(i);
                            if (_activeImageIndex >= _imagenes.length &&
                                _imagenes.isNotEmpty) {
                              _activeImageIndex = _imagenes.length - 1;
                            }
                          }),
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: SaasPalette.danger,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: SaasPalette.border, height: 1),
          const SizedBox(height: 14),
        ],
        // Input URL
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PremiumTextField(
                controller: _imagenUrlCtrl,
                label: 'URL de imagen',
                icon: Icons.link_rounded,
                validator: (_) => null,
              ),
            ),
            const SizedBox(width: 12),
            _AddButton(label: 'Agregar', onTap: _addImagen),
          ],
        ),
        if (_imagenes.isEmpty) ...[
          const SizedBox(height: 12),
          const PremiumEmptyIndicator(
            msg:
                'Agrega URLs de imágenes para construir la galería del destino.',
            icon: Icons.photo_outlined,
          ),
        ],
      ],
    );
  }

  // ── Qué incluye ───────────────────────────────────────────────────────────
  Widget _buildItemsIncluidosSection() {
    return PremiumSectionCard(
      title: '¿QUÉ INCLUYE EL PAQUETE?',
      icon: Icons.checklist_rounded,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PremiumTextField(
                controller: _itemCtrl,
                label: 'Ítem incluido (ej: Tiquetes aéreos, traslados)',
                icon: Icons.add_task_rounded,
                validator: (_) => null,
              ),
            ),
            const SizedBox(width: 12),
            _AddButton(label: 'Agregar', onTap: _addItem),
          ],
        ),
        if (_itemsIncluidos.isNotEmpty) ...[
          const SizedBox(height: 14),
          Column(
            children: _itemsIncluidos.asMap().entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: SaasPalette.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: SaasPalette.success.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: SaasPalette.success,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _itemsIncluidos.removeAt(e.key)),
                      child: const Icon(
                        Icons.close_rounded,
                        color: SaasPalette.textTertiary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ] else ...[
          const SizedBox(height: 12),
          const PremiumEmptyIndicator(
            msg: 'Sin ítems aún. Agrega lo que incluye el paquete.',
            icon: Icons.list_alt_rounded,
          ),
        ],
      ],
    );
  }

  // ── Qué NO incluye ────────────────────────────────────────────────────────
  Widget _buildItemsNoIncluidosSection() {
    return PremiumSectionCard(
      title: '¿QUÉ NO INCLUYE?',
      icon: Icons.remove_circle_outline_rounded,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: PremiumTextField(
                controller: _itemNoIncluidoCtrl,
                label: 'Ítem NO incluido (ej: Gastos personales, propinas)',
                icon: Icons.block_rounded,
                validator: (_) => null,
              ),
            ),
            const SizedBox(width: 12),
            _AddButton(
              label: 'Agregar',
              onTap: () {
                final item = _itemNoIncluidoCtrl.text.trim();
                if (item.isEmpty) return;
                setState(() {
                  _itemsNoIncluidos.add(item);
                  _itemNoIncluidoCtrl.clear();
                });
              },
            ),
          ],
        ),
        if (_itemsNoIncluidos.isNotEmpty) ...[
          const SizedBox(height: 14),
          Column(
            children: _itemsNoIncluidos.asMap().entries.map((e) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: SaasPalette.danger.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: SaasPalette.danger.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cancel_rounded,
                      color: SaasPalette.danger,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.value,
                        style: const TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _itemsNoIncluidos.removeAt(e.key)),
                      child: const Icon(
                        Icons.close_rounded,
                        color: SaasPalette.textTertiary,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ] else ...[
          const SizedBox(height: 12),
          const PremiumEmptyIndicator(
            msg: 'Sin ítems aún. Agrega lo que NO incluye el paquete.',
            icon: Icons.block_outlined,
          ),
        ],
      ],
    );
  }

  // ── Vuelos ────────────────────────────────────────────────────────────────
  Widget _buildVuelosSection() {
    return PremiumSectionCard(
      title: 'ITINERARIO DE VUELO',
      icon: Icons.flight_rounded,
      children: [
        if (_vuelos.isEmpty)
          const PremiumEmptyIndicator(
            msg: 'Sin vuelos. Agrega tramos del itinerario.',
            icon: Icons.flight_outlined,
          ),
        ..._vuelos.asMap().entries.map((e) => _buildVueloCard(e.key, e.value)),
        const SizedBox(height: 8),
        _OutlineAddButton(
          label: 'Agregar Vuelo',
          icon: Icons.add_rounded,
          onTap: _addVuelo,
        ),
      ],
    );
  }

  Widget _buildVueloCard(int index, _VueloData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionBadge(
                label: 'Vuelo ${index + 1}',
                color: SaasPalette.brand600,
                icon: Icons.flight_rounded,
              ),
              const SizedBox(width: 10),
              _TipoVueloToggle(
                value: data.tipoVuelo,
                onChanged: (v) => setState(() => data.tipoVuelo = v),
              ),
              const Spacer(),
              _RemoveButton(onTap: () => _removeVuelo(index)),
            ],
          ),
          const SizedBox(height: 14),

          // Aerolínea picker
          const _FieldLabel(label: 'Aerolínea *'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _loadingAerolineas ? null : () => _openAerolineaPicker(data),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: SaasPalette.bgCanvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SaasPalette.border),
              ),
              child: Row(
                children: [
                  if (data.aerolinea != null) ...[
                    _AerolineaLogo(aerolinea: data.aerolinea!, size: 30),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.aerolinea!.nombre,
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _loadingAerolineas
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

          PremiumTextField(
            controller: data.numeroVueloCtrl,
            label: 'No. de Vuelo',
            icon: Icons.confirmation_number_rounded,
            validator: (_) => null,
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 500;
              return wide
                  ? Row(
                      children: [
                        Expanded(
                          child: PremiumTextField(
                            controller: data.origenCtrl,
                            label: 'Ciudad de Origen *',
                            icon: Icons.flight_takeoff_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: PremiumTextField(
                            controller: data.destinoCtrl,
                            label: 'Ciudad de Destino *',
                            icon: Icons.flight_land_rounded,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        PremiumTextField(
                          controller: data.origenCtrl,
                          label: 'Ciudad de Origen *',
                          icon: Icons.flight_takeoff_rounded,
                        ),
                        const SizedBox(height: 12),
                        PremiumTextField(
                          controller: data.destinoCtrl,
                          label: 'Ciudad de Destino *',
                          icon: Icons.flight_land_rounded,
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 500;
              final dateField = _PickerField(
                label: 'Fecha del Vuelo',
                value: data.fecha != null ? _dateFmt.format(data.fecha!) : null,
                icon: Icons.calendar_today_rounded,
                hint: 'Seleccionar fecha',
                onTap: () async {
                  final d = await _pickDate(initial: data.fecha);
                  if (d != null) setState(() => data.fecha = d);
                },
              );
              final salidaField = PremiumTextField(
                controller: data.horaSalidaCtrl,
                label: 'Hora Salida (ej. 08:30)',
                icon: Icons.schedule_rounded,
                validator: (_) => null,
              );
              final llegadaField = PremiumTextField(
                controller: data.horaLlegadaCtrl,
                label: 'Hora Llegada (ej. 14:15)',
                icon: Icons.schedule_rounded,
                validator: (_) => null,
              );
              return wide
                  ? Row(
                      children: [
                        Expanded(child: dateField),
                        const SizedBox(width: 12),
                        Expanded(child: salidaField),
                        const SizedBox(width: 12),
                        Expanded(child: llegadaField),
                      ],
                    )
                  : Column(
                      children: [
                        dateField,
                        const SizedBox(height: 12),
                        salidaField,
                        const SizedBox(height: 12),
                        llegadaField,
                      ],
                    );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 400;
              final costoField = PremiumTextField(
                controller: data.costoCtrl,
                label: 'Costo del vuelo',
                icon: Icons.attach_money_rounded,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (_) => null,
              );
              final pasajerosField = PremiumTextField(
                controller: data.numeroPasajerosCtrl,
                label: 'Cant. pasajeros',
                icon: Icons.people_alt_rounded,
                keyboardType: TextInputType.number,
                validator: (_) => null,
              );
              return wide
                  ? Row(
                      children: [
                        Expanded(child: costoField),
                        const SizedBox(width: 12),
                        SizedBox(width: 160, child: pasajerosField),
                      ],
                    )
                  : Column(
                      children: [
                        costoField,
                        const SizedBox(height: 12),
                        pasajerosField,
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  // ── Hoteles ───────────────────────────────────────────────────────────────
  Widget _buildHotelesSection() {
    return PremiumSectionCard(
      title: 'OPCIONES DE HOTEL',
      icon: Icons.hotel_rounded,
      children: [
        if (_hoteles.isEmpty)
          const PremiumEmptyIndicator(
            msg: 'Sin opciones. El cliente elegirá entre las que agregues.',
            icon: Icons.bed_outlined,
          ),
        ..._hoteles.asMap().entries.map((e) => _buildHotelCard(e.key, e.value)),
        const SizedBox(height: 8),
        _OutlineAddButton(
          label: 'Agregar Opción de Hotel',
          icon: Icons.add_rounded,
          onTap: _addHotel,
        ),
      ],
    );
  }

  Widget _buildHotelCard(int index, _HotelData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Galería fotos del hotel (preview de la activa)
          if (data.fotos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      data.fotos[data.activeFotoIndex],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, e) => Container(
                        color: SaasPalette.bgSubtle,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: SaasPalette.textTertiary,
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${data.activeFotoIndex + 1} / ${data.fotos.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _SectionBadge(
                      label: 'Opción ${index + 1}',
                      color: SaasPalette.warning,
                      icon: Icons.hotel_rounded,
                    ),
                    const Spacer(),
                    _RemoveButton(onTap: () => _removeHotel(index)),
                  ],
                ),
                const SizedBox(height: 14),

                PremiumTextField(
                  controller: data.nombreCtrl,
                  label: 'Nombre del Hotel *',
                  icon: Icons.hotel_rounded,
                ),
                const SizedBox(height: 12),

                _DropdownField(
                  label: 'Tipo de Habitación',
                  value: data.tipoHabitacion,
                  options: _tipoHabitacionOpciones,
                  icon: Icons.bed_rounded,
                  onChanged: (v) => setState(
                    () => data.tipoHabitacion = v ?? data.tipoHabitacion,
                  ),
                ),
                const SizedBox(height: 14),

                // Qué incluye — multi-select chips
                const _FieldLabel(label: 'Qué Incluye'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _incluyeOpciones.map((option) {
                    final sel = data.queIncluye.contains(option);
                    return GestureDetector(
                      onTap: () => _toggleIncluye(data, option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? SaasPalette.brand600
                              : SaasPalette.bgSubtle,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: sel
                                ? SaasPalette.brand600
                                : SaasPalette.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (sel) ...[
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              option,
                              style: TextStyle(
                                color: sel
                                    ? Colors.white
                                    : SaasPalette.textSecondary,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (data.queIncluye.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${data.queIncluye.length} seleccionado(s)',
                    style: const TextStyle(
                      color: SaasPalette.brand600,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Fechas
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final wide = constraints.maxWidth > 500;
                    final entrada = _PickerField(
                      label: 'Fecha de Entrada',
                      value: data.fechaEntrada != null
                          ? _dateFmt.format(data.fechaEntrada!)
                          : null,
                      icon: Icons.login_rounded,
                      hint: 'Seleccionar fecha',
                      onTap: () async {
                        final d = await _pickDate(initial: data.fechaEntrada);
                        if (d != null) setState(() => data.fechaEntrada = d);
                      },
                    );
                    final salida = _PickerField(
                      label: 'Fecha de Salida',
                      value: data.fechaSalida != null
                          ? _dateFmt.format(data.fechaSalida!)
                          : null,
                      icon: Icons.logout_rounded,
                      hint: 'Seleccionar fecha',
                      onTap: () async {
                        final d = await _pickDate(initial: data.fechaSalida);
                        if (d != null) setState(() => data.fechaSalida = d);
                      },
                    );
                    return wide
                        ? Row(
                            children: [
                              Expanded(child: entrada),
                              const SizedBox(width: 12),
                              Expanded(child: salida),
                            ],
                          )
                        : Column(
                            children: [
                              entrada,
                              const SizedBox(height: 12),
                              salida,
                            ],
                          );
                  },
                ),
                const SizedBox(height: 12),

                // Precios
                LayoutBuilder(
                  builder: (ctx, constraints) {
                    final wide = constraints.maxWidth > 500;
                    return wide
                        ? Row(
                            children: [
                              Expanded(
                                child: PremiumTextField(
                                  controller: data.precioAdultoCtrl,
                                  label: 'Precio por Adulto *',
                                  icon: Icons.person_rounded,
                                  isNumeric: true,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PremiumTextField(
                                  controller: data.precioMenorCtrl,
                                  label: 'Precio por Menor',
                                  isNumeric: true,
                                  icon: Icons.child_care_rounded,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (_) => null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PremiumTextField(
                                  controller: data.precioTotalCtrl,
                                  label: 'Precio Total',
                                  isNumeric: true,
                                  icon: Icons.attach_money_rounded,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  validator: (_) => null,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              PremiumTextField(
                                controller: data.precioAdultoCtrl,
                                label: 'Precio por Adulto *',
                                isNumeric: true,
                                icon: Icons.person_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                              ),
                              const SizedBox(height: 12),
                              PremiumTextField(
                                controller: data.precioMenorCtrl,
                                label: 'Precio por Menor',
                                isNumeric: true,
                                icon: Icons.child_care_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (_) => null,
                              ),
                              const SizedBox(height: 12),
                              PremiumTextField(
                                controller: data.precioTotalCtrl,
                                label: 'Precio Total',
                                isNumeric: true,
                                icon: Icons.attach_money_rounded,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (_) => null,
                              ),
                            ],
                          );
                  },
                ),
                const SizedBox(height: 12),

                // Fotos del hotel — galería multi-imagen
                const _FieldLabel(label: 'Fotos del Hotel'),
                const SizedBox(height: 8),
                if (data.fotos.isNotEmpty) ...[
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.fotos.length,
                      separatorBuilder: (_, i) => const SizedBox(width: 6),
                      itemBuilder: (context, i) {
                        final isActive = i == data.activeFotoIndex;
                        return GestureDetector(
                          onTap: () => setState(() => data.activeFotoIndex = i),
                          child: Stack(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: isActive
                                        ? SaasPalette.warning
                                        : SaasPalette.border,
                                    width: isActive ? 2.5 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    data.fotos[i],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, e) =>
                                        Container(
                                          color: SaasPalette.bgSubtle,
                                          child: const Icon(
                                            Icons.broken_image_rounded,
                                            color: SaasPalette.textTertiary,
                                            size: 18,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 1,
                                right: 1,
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    data.fotos.removeAt(i);
                                    if (data.activeFotoIndex >=
                                            data.fotos.length &&
                                        data.fotos.isNotEmpty) {
                                      data.activeFotoIndex =
                                          data.fotos.length - 1;
                                    }
                                  }),
                                  child: Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      color: SaasPalette.danger,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 9,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: PremiumTextField(
                        controller: data.fotoUrlCtrl,
                        label: 'URL de foto',
                        icon: Icons.link_rounded,
                        validator: (_) => null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _AddButton(
                      label: 'Agregar',
                      onTap: () {
                        final url = data.fotoUrlCtrl.text.trim();
                        if (url.isEmpty) return;
                        setState(() {
                          data.fotos.add(url);
                          data.fotoUrlCtrl.clear();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Adicionales ───────────────────────────────────────────────────────────
  Widget _buildAdicionalesSection() {
    return PremiumSectionCard(
      title: 'ADICIONALES',
      icon: Icons.add_circle_outline_rounded,
      children: [
        if (_adicionales.isEmpty)
          const PremiumEmptyIndicator(
            msg:
                'Sin adicionales. Agrega servicios o ítems extras con su precio.',
            icon: Icons.playlist_add_rounded,
          ),
        ..._adicionales.asMap().entries.map(
          (e) => _buildAdicionalCard(e.key, e.value),
        ),
        const SizedBox(height: 8),
        _OutlineAddButton(
          label: 'Agregar Adicional',
          icon: Icons.add_rounded,
          onTap: _addAdicional,
        ),
      ],
    );
  }

  Widget _buildAdicionalCard(int index, _AdicionalData data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SectionBadge(
                label: 'Adicional ${index + 1}',
                color: const Color(0xFF7C3AED),
                icon: Icons.extension_rounded,
              ),
              const Spacer(),
              _RemoveButton(onTap: () => _removeAdicional(index)),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (ctx, constraints) {
              final wide = constraints.maxWidth > 500;
              return wide
                  ? Row(
                      children: [
                        Expanded(
                          child: PremiumTextField(
                            controller: data.nombreCtrl,
                            label: 'Nombre *',
                            icon: Icons.label_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 180,
                          child: PremiumTextField(
                            controller: data.precioCtrl,
                            label: 'Precio *',
                            isNumeric: true,
                            icon: Icons.attach_money_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        PremiumTextField(
                          controller: data.nombreCtrl,
                          label: 'Nombre *',
                          icon: Icons.label_rounded,
                        ),
                        const SizedBox(height: 12),
                        PremiumTextField(
                          controller: data.precioCtrl,
                          label: 'Precio *',
                          isNumeric: true,
                          icon: Icons.attach_money_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 12),
          PremiumTextField(
            controller: data.descripcionCtrl,
            label: 'Descripción',
            icon: Icons.notes_rounded,
            maxLines: 2,
            validator: (_) => null,
          ),
        ],
      ),
    );
  }

  // ── Condiciones generales ─────────────────────────────────────────────────
  Widget _buildCondicionesGeneralesSection() {
    return PremiumSectionCard(
      title: 'CONDICIONES GENERALES',
      icon: Icons.gavel_rounded,
      children: [
        PremiumTextField(
          controller: _condicionesCtrl,
          label: 'Condiciones y términos del paquete',
          icon: Icons.article_rounded,
          maxLines: 6,
          validator: (_) => null,
        ),
      ],
    );
  }

  // ── Resumen de costos ─────────────────────────────────────────────────────
  Widget _buildResumenCostos() {
    final priceFmt = NumberFormat('#,##0', 'es_CO');

    // Filas de vuelos con costo
    final vueloRows = _vuelos
        .where((v) {
          final costo = double.tryParse(v.costoCtrl.text.trim()) ?? 0;
          return costo > 0;
        })
        .map((v) {
          final costo = double.tryParse(v.costoCtrl.text.trim()) ?? 0;
          final pax = int.tryParse(v.numeroPasajerosCtrl.text.trim()) ?? 1;
          final origen = v.origenCtrl.text.trim();
          final destino = v.destinoCtrl.text.trim();
          final label = origen.isNotEmpty && destino.isNotEmpty
              ? '$origen → $destino'
              : origen.isNotEmpty
              ? origen
              : 'Vuelo ${_vuelos.indexOf(v) + 1}';
          return _ResumenFila(
            icono: Icons.flight_rounded,
            color: const Color(0xFF2563EB),
            label: label,
            sublabel: '$pax pax · ${v.tipoVuelo == 'ida' ? 'Ida' : 'Vuelta'}',
            valor: costo,
          );
        })
        .toList();

    // Filas de hoteles con costo
    final hotelRows = _hoteles
        .where((h) {
          final total = double.tryParse(h.precioTotalCtrl.text.trim()) ?? 0;
          final adulto = double.tryParse(h.precioAdultoCtrl.text.trim()) ?? 0;
          return total > 0 || adulto > 0;
        })
        .map((h) {
          final total = double.tryParse(h.precioTotalCtrl.text.trim()) ?? 0;
          final adulto = double.tryParse(h.precioAdultoCtrl.text.trim()) ?? 0;
          final valor = total > 0 ? total : adulto;
          final nombre = h.nombreCtrl.text.trim();
          return _ResumenFila(
            icono: Icons.hotel_rounded,
            color: const Color(0xFFF59E0B),
            label: nombre.isNotEmpty
                ? nombre
                : 'Hotel ${_hoteles.indexOf(h) + 1}',
            sublabel: h.tipoHabitacion,
            valor: valor,
          );
        })
        .toList();

    // Filas de adicionales con precio
    final adicionalRows = _adicionales
        .where((a) {
          final precio = double.tryParse(a.precioCtrl.text.trim()) ?? 0;
          return precio > 0;
        })
        .map((a) {
          final precio = double.tryParse(a.precioCtrl.text.trim()) ?? 0;
          final nombre = a.nombreCtrl.text.trim();
          return _ResumenFila(
            icono: Icons.extension_rounded,
            color: const Color(0xFF7C3AED),
            label: nombre.isNotEmpty
                ? nombre
                : 'Adicional ${_adicionales.indexOf(a) + 1}',
            sublabel: null,
            valor: precio,
          );
        })
        .toList();

    final todasLasFilas = [...vueloRows, ...hotelRows, ...adicionalRows];
    final total = todasLasFilas.fold(0.0, (sum, f) => sum + f.valor);
    final hayDatos = todasLasFilas.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: SaasPalette.bgSubtle,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              border: const Border(
                bottom: BorderSide(color: SaasPalette.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: SaasPalette.brand600.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calculate_rounded,
                    color: SaasPalette.brand600,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'RESUMEN DE COSTOS',
                  style: TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ],
            ),
          ),

          if (!hayDatos)
            const Padding(
              padding: EdgeInsets.all(24),
              child: PremiumEmptyIndicator(
                msg:
                    'Agrega costos en vuelos, hoteles o adicionales para ver el resumen.',
                icon: Icons.receipt_long_outlined,
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Vuelos
                  if (vueloRows.isNotEmpty) ...[
                    _ResumenGrupoHeader(
                      label: 'Vuelos',
                      icon: Icons.flight_rounded,
                    ),
                    const SizedBox(height: 8),
                    ...vueloRows.map(
                      (f) => _ResumenFilaWidget(fila: f, priceFmt: priceFmt),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Hoteles
                  if (hotelRows.isNotEmpty) ...[
                    _ResumenGrupoHeader(
                      label: 'Hoteles',
                      icon: Icons.hotel_rounded,
                    ),
                    const SizedBox(height: 8),
                    ...hotelRows.map(
                      (f) => _ResumenFilaWidget(fila: f, priceFmt: priceFmt),
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Adicionales
                  if (adicionalRows.isNotEmpty) ...[
                    _ResumenGrupoHeader(
                      label: 'Adicionales',
                      icon: Icons.extension_rounded,
                    ),
                    const SizedBox(height: 8),
                    ...adicionalRows.map(
                      (f) => _ResumenFilaWidget(fila: f, priceFmt: priceFmt),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Total
                  const Divider(color: SaasPalette.border, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: SaasPalette.brand600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.receipt_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'COSTO TOTAL',
                          style: TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '\$ ${priceFmt.format(total)}',
                        style: const TextStyle(
                          color: SaasPalette.brand600,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Link para compartir ───────────────────────────────────────────────────
  Widget _buildLinkCard(String token) {
    final link = ApiConstants.propuestaUrl(token);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaasPalette.brand50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SaasPalette.brand600.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: SaasPalette.brand600.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.link_rounded,
                  color: SaasPalette.brand600,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'ENLACE PARA COMPARTIR',
                style: TextStyle(
                  color: SaasPalette.brand600,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: SaasPalette.bgCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SaasPalette.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    link,
                    style: const TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: link));

                    SaasSnackBar.showSuccess(
                      context,
                      'Enlace copiado al portapapeles',
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: SaasPalette.brand600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_rounded, color: Colors.white, size: 14),
                        SizedBox(width: 5),
                        Text(
                          'Copiar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () async {
              final uri = Uri.parse(link);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  color: SaasPalette.brand600,
                  size: 14,
                ),
                SizedBox(width: 5),
                Text(
                  'Abrir en navegador',
                  style: TextStyle(
                    color: SaasPalette.brand600,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Resumen de costos helpers ─────────────────────────────────────────────────

class _ResumenFila {
  final IconData icono;
  final Color color;
  final String label;
  final String? sublabel;
  final double valor;
  const _ResumenFila({
    required this.icono,
    required this.color,
    required this.label,
    required this.sublabel,
    required this.valor,
  });
}

class _ResumenGrupoHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _ResumenGrupoHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: SaasPalette.textTertiary),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: SaasPalette.textTertiary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _ResumenFilaWidget extends StatelessWidget {
  final _ResumenFila fila;
  final NumberFormat priceFmt;
  const _ResumenFilaWidget({required this.fila, required this.priceFmt});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: fila.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(fila.icono, color: fila.color, size: 13),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fila.label,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (fila.sublabel != null)
                  Text(
                    fila.sublabel!,
                    style: const TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '\$ ${priceFmt.format(fila.valor)}',
            style: const TextStyle(
              color: SaasPalette.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _CotizacionBanner extends StatelessWidget {
  final Cotizacion cotizacion;
  const _CotizacionBanner({required this.cotizacion});

  @override
  Widget build(BuildContext context) {
    final c = cotizacion;
    final fmt = DateFormat('dd MMM yyyy', 'es_CO');

    String? fmtDate(String? d) {
      if (d == null || d.isEmpty) return null;
      try {
        return fmt.format(DateTime.parse(d));
      } catch (_) {
        return d;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: SaasPalette.brand50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.brand600.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: SaasPalette.brand600.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: SaasPalette.brand600.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.request_quote_rounded,
                    color: SaasPalette.brand600,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'COTIZACIÓN A RESPONDER',
                  style: TextStyle(
                    color: SaasPalette.brand600,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRouter.cotizacionCreate,
                      arguments: c,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: SaasPalette.brand600,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: SaasPalette.brand600.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ver Original',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: SaasPalette.brand600.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SaasPalette.brand600),
                  ),
                  child: Text(
                    '#${c.id}',
                    style: const TextStyle(
                      color: SaasPalette.brand600,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre
                _BannerRow(
                  icon: Icons.person_rounded,
                  label: 'Cliente',
                  value: c.nombreCompleto,
                ),
                if (c.correoElectronico != null &&
                    c.correoElectronico!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _BannerRow(
                    icon: Icons.email_rounded,
                    label: 'Correo',
                    value: c.correoElectronico!,
                  ),
                ],
                const SizedBox(height: 10),
                _BannerRow(
                  icon: Icons.phone_android_rounded,
                  label: 'WhatsApp',
                  value: c.chatId,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: SaasPalette.border, height: 1),
                ),
                // Detalles plan
                _BannerRow(
                  icon: Icons.map_rounded,
                  label: 'Plan',
                  value: c.detallesPlan,
                  maxLines: 3,
                ),
                if ((c.origen != null && c.origen!.isNotEmpty) ||
                    (c.destino != null && c.destino!.isNotEmpty)) ...[
                  const SizedBox(height: 10),
                  _BannerRow(
                    icon: Icons.route_rounded,
                    label: 'Ruta',
                    value: [c.origen ?? '—', c.destino ?? '—'].join(' → '),
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: SaasPalette.border, height: 1),
                ),
                // Fechas y pasajeros en fila
                Row(
                  children: [
                    Expanded(
                      child: _BannerRow(
                        icon: Icons.flight_takeoff_rounded,
                        label: 'Salida',
                        value: fmtDate(c.fechaSalida) ?? '—',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _BannerRow(
                        icon: Icons.flight_land_rounded,
                        label: 'Regreso',
                        value: fmtDate(c.fechaRegreso) ?? '—',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _BannerRow(
                        icon: Icons.people_alt_rounded,
                        label: 'Pasajeros',
                        value: '${c.numeroPasajeros}',
                      ),
                    ),
                    if (c.edadesMenores != null &&
                        c.edadesMenores!.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: _BannerRow(
                          icon: Icons.child_care_rounded,
                          label: 'Edades menores',
                          value: c.edadesMenores!,
                        ),
                      ),
                    ],
                  ],
                ),
                if (c.especificaciones != null &&
                    c.especificaciones!.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: SaasPalette.border, height: 1),
                  ),
                  _BannerRow(
                    icon: Icons.notes_rounded,
                    label: 'Notas / Especificaciones',
                    value: c.especificaciones!,
                    maxLines: 4,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  const _BannerRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: SaasPalette.brand600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: SaasPalette.textTertiary,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: SaasPalette.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SectionBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _SectionBadge({
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(
        Icons.delete_outline_rounded,
        color: SaasPalette.danger,
        size: 20,
      ),
      tooltip: 'Eliminar',
      splashRadius: 18,
    );
  }
}

class _AddButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: SaasPalette.brand600,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: SaasPalette.brand600.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _OutlineAddButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _OutlineAddButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: SaasPalette.brand600.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: SaasPalette.brand600.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: SaasPalette.brand600, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: SaasPalette.brand600,
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

class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final IconData icon;
  final String hint;
  final VoidCallback onTap;

  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.hint = 'Seleccionar...',
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: SaasPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: SaasPalette.bgCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SaasPalette.border),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: hasValue
                      ? SaasPalette.brand600
                      : SaasPalette.textTertiary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasValue ? value! : hint,
                    style: TextStyle(
                      color: hasValue
                          ? SaasPalette.textPrimary
                          : SaasPalette.textTertiary,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: SaasPalette.textTertiary,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final IconData icon;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: value,
          style: const TextStyle(color: SaasPalette.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: SaasPalette.brand600, size: 18),
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
          items: options
              .map((o) => DropdownMenuItem(value: o, child: Text(o)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ── Aerolínea picker dialog ───────────────────────────────────────────────────

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
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.aerolineas
          .where(
            (a) =>
                a.nombre.toLowerCase().contains(q) ||
                a.codigoIata.toLowerCase().contains(q),
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
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.white.withValues(alpha: 0.97),
            constraints: const BoxConstraints(maxHeight: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: SaasPalette.border),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.business_rounded,
                        color: SaasPalette.brand600,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Seleccionar Aerolínea',
                          style: TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: SaasPalette.textTertiary,
                        ),
                        onPressed: () => Navigator.pop(context),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                ),
                // Search
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
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
                          itemBuilder: (context, i) {
                            final a = _filtered[i];
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
                                      color: SaasPalette.border,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
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
                                                fontWeight: FontWeight.w600,
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
                                            fontWeight: FontWeight.w700,
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

// ── Aerolínea logo ────────────────────────────────────────────────────────────

class _AerolineaLogo extends StatelessWidget {
  final Aerolinea aerolinea;
  final double size;
  const _AerolineaLogo({required this.aerolinea, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final inner = size - 12;
    final hasLogo = aerolinea.logoUrl != null && aerolinea.logoUrl!.isNotEmpty;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: SaasPalette.border),
      ),
      child: hasLogo
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: buildPlatformNetworkImage(
                aerolinea.logoUrl!,
                height: inner,
                fit: BoxFit.contain,
              ),
            )
          : _IataBadge(iata: aerolinea.codigoIata, size: inner),
    );
  }
}

class _TipoVueloToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TipoVueloToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SaasPalette.border),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn('ida', Icons.flight_takeoff_rounded, 'Ida'),
          _btn('vuelta', Icons.flight_land_rounded, 'Vuelta'),
        ],
      ),
    );
  }

  Widget _btn(String tipo, IconData icon, String label) {
    final sel = value == tipo;
    return GestureDetector(
      onTap: () => onChanged(tipo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? SaasPalette.brand600 : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: sel ? Colors.white : SaasPalette.textTertiary,
              size: 13,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: sel ? Colors.white : SaasPalette.textTertiary,
                fontSize: 11,
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Live preview dialog ───────────────────────────────────────────────────────

class _PropuestaPreviewDialog extends StatefulWidget {
  final RespuestaCotizacion respuesta;
  final Cotizacion? cotizacion;
  const _PropuestaPreviewDialog({required this.respuesta, this.cotizacion});

  @override
  State<_PropuestaPreviewDialog> createState() =>
      _PropuestaPreviewDialogState();
}

class _PropuestaPreviewDialogState extends State<_PropuestaPreviewDialog> {
  int _imgIndex = 0;
  static final _priceFmt = NumberFormat('#,##0', 'es_CO');
  static final _dateFmt = DateFormat('dd MMM yyyy', 'es_CO');

  String? _fmtDate(String? d) {
    if (d == null || d.isEmpty) return null;
    try {
      return _dateFmt.format(DateTime.parse(d));
    } catch (_) {
      return d;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.respuesta;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          color: const Color(0xFFF8FAFC),
          child: Column(
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.preview_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'VISTA PREVIA DE LA PROPUESTA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      splashRadius: 16,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (r.imagenesDestino.isNotEmpty) _buildHero(r),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (r.tituloViaje.isNotEmpty) ...[
                              Text(
                                r.tituloViaje,
                                style: const TextStyle(
                                  color: Color(0xFF1E3A5F),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                            if (widget.cotizacion != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Para: ${widget.cotizacion!.nombreCompleto}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (r.itemsIncluidos.isNotEmpty) ...[
                              _PreviewSectionTitle(
                                title: '¿QUÉ INCLUYE?',
                                icon: Icons.checklist_rounded,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: r.itemsIncluidos
                                    .map(
                                      (item) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF10B981),
                                              size: 13,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              item,
                                              style: const TextStyle(
                                                color: Color(0xFF065F46),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (r.itemsNoIncluidos.isNotEmpty) ...[
                              _PreviewSectionTitle(
                                title: '¿QUÉ NO INCLUYE?',
                                icon: Icons.remove_circle_outline_rounded,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: r.itemsNoIncluidos
                                    .map(
                                      (item) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFEF4444,
                                          ).withValues(alpha: 0.07),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: const Color(
                                              0xFFEF4444,
                                            ).withValues(alpha: 0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.cancel_rounded,
                                              color: Color(0xFFEF4444),
                                              size: 13,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              item,
                                              style: const TextStyle(
                                                color: Color(0xFF7F1D1D),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (r.vuelos.isNotEmpty) ...[
                              _PreviewSectionTitle(
                                title: 'ITINERARIO DE VUELO',
                                icon: Icons.flight_rounded,
                              ),
                              const SizedBox(height: 12),
                              ...r.vuelos.map(_buildVueloTile),
                              const SizedBox(height: 24),
                            ],
                            if (r.opcionesHotel.isNotEmpty) ...[
                              _PreviewSectionTitle(
                                title: 'OPCIONES DE HOTEL',
                                icon: Icons.hotel_rounded,
                              ),
                              const SizedBox(height: 12),
                              ...r.opcionesHotel.asMap().entries.map(
                                (e) => _buildHotelCard(e.key, e.value),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (r.adicionales.isNotEmpty) ...[
                              _PreviewSectionTitle(
                                title: 'SERVICIOS ADICIONALES',
                                icon: Icons.add_circle_outline_rounded,
                              ),
                              const SizedBox(height: 12),
                              ...r.adicionales.map(_buildAdicionalTile),
                              const SizedBox(height: 24),
                            ],
                            if (r.condicionesGenerales.isNotEmpty) ...[
                              _PreviewSectionTitle(
                                title: 'CONDICIONES GENERALES',
                                icon: Icons.gavel_rounded,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Text(
                                  r.condicionesGenerales,
                                  style: const TextStyle(
                                    color: Color(0xFF475569),
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                            if (r.tituloViaje.isEmpty &&
                                r.itemsIncluidos.isEmpty &&
                                r.vuelos.isEmpty &&
                                r.opcionesHotel.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 48,
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.edit_note_rounded,
                                        color: Colors.grey.shade300,
                                        size: 64,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Completa el formulario para\nver la vista previa',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHero(RespuestaCotizacion r) {
    return Stack(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: Image.network(
            r.imagenesDestino[_imgIndex],
            fit: BoxFit.cover,
            errorBuilder: (context, error, _) => Container(
              color: const Color(0xFF1E3A5F),
              child: const Center(
                child: Icon(
                  Icons.broken_image_rounded,
                  color: Colors.white30,
                  size: 48,
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0x99000000)],
              ),
            ),
          ),
        ),
        if (r.imagenesDestino.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: r.imagenesDestino.asMap().entries.map((e) {
                final active = e.key == _imgIndex;
                return GestureDetector(
                  onTap: () => setState(() => _imgIndex = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildVueloTile(VueloItinerario v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              v.tipo == 'ida'
                  ? Icons.flight_takeoff_rounded
                  : Icons.flight_land_rounded,
              color: const Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      v.origen.isNotEmpty ? v.origen : '—',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      v.destino.isNotEmpty ? v.destino : '—',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (v.aerolinea.isNotEmpty)
                      Text(
                        v.aerolinea,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    if (v.aerolinea.isNotEmpty && v.numeroVuelo.isNotEmpty)
                      Text(
                        ' · ${v.numeroVuelo}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    if (v.fecha.isNotEmpty) ...[
                      if (v.aerolinea.isNotEmpty)
                        const Text(
                          '  ·  ',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      Text(
                        _fmtDate(v.fecha) ?? v.fecha,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                if (v.horaSalida.isNotEmpty || v.horaLlegada.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${v.horaSalida.isNotEmpty ? v.horaSalida : '--:--'} → ${v.horaLlegada.isNotEmpty ? v.horaLlegada : '--:--'}',
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
                ],
                if (v.costo > 0 || v.numeroPasajeros > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (v.costo > 0) ...[
                        const Icon(
                          Icons.attach_money_rounded,
                          size: 13,
                          color: Color(0xFF10B981),
                        ),
                        Text(
                          _priceFmt.format(v.costo),
                          style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (v.numeroPasajeros > 0) ...[
                        const Icon(
                          Icons.people_alt_rounded,
                          size: 13,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${v.numeroPasajeros} pax',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: v.tipo == 'ida'
                  ? const Color(0xFF2563EB).withValues(alpha: 0.1)
                  : const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              v.tipo == 'ida' ? 'Ida' : 'Vuelta',
              style: TextStyle(
                color: v.tipo == 'ida'
                    ? const Color(0xFF2563EB)
                    : const Color(0xFF7C3AED),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(int index, OpcionHotel h) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (h.fotos.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: SizedBox(
                height: 140,
                width: double.infinity,
                child: Image.network(
                  h.fotos.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, _) => Container(
                    color: const Color(0xFFF1F5F9),
                    child: const Center(
                      child: Icon(
                        Icons.hotel_rounded,
                        color: Color(0xFFCBD5E1),
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        h.nombre.isNotEmpty ? h.nombre : 'Hotel ${index + 1}',
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        h.tipoHabitacion,
                        style: const TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (h.fechaEntrada.isNotEmpty || h.fechaSalida.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_fmtDate(h.fechaEntrada) ?? '—'} → ${_fmtDate(h.fechaSalida) ?? '—'}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
                if (h.queIncluye.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: h.queIncluye
                        .map(
                          (q) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              q,
                              style: const TextStyle(
                                color: Color(0xFF065F46),
                                fontSize: 11,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (h.precioAdulto > 0 || h.precioTotal > 0) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (h.precioAdulto > 0)
                        Expanded(
                          child: _PriceChip(
                            label: 'Por adulto',
                            price: h.precioAdulto,
                            fmt: _priceFmt,
                          ),
                        ),
                      if (h.precioMenor > 0) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PriceChip(
                            label: 'Por menor',
                            price: h.precioMenor,
                            fmt: _priceFmt,
                          ),
                        ),
                      ],
                      if (h.precioTotal > 0) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: _PriceChip(
                            label: 'Total',
                            price: h.precioTotal,
                            fmt: _priceFmt,
                            highlight: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdicionalTile(AdicionalViaje a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.extension_rounded,
              color: Color(0xFF7C3AED),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.nombre,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (a.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    a.descripcion,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (a.precio > 0)
            Text(
              '\$ ${_priceFmt.format(a.precio)}',
              style: const TextStyle(
                color: Color(0xFF1E3A5F),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}

class _PreviewSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _PreviewSectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A5F).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF1E3A5F), size: 15),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF1E3A5F),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
      ],
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final double price;
  final NumberFormat fmt;
  final bool highlight;
  const _PriceChip({
    required this.label,
    required this.price,
    required this.fmt,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF1E3A5F) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: highlight ? Colors.white70 : const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '\$ ${fmt.format(price)}',
            style: TextStyle(
              color: highlight ? Colors.white : const Color(0xFF1E3A5F),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
