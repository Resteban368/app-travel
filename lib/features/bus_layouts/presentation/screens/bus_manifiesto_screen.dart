import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as webLib;
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/dialog_loading_widget.dart';
import '../../domain/entities/bus_manifiesto.dart';
import '../../domain/entities/bus_layout.dart';
import '../bloc/bus_manifiesto_bloc.dart';
import '../bloc/bus_manifiesto_event.dart';
import '../bloc/bus_manifiesto_state.dart';
import '../pdf/bus_manifiesto_pdf_generator.dart';

// Paleta de colores para reservas (igual al HTML)
const List<Color> _kReservaColors = [
  Color(0xFF2563EB), // azul
  Color(0xFF059669), // verde
  Color(0xFFD97706), // ámbar
  Color(0xFF7C3AED), // violeta
  Color(0xFFDB2777), // rosa
  Color(0xFF0891B2), // cyan
  Color(0xFFEA580C), // naranja
  Color(0xFF65A30D), // lima
  Color(0xFF6D28D9), // púrpura
  Color(0xFF0F766E), // teal
];

Color _colorParaReserva(String idReserva, Map<String, Color> cache) {
  if (cache.containsKey(idReserva)) return cache[idReserva]!;
  final color = _kReservaColors[cache.length % _kReservaColors.length];
  cache[idReserva] = color;
  return color;
}

class BusManifiestoScreen extends StatelessWidget {
  final int tourId;
  final int? salidaId;
  const BusManifiestoScreen({super.key, required this.tourId, this.salidaId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BusManifiestoBloc>()..add(LoadBusManifiesto(tourId, salidaId: salidaId)),
      child: const _BusManifiestoBody(),
    );
  }
}


class _BusManifiestoBody extends StatefulWidget {
  const _BusManifiestoBody();

  @override
  State<_BusManifiestoBody> createState() => _BusManifiestoBodyState();
}

class _ModoMoverInfo {
  final int tourId;
  final int busLayoutId;
  final int reservaId;
  final String idReserva;
  final String asientoOrigen;
  const _ModoMoverInfo({
    required this.tourId,
    required this.busLayoutId,
    required this.reservaId,
    required this.idReserva,
    required this.asientoOrigen,
  });
}


