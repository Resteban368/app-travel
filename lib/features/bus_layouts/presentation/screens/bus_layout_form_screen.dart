import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/bus_layout.dart';
import '../../domain/repositories/bus_layout_repository.dart';
import '../bloc/bus_layout_bloc.dart';
import '../bloc/bus_layout_event.dart';
import '../bloc/bus_layout_state.dart';

enum _PaintMode { normal, bano, vacio, conductor, entrada }

enum _ColumnaConfig {
  unoMasUno, // 1+1 → 2 asientos/fila (minibus)
  dosMasUno, // 2+1 → 3 asientos/fila (ejecutivo)
  dosMasDos, // 2+2 → 4 asientos/fila (estándar)
  tresMasUno, // 3+1 → 4 asientos/fila (especial)
  tresMasDos, // 3+2 → 5 asientos/fila (económico)
}

class BusLayoutFormScreen extends StatefulWidget {
  final BusLayout? layout;
  const BusLayoutFormScreen({super.key, this.layout});

  @override
  State<BusLayoutFormScreen> createState() => _BusLayoutFormScreenState();
}

class _BusLayoutFormScreenState extends State<BusLayoutFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;

  // Configuración del layout
  int _filasPassajeros = 11;
  _ColumnaConfig _columnaConfig = _ColumnaConfig.dosMasDos;
  Set<String> _banoSeatNumbers = {};
  Set<String> _vazioSeatNumbers = {};
  Set<String> _entradaSeatNumbers = {};
  String? _conductorSeatNumber; // solo uno
  _PaintMode _paintMode = _PaintMode.bano;

  List<BusTourHistorialItem> _historial = [];
  bool _loadingHistorial = false;
  String? _historialError;

  late final AnimationController _entryCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isEditing => widget.layout != null;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.layout?.nombre ?? '');
    _descripcionCtrl = TextEditingController(
      text: widget.layout?.descripcion ?? '',
    );

    if (_isEditing && widget.layout?.configuracion != null) {
      _inferirConfiguracion(widget.layout!.configuracion!);
    }

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistorial());
    }

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  Future<void> _loadHistorial() async {
    if (!mounted || widget.layout?.id == null) return;
    setState(() { _loadingHistorial = true; _historialError = null; });
    try {
      final items = await sl<BusLayoutRepository>().getHistorial(widget.layout!.id!);
      if (mounted) setState(() => _historial = items);
    } catch (e) {
      if (mounted) setState(() => _historialError = e.toString());
    } finally {
      if (mounted) setState(() => _loadingHistorial = false);
    }
  }

  void _inferirConfiguracion(BusConfiguracion cfg) {
    final filasPasajero = cfg.asientos
        .where((a) => a.fila > 0 && a.tipo != TipoAsiento.vacio)
        .map((a) => a.fila)
        .toSet();
    _filasPassajeros = filasPasajero.isNotEmpty ? filasPasajero.length : 11;

    if (cfg.columnas == 3) {
      _columnaConfig = _ColumnaConfig.unoMasUno;
    } else if (cfg.columnas == 4) {
      // 2+1 (aisle at 2) or 3+0 (unlikely)?
      _columnaConfig = _ColumnaConfig.dosMasUno;
    } else if (cfg.columnas == 5) {
      // 2+2 (aisle at 2) or 3+1 (aisle at 3)
      final hasSeatInCol2 = cfg.asientos.any(
        (a) => a.columna == 2 && a.tipo != TipoAsiento.vacio && a.fila > 0,
      );
      _columnaConfig = hasSeatInCol2
          ? _ColumnaConfig.tresMasUno
          : _ColumnaConfig.dosMasDos;
    } else if (cfg.columnas == 6) {
      _columnaConfig = _ColumnaConfig.tresMasDos;
    } else {
      _columnaConfig = _ColumnaConfig.dosMasDos;
    }

    _banoSeatNumbers = cfg.asientos
        .where((a) => a.tipo == TipoAsiento.bano && a.numero.isNotEmpty)
        .map((a) => a.numero)
        .toSet();

    _vazioSeatNumbers = cfg.asientos
        .where((a) => a.tipo == TipoAsiento.vacio && a.numero.isNotEmpty)
        .map((a) => a.numero)
        .toSet();

    _entradaSeatNumbers = cfg.asientos
        .where((a) => a.tipo == TipoAsiento.entrada && a.numero.isNotEmpty)
        .map((a) => a.numero)
        .toSet();

    final conductorSeat = cfg.asientos
        .where((a) => a.tipo == TipoAsiento.conductor)
        .firstOrNull;
    _conductorSeatNumber = conductorSeat?.numero.isNotEmpty == true
        ? conductorSeat!.numero
        : null;
  }

  // ── Configuración de columnas ────────────────────────────────────────────────

  // Retorna: (totalColumnas, aisleCol, leftSeats [(col, letra)], rightSeats [(col, letra)])
  ({
    int totalCols,
    int aisle,
    List<(int, String)> left,
    List<(int, String)> right,
  })
  get _colDef {
    switch (_columnaConfig) {
      case _ColumnaConfig.unoMasUno:
        // cols: 0=A  1=aisle  2=B
        return (totalCols: 3, aisle: 1, left: [(0, 'A')], right: [(2, 'B')]);
      case _ColumnaConfig.dosMasUno:
        // cols: 0=A  1=B  2=aisle  3=C
        return (
          totalCols: 4,
          aisle: 2,
          left: [(0, 'A'), (1, 'B')],
          right: [(3, 'C')],
        );
      case _ColumnaConfig.dosMasDos:
        // cols: 0=A  1=B  2=aisle  3=C  4=D
        return (
          totalCols: 5,
          aisle: 2,
          left: [(0, 'A'), (1, 'B')],
          right: [(3, 'C'), (4, 'D')],
        );
      case _ColumnaConfig.tresMasUno:
        // cols: 0=A  1=B  2=C  3=aisle  4=D
        return (
          totalCols: 5,
          aisle: 3,
          left: [(0, 'A'), (1, 'B'), (2, 'C')],
          right: [(4, 'D')],
        );
      case _ColumnaConfig.tresMasDos:
        // cols: 0=A  1=B  2=C  3=aisle  4=D  5=E
        return (
          totalCols: 6,
          aisle: 3,
          left: [(0, 'A'), (1, 'B'), (2, 'C')],
          right: [(4, 'D'), (5, 'E')],
        );
    }
  }

  // ── Generación automática del layout ────────────────────────────────────────

  BusConfiguracion _generarLayout() {
    final def = _colDef;
    final asientos = <AsientoLayout>[];

    // Fila 0: toda la fila empieza como normal, luego se aplican overrides
    for (int c = 0; c < def.totalCols; c++) {
      if (c == def.aisle) {
        asientos.add(AsientoLayout(
          fila: 0, columna: c, numero: '', tipo: TipoAsiento.vacio));
      } else {
        final num = '0${_letraForCol(c, def)}'; // etiqueta de fila 0
        asientos.add(AsientoLayout(
          fila: 0, columna: c, numero: num, tipo: TipoAsiento.normal));
      }
    }

    // Filas de pasajeros: todas las celdas de asiento como 'normal', pasillo como vacio
    for (int row = 1; row <= _filasPassajeros; row++) {
      for (int c = 0; c < def.totalCols; c++) {
        if (c == def.aisle) {
          asientos.add(AsientoLayout(
            fila: row, columna: c, numero: '', tipo: TipoAsiento.vacio));
        } else {
          final letra = _letraForCol(c, def);
          asientos.add(AsientoLayout(
            fila: row,
            columna: c,
            numero: '$row$letra',
            tipo: TipoAsiento.normal,
          ));
        }
      }
    }

    // Aplicar overrides: baño > vacio > entrada > conductor
    final resultado = asientos.map((a) {
      if (a.numero.isNotEmpty) {
        if (_banoSeatNumbers.contains(a.numero)) {
          return AsientoLayout(fila: a.fila, columna: a.columna, numero: a.numero, tipo: TipoAsiento.bano);
        }
        if (_vazioSeatNumbers.contains(a.numero)) {
          return AsientoLayout(fila: a.fila, columna: a.columna, numero: a.numero, tipo: TipoAsiento.vacio);
        }
        if (_entradaSeatNumbers.contains(a.numero)) {
          return AsientoLayout(fila: a.fila, columna: a.columna, numero: a.numero, tipo: TipoAsiento.entrada);
        }
        if (_conductorSeatNumber == a.numero) {
          return AsientoLayout(fila: a.fila, columna: a.columna, numero: a.numero, tipo: TipoAsiento.conductor);
        }
      }
      return a;
    }).toList();

    return BusConfiguracion(
      filas: _filasPassajeros + 1,
      columnas: def.totalCols,
      asientos: resultado,
    );
  }

  String _letraForCol(int col, ({int totalCols, int aisle, List<(int, String)> left, List<(int, String)> right}) def) {
    for (final (c, l) in def.left) { if (c == col) return l; }
    for (final (c, l) in def.right) { if (c == col) return l; }
    return '?';
  }

  void _toggleSeat(String numero, int fila, int columna, BuildContext ctx) {
    setState(() {
      final totalCols = _colDef.totalCols;
      final isLeftEdge = columna == 0;
      final isRightEdge = columna == totalCols - 1;

      switch (_paintMode) {
        case _PaintMode.bano:
          if (_banoSeatNumbers.contains(numero)) {
            _banoSeatNumbers.remove(numero);
          } else {
            _vazioSeatNumbers.remove(numero);
            _entradaSeatNumbers.remove(numero);
            if (_conductorSeatNumber == numero) _conductorSeatNumber = null;
            _banoSeatNumbers.add(numero);
          }

        case _PaintMode.vacio:
          if (_vazioSeatNumbers.contains(numero)) {
            _vazioSeatNumbers.remove(numero);
          } else {
            _banoSeatNumbers.remove(numero);
            _entradaSeatNumbers.remove(numero);
            if (_conductorSeatNumber == numero) _conductorSeatNumber = null;
            _vazioSeatNumbers.add(numero);
          }

        case _PaintMode.entrada:
          if (!isLeftEdge && !isRightEdge) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Las entradas solo pueden colocarse en los laterales del bus'),
                  duration: Duration(seconds: 3),
                ),
              );
            });
            return;
          }
          if (_entradaSeatNumbers.contains(numero)) {
            _entradaSeatNumbers.remove(numero);
          } else {
            _banoSeatNumbers.remove(numero);
            _vazioSeatNumbers.remove(numero);
            if (_conductorSeatNumber == numero) _conductorSeatNumber = null;
            _entradaSeatNumbers.add(numero);
          }

        case _PaintMode.conductor:
          if (fila != 0 || (!isLeftEdge && !isRightEdge)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('El conductor solo puede ir en una esquina del frente del bus'),
                  duration: Duration(seconds: 3),
                ),
              );
            });
            return;
          }
          if (_conductorSeatNumber == numero) {
            _conductorSeatNumber = null;
          } else if (_conductorSeatNumber != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('Ya existe un conductor en el bus'),
                  duration: Duration(seconds: 3),
                ),
              );
            });
            return;
          } else {
            _banoSeatNumbers.remove(numero);
            _vazioSeatNumbers.remove(numero);
            _entradaSeatNumbers.remove(numero);
            _conductorSeatNumber = numero;
          }

        case _PaintMode.normal:
          _banoSeatNumbers.remove(numero);
          _vazioSeatNumbers.remove(numero);
          _entradaSeatNumbers.remove(numero);
          if (_conductorSeatNumber == numero) _conductorSeatNumber = null;
      }
    });
  }

  int get _totalNormales {
    return _generarLayout().asientos
        .where((a) => a.tipo == TipoAsiento.normal)
        .length;
  }

  // ── Historial ────────────────────────────────────────────────────────────────

  Widget _buildHistorialSection() {
    Widget body;

    if (_loadingHistorial) {
      body = Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.saas.brand600,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Cargando historial...',
                style: TextStyle(
                  color: context.saas.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_historialError != null) {
      body = Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.saas.danger.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.saas.danger.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: context.saas.danger, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Error al cargar el historial',
                style: TextStyle(
                  color: context.saas.danger, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _loadHistorial,
              child: Text('Reintentar',
                  style: TextStyle(color: context.saas.brand600, fontSize: 12)),
            ),
          ],
        ),
      );
    } else if (_historial.isEmpty) {
      body = const PremiumEmptyIndicator(
        msg: 'Este bus aún no ha sido asignado a ningún tour.',
        icon: Icons.route_rounded,
      );
    } else {
      body = Column(
        children: _historial
            .map((item) => _HistorialItemCard(item: item))
            .toList(),
      );
    }

    return PremiumSectionCard(
      title: 'HISTORIAL DE VIAJES',
      icon: Icons.history_rounded,
      children: [body],
    );
  }

  // ── Guardar ─────────────────────────────────────────────────────────────────

  void _onSave(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final cfg = _generarLayout();
    final totalNormales = cfg.asientos
        .where((a) => a.tipo == TipoAsiento.normal)
        .length;

    final layout = BusLayout(
      id: widget.layout?.id,
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim(),
      configuracion: cfg,
      totalAsientosCliente: totalNormales,
      activo: widget.layout?.activo ?? true,
    );

    if (_isEditing) {
      context.read<BusLayoutBloc>().add(UpdateBusLayout(layout));
    } else {
      context.read<BusLayoutBloc>().add(CreateBusLayout(layout));
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('bus_layouts')
        : false;

    return BlocListener<BusLayoutBloc, BusLayoutState>(
      listener: (context, state) {
        if (state is BusLayoutSaved) {
          SaasSnackBar.showSuccess(
            context,
            _isEditing ? 'Diseño actualizado' : 'Diseño creado exitosamente',
          );
          Navigator.pop(context);
        } else if (state is BusLayoutError) {
          SaasSnackBar.showError(context, state.message);
        }
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            PremiumSliverAppBar(
              title: _isEditing && !canWrite
                  ? 'Ver Diseño de Bus'
                  : (_isEditing
                        ? 'Editar Diseño de Bus'
                        : 'Nuevo Diseño de Bus'),
              actions: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Badge ───────────────────────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: context.saas.brand50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: context.saas.brand600.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.directions_bus_rounded,
                                  color: context.saas.brand600,
                                  size: 16,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'CONFIGURACIÓN DEL BUS',
                                  style: TextStyle(
                                    color: context.saas.brand600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Info general ────────────────────────────────
                          PremiumSectionCard(
                            title: 'INFORMACIÓN GENERAL',
                            icon: Icons.info_outline_rounded,
                            children: [
                              PremiumTextField(
                                controller: _nombreCtrl,
                                label: 'Nombre del Layout *',
                                icon: Icons.directions_bus_rounded,
                                readOnly: !canWrite,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'El nombre es requerido'
                                    : null,
                              ),
                              const SizedBox(height: 20),
                              PremiumTextField(
                                controller: _descripcionCtrl,
                                label: 'Descripción (opcional)',
                                icon: Icons.description_rounded,
                                readOnly: !canWrite,
                                maxLines: 2,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Configuración ───────────────────────────────
                          PremiumSectionCard(
                            title: 'CONFIGURACIÓN DE ASIENTOS',
                            icon: Icons.event_seat_rounded,
                            children: [
                              // Filas de pasajeros
                              _ConfigOption(
                                icon: Icons.table_rows_rounded,
                                label: 'Filas de pasajeros',
                                subtitle:
                                    'Número de filas (sin contar la fila del conductor)',
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _StepButton(
                                      icon: Icons.remove,
                                      onPressed:
                                          canWrite && _filasPassajeros > 2
                                          ? () => setState(
                                              () => _filasPassajeros--,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 36,
                                      child: Text(
                                        '$_filasPassajeros',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: context.saas.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _StepButton(
                                      icon: Icons.add,
                                      onPressed:
                                          canWrite && _filasPassajeros < 20
                                          ? () => setState(
                                              () => _filasPassajeros++,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Distribución de columnas
                              _ColumnaConfigSelector(
                                value: _columnaConfig,
                                enabled: canWrite,
                                onChanged: (v) => setState(() {
                                  _columnaConfig = v;
                                  // Limpiar asientos especiales que ya no existen
                                  final layout = _generarLayout();
                                  final numeros = layout.asientos
                                      .map((a) => a.numero)
                                      .toSet();
                                  _banoSeatNumbers.removeWhere(
                                    (n) => !numeros.contains(n),
                                  );
                                }),
                              ),
                              const SizedBox(height: 16),

                              // Asientos de baño
                              _SeatSetPanel(
                                icon: Icons.wc_rounded,
                                label: 'Asientos de baño',
                                hint: 'Toca en la vista previa en modo Baño',
                                color: const Color(0xFF10B981),
                                bgColor: const Color(0xFFECFDF5),
                                seats: _banoSeatNumbers,
                                canWrite: canWrite,
                                onDelete: (n) => setState(() {
                                  _banoSeatNumbers.remove(n);
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Resumen ─────────────────────────────────────
                          _ResumenCard(totalNormales: _totalNormales),
                          const SizedBox(height: 20),

                          // ── Preview visual ──────────────────────────────
                          PremiumSectionCard(
                            title: 'VISTA PREVIA DEL BUS',
                            icon: Icons.preview_rounded,
                            children: [
                              if (canWrite) ...[
                                // Selector de modo
                                _PaintModeSelector(
                                  mode: _paintMode,
                                  onChanged: (m) =>
                                      setState(() => _paintMode = m),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.touch_app_rounded,
                                      size: 16,
                                      color: context.saas.textTertiary,
                                    ),
                                    const SizedBox(width: 6),
                                                                    Expanded(
                                      child: Text(
                                        _paintMode == _PaintMode.bano
                                            ? 'Toca un asiento para marcarlo como baño (verde)'
                                            : _paintMode == _PaintMode.vacio
                                            ? 'Toca un asiento para marcarlo como vacío (negro)'
                                            : _paintMode == _PaintMode.entrada
                                            ? 'Toca una celda lateral para marcarla como entrada (gris)'
                                            : _paintMode == _PaintMode.conductor
                                            ? 'Toca una esquina del frente del bus para el conductor'
                                            : 'Toca un asiento para restaurarlo como normal',
                                        style: TextStyle(
                                          color: context.saas.textTertiary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                              Builder(
                                builder: (ctx) => _BusPreview(
                                  configuracion: _generarLayout(),
                                  aisleIndex: _colDef.aisle,
                                  onSeatTap: canWrite
                                      ? (num, fila, col) =>
                                          _toggleSeat(num, fila, col, ctx)
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Historial de viajes ─────────────────────────
                          if (_isEditing) _buildHistorialSection(),

                          const SizedBox(height: 32),

                          // ── Botón guardar ───────────────────────────────
                          if (canWrite)
                            Builder(
                              builder: (ctx) =>
                                  BlocBuilder<BusLayoutBloc, BusLayoutState>(
                                    builder: (context, state) =>
                                        PremiumActionButton(
                                          label: _isEditing
                                              ? 'GUARDAR CAMBIOS'
                                              : 'CREAR LAYOUT',
                                          icon: Icons.save_rounded,
                                          isLoading: state is BusLayoutSaving,
                                          onTap: () => _onSave(ctx),
                                        ),
                                  ),
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
      ),
    );
  }
}

// ── Widgets internos ──────────────────────────────────────────────────────────

class _PaintModeSelector extends StatelessWidget {
  final _PaintMode mode;
  final ValueChanged<_PaintMode> onChanged;
  const _PaintModeSelector({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.saas.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Column(
        children: [
          Row(
            children: [
              _ModeTab(
                label: 'Normal',
                icon: Icons.event_seat_rounded,
                color: context.saas.brand600,
                selected: mode == _PaintMode.normal,
                onTap: () => onChanged(_PaintMode.normal),
              ),
              _ModeTab(
                label: 'Baño',
                icon: Icons.wc_rounded,
                color: const Color(0xFF10B981),
                selected: mode == _PaintMode.bano,
                onTap: () => onChanged(_PaintMode.bano),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _ModeTab(
                label: 'Vacío',
                icon: Icons.block_rounded,
                color: Colors.grey.shade800,
                selected: mode == _PaintMode.vacio,
                onTap: () => onChanged(_PaintMode.vacio),
              ),
              _ModeTab(
                label: 'Conductor',
                icon: Icons.drive_eta_rounded,
                color: const Color(0xFF1E3A5F),
                selected: mode == _PaintMode.conductor,
                onTap: () => onChanged(_PaintMode.conductor),
              ),
              _ModeTab(
                label: 'Entrada',
                icon: Icons.door_sliding_rounded,
                color: Colors.grey.shade600,
                selected: mode == _PaintMode.entrada,
                onTap: () => onChanged(_PaintMode.entrada),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ModeTab({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? color : context.saas.textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : context.saas.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SeatSetPanel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final Color color;
  final Color bgColor;
  final Set<String> seats;
  final bool canWrite;
  final void Function(String) onDelete;

  const _SeatSetPanel({
    required this.icon,
    required this.label,
    required this.hint,
    required this.color,
    required this.bgColor,
    required this.seats,
    required this.canWrite,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: seats.isNotEmpty ? bgColor : context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: seats.isNotEmpty
              ? color.withValues(alpha: 0.4)
              : context.saas.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: context.saas.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: TextStyle(
                        color: context.saas.textTertiary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${seats.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          if (seats.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: seats
                  .map(
                    (n) => Chip(
                      label: Text(n, style: const TextStyle(fontSize: 12)),
                      backgroundColor: color.withValues(alpha: 0.15),
                      side: BorderSide(color: color, width: 0.5),
                      deleteIcon: canWrite
                          ? const Icon(Icons.close, size: 14)
                          : null,
                      onDeleted: canWrite ? () => onDelete(n) : null,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ColumnaConfigSelector extends StatelessWidget {
  final _ColumnaConfig value;
  final bool enabled;
  final ValueChanged<_ColumnaConfig> onChanged;

  const _ColumnaConfigSelector({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  static const _opciones = [
    (
      config: _ColumnaConfig.unoMasUno,
      label: '1 + 1',
      sub: '2 as.',
      icon: '🚐',
    ),
    (
      config: _ColumnaConfig.dosMasUno,
      label: '2 + 1',
      sub: '3 as.',
      icon: '🚌',
    ),
    (
      config: _ColumnaConfig.dosMasDos,
      label: '2 + 2',
      sub: '4 as.',
      icon: '🚍',
    ),
    (
      config: _ColumnaConfig.tresMasUno,
      label: '3 + 1',
      sub: '4 as.',
      icon: '🚍',
    ),
    (
      config: _ColumnaConfig.tresMasDos,
      label: '3 + 2',
      sub: '5 as.',
      icon: '🚍',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.saas.brand50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.view_column_rounded,
                  size: 18,
                  color: context.saas.brand600,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribución de asientos',
                    style: TextStyle(
                      color: context.saas.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Columnas por lado del pasillo',
                    style: TextStyle(
                      color: context.saas.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: _opciones.map((op) {
              final selected = value == op.config;
              return Expanded(
                child: GestureDetector(
                  onTap: enabled ? () => onChanged(op.config) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? context.saas.brand600
                          : context.saas.bgApp,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? context.saas.brand600
                            : context.saas.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(op.icon, style: const TextStyle(fontSize: 20)),
                        const SizedBox(height: 4),
                        Text(
                          op.label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : context.saas.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          op.sub,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.8)
                                : context.saas.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  const _StepButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onPressed != null
              ? context.saas.brand600
              : context.saas.bgSubtle,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onPressed != null ? Colors.white : context.saas.textTertiary,
        ),
      ),
    );
  }
}

class _ConfigOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Widget trailing;

  const _ConfigOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.saas.brand50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: context.saas.brand600),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.saas.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _ResumenCard extends StatelessWidget {
  final int totalNormales;
  const _ResumenCard({required this.totalNormales});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.saas.brand600,
            context.saas.brand600.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_seat_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total asientos para clientes',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '$totalNormales',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Vista previa del bus ──────────────────────────────────────────────────────

class _BusPreview extends StatelessWidget {
  final BusConfiguracion configuracion;
  final int? aisleIndex;
  /// Called with (numero, fila, columna)
  final void Function(String numero, int fila, int columna)? onSeatTap;
  const _BusPreview({
    required this.configuracion,
    this.aisleIndex,
    this.onSeatTap,
  });

  static const _cellSize = 22.0;
  static const _gap = 3.0;
  static const _aisleWidth = 12.0;

  Color _colorForTipo(TipoAsiento tipo) {
    switch (tipo) {
      case TipoAsiento.normal:
        return const Color(0xFF3B82F6);
      case TipoAsiento.agente:
        return const Color(0xFFF59E0B);
      case TipoAsiento.conductor:
        return const Color(0xFF1E3A5F);
      case TipoAsiento.bano:
        return const Color(0xFF10B981);
      case TipoAsiento.vacio:
        return Colors.grey.shade900;
      case TipoAsiento.entrada:
        return Colors.grey.shade400;
    }
  }


  String _tooltipForTipo(TipoAsiento tipo, String numero) {
    switch (tipo) {
      case TipoAsiento.normal:
        return '$numero — Normal';
      case TipoAsiento.agente:
        return '$numero — Agente';
      case TipoAsiento.bano:
        return '$numero — Baño';
      case TipoAsiento.conductor:
        return 'Conductor';
      case TipoAsiento.vacio:
        return '$numero — Vacío';
      case TipoAsiento.entrada:
        return '$numero — Entrada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cfg = configuracion;
    final maxFila = cfg.asientos
        .map((a) => a.fila)
        .reduce((a, b) => a > b ? a : b);
    final aisle = aisleIndex ?? cfg.columnas ~/ 2;

    final porFila = <int, List<AsientoLayout>>{};
    for (final a in cfg.asientos) {
      porFila.putIfAbsent(a.fila, () => []).add(a);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Leyenda
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            const _LeyendaItem(color: Color(0xFF3B82F6), label: 'Normal'),
            const _LeyendaItem(color: Color(0xFF1E3A5F), label: 'Conductor'),
            const _LeyendaItem(color: Color(0xFF10B981), label: 'Baño'),
            _LeyendaItem(color: Colors.grey.shade900, label: 'Vacío'),
            _LeyendaItem(color: Colors.grey.shade400, label: 'Entrada'),
          ],
        ),
        const SizedBox(height: 16),

        // Grid del bus
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(maxFila + 1, (fila) {
              final asientosFila = (porFila[fila] ?? [])
                ..sort((a, b) => a.columna.compareTo(b.columna));

              return Padding(
                padding: const EdgeInsets.only(bottom: _gap),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(cfg.columnas, (col) {
                    if (col == aisle) {
                      return const SizedBox(width: _aisleWidth);
                    }

                    // Always show a cell for non-aisle columns (no skipping vacio)
                    final asiento = asientosFila
                        .where((a) => a.columna == col)
                        .firstOrNull;

                    // If no asiento data, show empty grey placeholder
                    if (asiento == null) {
                      return const SizedBox(
                        width: _cellSize + _gap,
                        height: _cellSize,
                      );
                    }

                    final tappable = onSeatTap != null;

                    // Build cell content based on tipo
                    Widget? cellChild;
                    if (asiento.tipo == TipoAsiento.bano) {
                      cellChild = const Icon(Icons.wc_rounded, size: 11, color: Colors.white);
                    } else if (asiento.tipo == TipoAsiento.entrada) {
                      cellChild = const Center(
                        child: Text(
                          'E',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    } else if (asiento.tipo == TipoAsiento.vacio) {
                      // black cell, no text
                      cellChild = null;
                    } else if (asiento.numero.isNotEmpty) {
                      cellChild = FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Text(
                            asiento.tipo == TipoAsiento.conductor
                                ? 'C'
                                : asiento.numero,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }

                    final cell = Container(
                      width: _cellSize,
                      height: _cellSize,
                      decoration: BoxDecoration(
                        color: _colorForTipo(asiento.tipo),
                        borderRadius: BorderRadius.circular(4),
                        border: tappable
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null,
                      ),
                      child: cellChild,
                    );

                    return Padding(
                      padding: const EdgeInsets.only(right: _gap),
                      child: Tooltip(
                        message: _tooltipForTipo(asiento.tipo, asiento.numero),
                        child: tappable
                            ? GestureDetector(
                                onTap: () => onSeatTap!(
                                  asiento.numero,
                                  asiento.fila,
                                  asiento.columna,
                                ),
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: cell,
                                ),
                              )
                            : cell,
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Historial item card ────────────────────────────────────────────────────────

class _HistorialItemCard extends StatelessWidget {
  final BusTourHistorialItem item;
  const _HistorialItemCard({required this.item});

  static const _dateFmt = 'dd MMM yyyy';

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return const Color(0xFF10B981);
      case 'finalizado':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String _estadoLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return 'Activo';
      case 'finalizado':
        return 'Finalizado';
      case 'inactivo':
        return 'Inactivo';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(item.estado);
    final dateFmt = DateFormat(_dateFmt, 'es_CO');
    final inicio = item.fechaInicio != null
        ? dateFmt.format(item.fechaInicio!)
        : '—';
    final fin = item.fechaFin != null
        ? dateFmt.format(item.fechaFin!)
        : '—';
    final ocup = item.porcentajeOcupacion.clamp(0, 100) / 100.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre + badge estado
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.nombreTour,
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _estadoLabel(item.estado),
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Fechas
          Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12, color: context.saas.textTertiary),
              const SizedBox(width: 5),
              Text(
                '$inicio → $fin',
                style: TextStyle(
                  color: context.saas.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stats
          Row(
            children: [
              _StatChip(
                icon: Icons.confirmation_number_rounded,
                label: '${item.totalReservas} reservas',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.people_rounded,
                label: '${item.totalPasajeros} pasajeros',
              ),
              const SizedBox(width: 8),
              _StatChip(
                icon: Icons.event_seat_rounded,
                label: '${item.asientosOcupados}/${item.asientosOcupados + item.asientosDisponibles}',
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Barra de ocupación
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ocup,
                    minHeight: 6,
                    backgroundColor: context.saas.border,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      item.porcentajeOcupacion >= 90
                          ? const Color(0xFFEF4444)
                          : item.porcentajeOcupacion >= 60
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.porcentajeOcupacion}%',
                style: TextStyle(
                  color: context.saas.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.saas.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: context.saas.textTertiary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: context.saas.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LeyendaItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: context.saas.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