class _BusManifiestoBodyState extends State<_BusManifiestoBody>
    with SingleTickerProviderStateMixin {
  int _busIndex = 0;
  String? _reservaSeleccionada;
  String? _asientoSeleccionado;
  final Map<String, Color> _colorCache = {};
  TabController? _tabController;
  _ModoMoverInfo? _modoMover;
  bool _loadingDialogOpen = false;
  int? _tourId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLoadingDialog('Cargando manifiesto de bus...');
    });
  }

  void _showLoadingDialog(String message) {
    if (_loadingDialogOpen) return;
    _loadingDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => DialogLoadingNetwork(titel: message),
    ).then((_) {
      // Only reset if _closeLoadingDialog() wasn't already called.
      // Guards against the race where a first dialog's dismiss animation
      // finishes after a second dialog has already been opened.
      if (_loadingDialogOpen && mounted) {
        setState(() => _loadingDialogOpen = false);
      }
    });
  }

  void _closeLoadingDialog() {
    if (!_loadingDialogOpen || !mounted) return;
    // Use setState so the flag is committed before any pending .then() fires.
    setState(() => _loadingDialogOpen = false);
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: context.saas.brand600,
        foregroundColor: Colors.white,
        title: const Text(
          'Manifiesto de Bus',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Exportar PDF',
            onPressed: () => _exportPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final bloc = context.read<BusManifiestoBloc>();
              final state = bloc.state;
              if (state is BusManifiestoLoaded) {
                _showLoadingDialog('Cargando manifiesto de bus...');
                bloc.add(LoadBusManifiesto(state.manifiesto.tour.id));
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<BusManifiestoBloc, BusManifiestoState>(
        listener: (context, state) {
          if (state is BusManifiestoLoaded || state is BusManifiestoError) {
            _closeLoadingDialog();
          }
          if (state is BusManifiestoAsignando) {
            _showLoadingDialog('Asignando asientos...');
          } else if (state is BusManifiestoOperando) {
            _showLoadingDialog('Procesando operación...');
          } else if (state is BusManifiestoOperacionExito) {
            _closeLoadingDialog();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Text('Operación completada con éxito'),
                  ],
                ),
                backgroundColor: Color(0xFF059669),
                duration: Duration(seconds: 2),
              ),
            );
          } else if (state is BusManifiestoOperacionError) {
            _closeLoadingDialog();
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Row(
                  children: [
                    Icon(Icons.error_rounded, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Error', style: TextStyle(fontSize: 17)),
                  ],
                ),
                content: Text(state.mensaje),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BusManifiestoLoading) {
            return const SizedBox.shrink();
          }
          if (state is BusManifiestoError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(state.message, textAlign: TextAlign.center),
                ],
              ),
            );
          }
          BusManifiesto? manifiesto;
          if (state is BusManifiestoLoaded) manifiesto = state.manifiesto;
          if (state is BusManifiestoAsignando) manifiesto = state.manifiesto;
          if (state is BusManifiestoOperando) manifiesto = state.manifiesto;
          if (state is BusManifiestoOperacionExito) manifiesto = state.manifiesto;
          if (state is BusManifiestoOperacionError) manifiesto = state.manifiesto;
          if (manifiesto != null) return _buildContent(manifiesto);
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BusManifiesto manifiesto, {bool asignando = false}) {
    _tourId = manifiesto.tour.id;
    final buses = manifiesto.buses;
    if (buses.isEmpty) {
      return const Center(child: Text('Este tour no tiene buses asignados'));
    }

    if (_tabController == null || _tabController!.length != buses.length) {
      _tabController?.dispose();
      _tabController = TabController(length: buses.length, vsync: this);
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) {
          setState(() {
            _busIndex = _tabController!.index;
            _reservaSeleccionada = null;
            _asientoSeleccionado = null;
          });
        }
      });
    }

    return Column(
      children: [
        _TourInfoCard(tour: manifiesto.tour),
        if (_modoMover != null)
          _buildModoMoverBanner()
        else if (manifiesto.reservasSinAsientos.isNotEmpty)
          _buildSinAsientosBar(manifiesto, asignando: asignando),
        if (buses.length > 1) _buildBusTabs(buses),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: buses.map((bus) => _buildBusView(bus)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildModoMoverBanner() {
    final info = _modoMover!;
    return Container(
      color: const Color(0xFFEFF6FF),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.open_with_rounded, color: Color(0xFF1D4ED8), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF1E40AF), fontSize: 13),
                children: [
                  const TextSpan(text: 'Moviendo asiento '),
                  TextSpan(
                    text: info.asientoOrigen,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: ' de ${info.idReserva}. Toca el asiento destino'),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _cancelarModoMover,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1D4ED8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSinAsientosBar(BusManifiesto manifiesto, {bool asignando = false}) {
    final sinAsientos = manifiesto.reservasSinAsientos;
    return Container(
      color: const Color(0xFFFFFBEB),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${sinAsientos.length} reserva${sinAsientos.length > 1 ? 's' : ''} sin asientos asignados',
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: asignando
                    ? null
                    : () => context.read<BusManifiestoBloc>().add(
                          AutoAsignarAsientos(manifiesto.tour.id),
                        ),
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: const Text('Auto-asignar', style: TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: context.saas.brand600,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: sinAsientos.map((r) {
              final nombre = r.responsable?.nombre ?? r.idReserva;
              final sinBus = r.busLayoutId == null;
              final sinAsientoCount =
                  r.integrantes.where((i) => !i.ocupaAsiento).length;
              final label = sinAsientoCount > 0
                  ? '$nombre (${r.totalPersonas}p · $sinAsientoCount sin asiento)'
                  : '$nombre (${r.totalPersonas}p)';
              return ActionChip(
                avatar: Icon(
                  sinBus ? Icons.person_pin_circle_rounded : Icons.event_seat_outlined,
                  size: 14,
                  color: sinBus ? Colors.red : const Color(0xFF92400E),
                ),
                label: Text(label, style: const TextStyle(fontSize: 11)),
                backgroundColor: sinBus ? const Color(0xFFFFE4E6) : const Color(0xFFFEF3C7),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                tooltip: 'Toca para asignar asiento manualmente',
                onPressed: () => _mostrarDialogAsignar(context, manifiesto, r),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBusTabs(List<BusManifiestoData> buses) {
    return Container(
      color: const Color(0xFF020617),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        indicatorColor: context.saas.brand600,
        tabs: buses.map((b) {
          return Tab(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_bus_rounded, size: 16),
                if (b.entrada != null && b.entrada!.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.confirmation_num_rounded,
                    size: 14,
                    color: Color(0xFFFBBF24),
                  ),
                ],
              ],
            ),
            text: b.nombre,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBusView(BusManifiestoData bus) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildBusColumn(bus)),
              Container(width: 1, color: const Color(0xFFE2E8F0)),
              SizedBox(width: 280, child: _buildReservasList(bus)),
            ],
          );
        }
        return Column(
          children: [
            _BusStatsBar(bus: bus),
            Expanded(
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: context.saas.brand600,
                      unselectedLabelColor: Color(0xFF64748B),
                      indicatorColor: context.saas.brand600,
                      tabs: [
                        Tab(text: 'Mapa del bus'),
                        Tab(text: 'Reservas'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [_buildBusGrid(bus), _buildReservasList(bus)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBusColumn(BusManifiestoData bus) {
    return Column(
      children: [
        _BusStatsBar(bus: bus),
        Expanded(child: _buildBusGrid(bus)),
      ],
    );
  }

  Widget _buildBusGrid(BusManifiestoData bus) {
    final cfg = bus.configuracion;

    // Position-based lookups — handle duplicate numero values (e.g. multiple baños)
    final manifPorPos = <(int, int), AsientoManifiesto>{
      for (final a in bus.asientos) (a.fila, a.columna): a,
    };
    final layoutByPos = <(int, int), AsientoLayout>{
      for (final a in cfg.asientos) (a.fila, a.columna): a,
    };

    final maxFila = cfg.asientos.isEmpty
        ? 0
        : cfg.asientos.map((a) => a.fila).reduce((a, b) => a > b ? a : b);
    final mitad = (cfg.columnas / 2).floor();

    // ── debug: confirm special seats reach the renderer ───────────────────
    final speciales = layoutByPos.entries
        .where((e) => e.value.tipo != TipoAsiento.normal && e.value.tipo != TipoAsiento.vacio)
        .map((e) => '${e.value.tipo.name}(${e.key.$1},${e.key.$2})')
        .toList();
    debugPrint('🎨 [BusGrid] "${bus.nombre}": mitad=$mitad columnas=${cfg.columnas} '
        'especiales=$speciales');
    // ─────────────────────────────────────────────────────────────────────

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              _BusFront(),
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
                              fontSize: 10, color: Color(0xFF94A3B8)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 4),
                      for (int col = 0; col < cfg.columnas; col++)
                        if (col == mitad)
                          const SizedBox(width: 20)
                        else
                          _buildCelda(layoutByPos[(filaIdx, col)],
                              manifPorPos[(filaIdx, col)], bus),
                      const SizedBox(width: 4),
                      const SizedBox(width: 24),
                    ],
                  ),
                );
              }),
              _BusBack(),
              const SizedBox(height: 16),
              _buildLeyenda(bus),
            ],
          ),
        ),
      ),
    );
  }

  /// Dispatches a single grid cell by seat type.
  /// [layout] is null when no seat exists at this position.
  Widget _buildCelda(
    AsientoLayout? layout,
    AsientoManifiesto? asiento,
    BusManifiestoData bus,
  ) {
    if (layout == null || layout.tipo == TipoAsiento.vacio) {
      return const SizedBox(width: 52, height: 52);
    }
    if (layout.tipo == TipoAsiento.bano) return _buildBanoCellSimple();
    if (layout.tipo == TipoAsiento.conductor) {
      return _AsientoConductor(numero: layout.numero);
    }
    if (layout.tipo == TipoAsiento.agente) {
      return _AsientoAgente(numero: layout.numero);
    }
    if (layout.tipo == TipoAsiento.entrada) {
      return _AsientoEntrada(numero: layout.numero);
    }
    return _buildAsiento(layout, asiento, bus);
  }

  Widget _buildAsiento(
    AsientoLayout layout,
    AsientoManifiesto? asiento,
    BusManifiestoData bus,
  ) {
    if (layout.tipo == TipoAsiento.vacio) {
      return const SizedBox(width: 52, height: 52);
    }
    if (layout.tipo == TipoAsiento.conductor) {
      return _AsientoConductor(numero: layout.numero);
    }
    if (layout.tipo == TipoAsiento.agente) {
      return _AsientoAgente(numero: layout.numero);
    }
    if (layout.tipo == TipoAsiento.entrada) {
      return _AsientoEntrada(numero: layout.numero);
    }

    final reserva = asiento?.reserva;
    final isLibre = reserva == null;
    final enModoMover = _modoMover != null && _modoMover!.busLayoutId == bus.busLayoutId;
    final isOrigen = enModoMover && _modoMover!.asientoOrigen == layout.numero;
    final isSeleccionado = _asientoSeleccionado == layout.numero;
    final isResaltado = reserva != null && _reservaSeleccionada == reserva.idReserva;

    final reservaColor = isLibre ? null : _colorParaReserva(reserva.idReserva, _colorCache);
    final color = isOrigen
        ? Colors.orange
        : isLibre
            ? const Color(0xFFE2E8F0)
            : reservaColor!;

    final iconColor = isLibre ? const Color(0xFF94A3B8) : Colors.white;
    final textColor = isLibre ? const Color(0xFF64748B) : Colors.white;

    return GestureDetector(
      onTap: () {
        if (enModoMover) {
          if (isOrigen) {
            _cancelarModoMover();
          } else {
            _ejecutarMover(layout.numero);
          }
          return;
        }
        setState(() {
          if (_asientoSeleccionado == layout.numero) {
            _asientoSeleccionado = null;
            _reservaSeleccionada = null;
          } else {
            _asientoSeleccionado = layout.numero;
            _reservaSeleccionada = reserva?.idReserva;
          }
        });
        if (reserva != null) {
          _mostrarDetalleReserva(reserva, layout.numero, _tourId!, bus.busLayoutId);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSeleccionado || isResaltado ? Colors.white : color.withValues(alpha: 0.5),
            width: isSeleccionado || isResaltado ? 2.5 : 1,
          ),
          boxShadow: isResaltado || isSeleccionado
              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.airline_seat_recline_normal_rounded,
              size: 18,
              color: iconColor,
            ),
            Text(
              layout.numero,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Un solo baño: container compacto que no deforma la fila.
  Widget _buildBanoCellSimple() {
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
          Text('Baño',
              style: TextStyle(fontSize: 7, color: Color(0xFF16A34A))),
        ],
      ),
    );
  }

  Widget _buildLeyenda(BusManifiestoData bus) {
    // Obtener reservas únicas para la leyenda
    final reservasUnicas = <String, ReservaManifiesto>{};
    for (final a in bus.asientos) {
      if (a.reserva != null) {
        reservasUnicas[a.reserva!.idReserva] = a.reserva!;
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LEYENDA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _LeyendaItem(
                color: const Color(0xFFE2E8F0),
                label: 'Libre',
                textColor: const Color(0xFF64748B),
              ),
              ...reservasUnicas.entries.map(
                (e) => _LeyendaItem(
                  color: _colorParaReserva(e.key, _colorCache),
                  label: e.key,
                  textColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReservasList(BusManifiestoData bus) {
    final reservasUnicas = <String, ReservaManifiesto>{};
    for (final a in bus.asientos) {
      if (a.reserva != null) reservasUnicas[a.reserva!.idReserva] = a.reserva!;
    }

    final asientosPorReserva = <String, List<String>>{};
    for (final a in bus.asientos) {
      if (a.reserva != null) {
        asientosPorReserva
            .putIfAbsent(a.reserva!.idReserva, () => [])
            .add(a.numero);
      }
    }

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Icon(
                  Icons.people_rounded,
                  size: 18,
                  color: context.saas.brand600,
                ),
                const SizedBox(width: 8),
                Text(
                  'Reservas (${reservasUnicas.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
          if (reservasUnicas.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Sin asientos confirmados',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: reservasUnicas.length,
                separatorBuilder: (_, i) => const SizedBox(height: 8),
                itemBuilder: (context, idx) {
                  final reserva = reservasUnicas.values.elementAt(idx);
                  final color = _colorParaReserva(
                    reserva.idReserva,
                    _colorCache,
                  );
                  final asientos = asientosPorReserva[reserva.idReserva] ?? [];
                  final isExpanded = _reservaSeleccionada == reserva.idReserva;

                  return _ReservaCard(
                    reserva: reserva,
                    color: color,
                    asientos: asientos,
                    isExpanded: isExpanded,
                    onTap: () => setState(() {
                      _reservaSeleccionada = isExpanded
                          ? null
                          : reserva.idReserva;
                      _asientoSeleccionado = null;
                    }),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _mostrarDetalleReserva(
    ReservaManifiesto reserva,
    String numeroAsiento,
    int tourId,
    int busLayoutId,
  ) {
    final color = _colorParaReserva(reserva.idReserva, _colorCache);
    showDialog(
      context: context,
      builder: (ctx) => _ReservaDialog(
        reserva: reserva,
        color: color,
        numeroAsiento: numeroAsiento,
        onLiberar: () {
          Navigator.of(ctx).pop();
          context.read<BusManifiestoBloc>().add(LiberarAsiento(
            tourId: tourId,
            reservaId: reserva.id,
            numeroAsiento: numeroAsiento,
          ));
        },
        onMover: () {
          Navigator.of(ctx).pop();
          setState(() {
            _modoMover = _ModoMoverInfo(
              tourId: tourId,
              busLayoutId: busLayoutId,
              reservaId: reserva.id,
              idReserva: reserva.idReserva,
              asientoOrigen: numeroAsiento,
            );
          });
        },
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context) async {
    final bloc = context.read<BusManifiestoBloc>();
    final state = bloc.state;
    BusManifiesto? manifiesto;
    if (state is BusManifiestoLoaded) manifiesto = state.manifiesto;
    if (state is BusManifiestoOperacionExito) manifiesto = state.manifiesto;
    if (state is BusManifiestoOperando) manifiesto = state.manifiesto;
    if (manifiesto == null) return;

    _showLoadingDialog('Generando PDF...');
    // Yield so the dialog renders before PDF generation begins
    await Future.delayed(Duration.zero);

    try {
      final bytes = await BusManifestoPdfGenerator.generate(manifiesto);
      _closeLoadingDialog();
      if (!context.mounted) return;

      final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final tourName = manifiesto.tour.nombreTour
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .replaceAll(' ', '_');
      final filename = 'Manifiesto_${tourName}_$dateStr.pdf';

      await _showPdfDialog(context, Uint8List.fromList(bytes), filename);
    } catch (e) {
      _closeLoadingDialog();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPdfDialog(
    BuildContext context,
    Uint8List bytes,
    String filename,
  ) async {
    void openInNewTab() {
      final blob = webLib.Blob(
        <JSAny>[bytes.buffer.toJS].toJS,
        webLib.BlobPropertyBag(type: 'application/pdf'),
      );
      final url = webLib.URL.createObjectURL(blob);
      webLib.window.open(url, '_blank', '');
    }

    void download() {
      final blob = webLib.Blob(
        <JSAny>[bytes.buffer.toJS].toJS,
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
        backgroundColor: context.saas.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.saas.brand600.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: context.saas.brand600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PDF Listo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.saas.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                filename,
                style: TextStyle(
                  fontSize: 13,
                  color: context.saas.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Ver PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.saas.brand600,
                        side: BorderSide(color: context.saas.brand600),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: openInNewTab,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Descargar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.saas.brand600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: download,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cerrar',
                  style: TextStyle(color: context.saas.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cancelarModoMover() => setState(() => _modoMover = null);

  Future<void> _mostrarDialogAsignar(
    BuildContext context,
    BusManifiesto manifiesto,
    ReservaManifiesto r,
  ) async {
    final result = await showDialog<(int, List<String>)>(
      context: context,
      builder: (ctx) => _AsignarAsientoDialog(
        manifiesto: manifiesto,
        reserva: r,
        colorCache: _colorCache,
      ),
    );
    if (result != null && mounted) {
      context.read<BusManifiestoBloc>().add(AsignarAsientoManual(
        tourId: manifiesto.tour.id,
        busLayoutId: result.$1,
        reservaId: r.id,
        asientos: result.$2,
      ));
    }
  }

  void _ejecutarMover(String asientoDestino) {
    final info = _modoMover!;
    setState(() => _modoMover = null);
    context.read<BusManifiestoBloc>().add(MoverAsiento(
      tourId: info.tourId,
      busLayoutId: info.busLayoutId,
      reservaIdOrigen: info.reservaId,
      asientoOrigen: info.asientoOrigen,
      asientoDestino: asientoDestino,
    ));
  }
}

// ── Dialog asignar asiento ────────────────────────────────────────────────────

class _AsignarAsientoDialog extends StatefulWidget {
  final BusManifiesto manifiesto;
  final ReservaManifiesto reserva;
  final Map<String, Color> colorCache;

  const _AsignarAsientoDialog({
    required this.manifiesto,
    required this.reserva,
    required this.colorCache,
  });

  @override
  State<_AsignarAsientoDialog> createState() => _AsignarAsientoDialogState();
}

class _AsignarAsientoDialogState extends State<_AsignarAsientoDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _selected = [];
  int? _lockedBusLayoutId;

  int get _seatsNeeded {
    int count = (widget.reserva.responsable?.ocupaAsiento == true) ? 1 : 0;
    count += widget.reserva.integrantes.where((i) => i.ocupaAsiento).length;
    return count.clamp(1, 999);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.manifiesto.buses.length,
      vsync: this,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final newBus = widget.manifiesto.buses[_tabController.index].busLayoutId;
        if (_lockedBusLayoutId != null && _lockedBusLayoutId != newBus) {
          setState(() {
            _selected.clear();
            _lockedBusLayoutId = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSeat(String numero, int busLayoutId) {
    setState(() {
      if (_selected.contains(numero)) {
        _selected.remove(numero);
        if (_selected.isEmpty) _lockedBusLayoutId = null;
      } else if (_selected.length < _seatsNeeded) {
        _selected.add(numero);
        _lockedBusLayoutId = busLayoutId;
      }
    });
  }

  Widget _buildGrid(BusManifiestoData bus) {
    final cfg = bus.configuracion;
    final manifPorPos = <(int, int), AsientoManifiesto>{
      for (final a in bus.asientos) (a.fila, a.columna): a,
    };
    final layoutByPos = <(int, int), AsientoLayout>{
      for (final a in cfg.asientos) (a.fila, a.columna): a,
    };
    final maxFila = cfg.asientos.isEmpty
        ? 0
        : cfg.asientos.map((a) => a.fila).reduce((a, b) => a > b ? a : b);
    final mitad = (cfg.columnas / 2).floor();
    final isThisBusLocked =
        _lockedBusLayoutId != null && _lockedBusLayoutId != bus.busLayoutId;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              _BusFront(),
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
                              fontSize: 10, color: Color(0xFF94A3B8)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 4),
                      for (int col = 0; col < cfg.columnas; col++)
                        if (col == mitad)
                          const SizedBox(width: 20)
                        else
                          _buildCeldaDialog(layoutByPos[(filaIdx, col)],
                              manifPorPos[(filaIdx, col)], bus, isThisBusLocked),
                      const SizedBox(width: 4),
                      const SizedBox(width: 24),
                    ],
                  ),
                );
              }),
              _BusBack(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCeldaDialog(
    AsientoLayout? layout,
    AsientoManifiesto? asiento,
    BusManifiestoData bus,
    bool isThisBusLocked,
  ) {
    if (layout == null || layout.tipo == TipoAsiento.vacio) {
      return const SizedBox(width: 52, height: 52);
    }
    if (layout.tipo == TipoAsiento.bano) return _buildBanoCellDialog();
    if (layout.tipo == TipoAsiento.conductor) {
      return _AsientoConductor(numero: layout.numero);
    }
    if (layout.tipo == TipoAsiento.agente) {
      return _AsientoAgente(numero: layout.numero);
    }
    if (layout.tipo == TipoAsiento.entrada) {
      return _AsientoEntrada(numero: layout.numero);
    }

    final isSelected = _selected.contains(layout.numero);
    final isLibre = asiento?.reserva == null;
    final tappable = isLibre && !isThisBusLocked;

    Color baseColor;
    if (isSelected) {
      baseColor = const Color(0xFF059669);
    } else if (isLibre) {
      baseColor = const Color(0xFFE2E8F0);
    } else {
      baseColor = _colorParaReserva(asiento!.reserva!.idReserva, widget.colorCache);
    }
    final color =
        isThisBusLocked ? baseColor.withValues(alpha: 0.3) : baseColor;

    final iconColor =
        (isLibre && !isSelected) ? const Color(0xFF94A3B8) : Colors.white;
    final textColor =
        (isLibre && !isSelected) ? const Color(0xFF64748B) : Colors.white;

    final cell = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 48,
      height: 48,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.white : color.withValues(alpha: 0.5),
          width: isSelected ? 2.5 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF059669).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.airline_seat_recline_normal_rounded,
              size: 18, color: iconColor),
          Text(
            layout.numero,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );

    if (!tappable) return cell;
    return Tooltip(
      message: layout.numero,
      child: GestureDetector(
        onTap: () => _toggleSeat(layout.numero, bus.busLayoutId),
        child: MouseRegion(cursor: SystemMouseCursors.click, child: cell),
      ),
    );
  }

  Widget _buildBanoCellDialog() {
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
          Text('Baño', style: TextStyle(fontSize: 7, color: Color(0xFF16A34A))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buses = widget.manifiesto.buses;
    final seatsNeeded = _seatsNeeded;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 540,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.saas.bgCanvas,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: context.saas.border)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_circle_rounded,
                        color: Color(0xFF059669), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asignar Asiento',
                            style: TextStyle(
                              color: context.saas.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.reserva.responsable?.nombre ?? widget.reserva.idReserva,
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
                      icon: Icon(Icons.close_rounded,
                          color: context.saas.textTertiary),
                    ),
                  ],
                ),
              ),

              // Tabs de buses (si hay más de uno)
              if (buses.length > 1)
                Container(
                  color: const Color(0xFF020617),
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: const Color(0xFF059669),
                    tabs: buses
                        .map((b) => Tab(
                              icon: const Icon(Icons.directions_bus_rounded,
                                  size: 14),
                              text: b.nombre,
                            ))
                        .toList(),
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
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Toca un asiento libre (gris) · necesitas $seatsNeeded asiento${seatsNeeded == 1 ? '' : 's'}',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF059669).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${_selected.length}/$seatsNeeded seleccionado${_selected.length == 1 ? '' : 's'}: ${_selected.join(', ')}',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              // Mapa del bus
              Expanded(
                child: buses.length == 1
                    ? _buildGrid(buses.first)
                    : TabBarView(
                        controller: _tabController,
                        physics: const NeverScrollableScrollPhysics(),
                        children: buses.map(_buildGrid).toList(),
                      ),
              ),

              // Botones
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.saas.textSecondary,
                          side: BorderSide(color: context.saas.border),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () => Navigator.pop(
                                context,
                                (_lockedBusLayoutId!, List<String>.from(_selected))),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF059669).withValues(alpha: 0.3),
                          padding:
                              const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          _selected.isEmpty
                              ? 'ASIGNAR'
                              : 'ASIGNAR (${_selected.length}/$seatsNeeded)',
                          style: const TextStyle(fontWeight: FontWeight.w700),
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

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _TourInfoCard extends StatelessWidget {
  final TourInfoManifiesto tour;
  const _TourInfoCard({required this.tour});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'es');
    return Container(
      width: double.infinity,
      color: context.saas.brand600,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (tour.esPromocion)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PROMO',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  tour.nombreTour,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              if (tour.fechaInicio != null)
                _InfoChip(
                  icon: Icons.calendar_today_rounded,
                  text: fmt.format(tour.fechaInicio!),
                ),
              if (tour.fechaFin != null)
                _InfoChip(
                  icon: Icons.event_rounded,
                  text: fmt.format(tour.fechaFin!),
                ),
              if (tour.horaPartida != null)
                _InfoChip(
                  icon: Icons.access_time_rounded,
                  text: tour.horaPartida!,
                ),
              if (tour.puntoPartida != null)
                _InfoChip(icon: Icons.place_rounded, text: tour.puntoPartida!),
              if (tour.llegada != null)
                _InfoChip(icon: Icons.flag_rounded, text: tour.llegada!),
              if (tour.cupos != null)
                _InfoChip(
                  icon: Icons.event_seat_rounded,
                  text: '${tour.cupos} cupos',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}

class _BusStatsBar extends StatelessWidget {
  final BusManifiestoData bus;
  const _BusStatsBar({required this.bus});

  @override
  Widget build(BuildContext context) {
    final pct = bus.totalAsientosCliente > 0
        ? bus.asientosOcupados / bus.totalAsientosCliente
        : 0.0;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_bus_rounded,
                size: 16,
                color: context.saas.brand600,
              ),
              const SizedBox(width: 6),
              Text(
                bus.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              if (bus.entrada != null && bus.entrada!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Entrada: ${bus.entrada}',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.confirmation_num_rounded,
                          size: 12,
                          color: Color(0xFFD97706),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Entrada',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              _StatPill(
                label: '${bus.asientosOcupados} ocupados',
                color: context.saas.brand600,
              ),
              const SizedBox(width: 6),
              _StatPill(
                label: '${bus.asientosDisponibles} libres',
                color: const Color(0xFF059669),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation(
                pct > 0.8
                    ? Colors.red
                    : pct > 0.5
                    ? Colors.orange
                    : context.saas.brand600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(pct * 100).toStringAsFixed(0)}% ocupado · ${bus.totalAsientosCliente} asientos totales',
            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BusFront extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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

class _BusBack extends StatelessWidget {
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

class _AsientoConductor extends StatelessWidget {
  final String numero;
  const _AsientoConductor({required this.numero});

  @override
  Widget build(BuildContext context) {
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
}

class _AsientoAgente extends StatelessWidget {
  final String numero;
  const _AsientoAgente({required this.numero});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
          Text(
            'Agente',
            style: TextStyle(fontSize: 8, color: Color(0xFFF59E0B)),
          ),
        ],
      ),
    );
  }
}

class _AsientoEntrada extends StatelessWidget {
  final String numero;
  const _AsientoEntrada({required this.numero});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.4)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_num_rounded,
              color: Color(0xFF7C3AED), size: 18),
          Text(
            'Entrada',
            style: TextStyle(fontSize: 8, color: Color(0xFF7C3AED)),
          ),
        ],
      ),
    );
  }
}

class _LeyendaItem extends StatelessWidget {
  final Color color;
  final String label;
  final Color textColor;
  const _LeyendaItem({
    required this.color,
    required this.label,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final ReservaManifiesto reserva;
  final Color color;
  final List<String> asientos;
  final bool isExpanded;
  final VoidCallback onTap;

  const _ReservaCard({
    required this.reserva,
    required this.color,
    required this.asientos,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded ? color : const Color(0xFFE2E8F0),
          width: isExpanded ? 1.5 : 1,
        ),
        boxShadow: isExpanded
            ? [BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 8)]
            : null,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reserva.responsable?.nombre ?? reserva.idReserva,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${reserva.idReserva} · ${reserva.totalPersonas} pers.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Asientos chips
                  ...asientos
                      .take(3)
                      .map(
                        (a) => Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            a,
                            style: TextStyle(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  if (asientos.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '+${asientos.length - 3}',
                        style: TextStyle(fontSize: 10, color: color),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[const Divider(height: 1), _buildDetalle()],
        ],
      ),
    );
  }

  Widget _buildDetalle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PersonaTile(
            persona: reserva.responsable,
            label: 'Responsable',
            icon: Icons.person_rounded,
          ),
          ...reserva.integrantes.asMap().entries.map(
            (e) => _PersonaTile(
              persona: e.value,
              label: 'Integrante ${e.key + 1}',
              icon: Icons.person_outline_rounded,
            ),
          ),
          const SizedBox(height: 6),
          _EstadoBadge(estado: reserva.estado),
        ],
      ),
    );
  }
}

class _PersonaTile extends StatelessWidget {
  final PersonaManifiesto? persona;
  final String label;
  final IconData icon;

  const _PersonaTile({
    required this.persona,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (persona == null) return const SizedBox.shrink();
    final sinAsiento = !persona!.ocupaAsiento;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${persona!.nombre} · $label',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (sinAsiento)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.airline_seat_recline_normal_rounded,
                                size: 10, color: Color(0xFF64748B)),
                            SizedBox(width: 3),
                            Text(
                              'Sin asiento',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (persona!.documento != null)
                  Text(
                    '${persona!.tipoDocumento ?? 'DOC'}: ${persona!.documento}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                if (persona!.telefono != null)
                  Text(
                    '📞 ${persona!.telefono}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
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

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (estado) {
      'al dia' => (const Color(0xFF059669), 'Al día'),
      'cancelado' => (const Color(0xFFEF4444), 'Cancelado'),
      _ => (const Color(0xFFF59E0B), 'Pendiente'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReservaDialog extends StatelessWidget {
  final ReservaManifiesto reserva;
  final Color color;
  final String numeroAsiento;
  final VoidCallback onLiberar;
  final VoidCallback onMover;
  const _ReservaDialog({
    required this.reserva,
    required this.color,
    required this.numeroAsiento,
    required this.onLiberar,
    required this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.airline_seat_recline_normal_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reserva.idReserva,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    _EstadoBadgeWhite(estado: reserva.estado),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PersonaTile(
                  persona: reserva.responsable,
                  label: 'Responsable',
                  icon: Icons.person_rounded,
                ),
                if (reserva.integrantes.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'INTEGRANTES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...reserva.integrantes.asMap().entries.map(
                    (e) => _PersonaTile(
                      persona: e.value,
                      label: 'Integrante ${e.key + 1}',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMover,
                        icon: const Icon(Icons.open_with_rounded, size: 16),
                        label: Text('Mover asiento $numeroAsiento'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1D4ED8),
                          side: const BorderSide(color: Color(0xFF1D4ED8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onLiberar,
                      icon: const Icon(Icons.event_seat_outlined, size: 16),
                      label: const Text('Liberar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
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
}

class _EstadoBadgeWhite extends StatelessWidget {
  final String estado;
  const _EstadoBadgeWhite({required this.estado});

  @override
  Widget build(BuildContext context) {
    final label = switch (estado) {
      'al dia' => 'Al día',
      'cancelado' => 'Cancelado',
      _ => 'Pendiente',
    };
    return Text(
      label,
      style: const TextStyle(color: Colors.white70, fontSize: 11),
    );
  }
}
