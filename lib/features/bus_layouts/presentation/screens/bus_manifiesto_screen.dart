import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/dialog_loading_widget.dart';
import '../../domain/entities/bus_manifiesto.dart';
import '../../domain/entities/bus_layout.dart';
import '../bloc/bus_manifiesto_bloc.dart';
import '../bloc/bus_manifiesto_event.dart';
import '../bloc/bus_manifiesto_state.dart';

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
  const BusManifiestoScreen({super.key, required this.tourId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<BusManifiestoBloc>()..add(LoadBusManifiesto(tourId)),
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
  bool _initialLoadDialogOpen = false;
  int? _tourId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialLoadDialogOpen = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const DialogLoadingNetwork(
          titel: 'Cargando manifiesto de bus...',
        ),
      ).then((_) => _initialLoadDialogOpen = false);
    });
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
        backgroundColor: SaasPalette.brand600,
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final bloc = context.read<BusManifiestoBloc>();
              final state = bloc.state;
              if (state is BusManifiestoLoaded) {
                _initialLoadDialogOpen = true;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const DialogLoadingNetwork(
                    titel: 'Cargando manifiesto de bus...',
                  ),
                ).then((_) => _initialLoadDialogOpen = false);
                bloc.add(LoadBusManifiesto(state.manifiesto.tour.id));
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<BusManifiestoBloc, BusManifiestoState>(
        listener: (context, state) {
          if (state is BusManifiestoLoaded || state is BusManifiestoError) {
            if (_initialLoadDialogOpen) {
              _initialLoadDialogOpen = false;
              Navigator.of(context, rootNavigator: true).pop();
            }
            // Cerrar diálogo de auto-asignar si estaba abierto
            if (_loadingDialogOpen) {
              _loadingDialogOpen = false;
              Navigator.of(context, rootNavigator: true).pop();
            }
          }
          if (state is BusManifiestoAsignando) {
            _loadingDialogOpen = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const DialogLoadingNetwork(
                titel: 'Asignando asientos...',
              ),
            ).then((_) => _loadingDialogOpen = false);
          } else if (state is BusManifiestoOperando) {
            _loadingDialogOpen = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const DialogLoadingNetwork(
                titel: 'Procesando operación...',
              ),
            ).then((_) => _loadingDialogOpen = false);
          } else if (state is BusManifiestoOperacionExito) {
            if (_loadingDialogOpen) {
              _loadingDialogOpen = false;
              Navigator.of(context, rootNavigator: true).pop();
            }
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
            if (_loadingDialogOpen) {
              _loadingDialogOpen = false;
              Navigator.of(context, rootNavigator: true).pop();
            }
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
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
                    onPressed: () => Navigator.of(context).pop(),
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
        if (_modoMover != null) _buildModoMoverBanner(),
        if (manifiesto.reservasSinAsientos.isNotEmpty && _modoMover == null)
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
                  backgroundColor: SaasPalette.brand600,
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
              return Chip(
                avatar: Icon(
                  sinBus ? Icons.directions_bus_outlined : Icons.event_seat_outlined,
                  size: 14,
                  color: sinBus ? Colors.red : const Color(0xFF92400E),
                ),
                label: Text(
                  '$nombre (${r.totalPersonas}p)',
                  style: const TextStyle(fontSize: 11),
                ),
                backgroundColor: sinBus
                    ? const Color(0xFFFFE4E6)
                    : const Color(0xFFFEF3C7),
                side: BorderSide.none,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
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
        indicatorColor: SaasPalette.brand600,
        tabs: buses
            .map(
              (b) => Tab(
                text: b.nombre,
                icon: const Icon(Icons.directions_bus_rounded, size: 16),
              ),
            )
            .toList(),
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
                    const TabBar(
                      labelColor: SaasPalette.brand600,
                      unselectedLabelColor: Color(0xFF64748B),
                      indicatorColor: SaasPalette.brand600,
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
    final asientosPorNumero = {for (final a in bus.asientos) a.numero: a};

    // Calcular número de filas reales desde configuración completa
    final maxFila = cfg.asientos.isEmpty
        ? 0
        : cfg.asientos.map((a) => a.fila).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              // Frontal del bus
              _BusFront(),
              const SizedBox(height: 8),
              // Filas
              ...List.generate(maxFila + 1, (filaIdx) {
                final asientosFila =
                    cfg.asientos.where((a) => a.fila == filaIdx).toList()
                      ..sort((a, b) => a.columna.compareTo(b.columna));

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: _buildFila(
                    filaIdx,
                    asientosFila,
                    asientosPorNumero,
                    bus,
                  ),
                );
              }),
              // Parte trasera
              _BusBack(),
              const SizedBox(height: 16),
              // Leyenda
              _buildLeyenda(bus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFila(
    int filaIdx,
    List<AsientoLayout> asientosFila,
    Map<String, AsientoManifiesto> asientosPorNumero,
    BusManifiestoData bus,
  ) {
    if (asientosFila.isEmpty) return const SizedBox.shrink();

    // Detectar baños en lado derecho (columna > mitad)
    final mitad = (bus.configuracion.columnas / 2).floor();
    final tieneBano = asientosFila.any(
      (a) => a.columna >= mitad && a.tipo == TipoAsiento.bano,
    );

    final izquierda = asientosFila.where((a) => a.columna < mitad).toList();
    final derecha = asientosFila
        .where((a) => a.columna >= mitad && a.tipo != TipoAsiento.bano)
        .toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Número de fila
        SizedBox(
          width: 24,
          child: Text(
            filaIdx == 0 ? '' : '$filaIdx',
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 4),
        // Asientos izquierda
        ...izquierda.map(
          (a) => _buildAsiento(a, asientosPorNumero[a.numero], bus),
        ),
        // Pasillo
        const SizedBox(width: 20),
        // Asientos derecha o baño
        if (tieneBano)
          _buildBanoCell()
        else
          ...derecha.map(
            (a) => _buildAsiento(a, asientosPorNumero[a.numero], bus),
          ),
        const SizedBox(width: 4),
        const SizedBox(width: 24),
      ],
    );
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

    final reserva = asiento?.reserva;
    final isLibre = reserva == null;
    final enModoMover = _modoMover != null && _modoMover!.busLayoutId == bus.busLayoutId;
    final isOrigen = enModoMover && _modoMover!.asientoOrigen == layout.numero;
    final isSeleccionado = _asientoSeleccionado == layout.numero;
    final isResaltado =
        reserva != null && _reservaSeleccionada == reserva.idReserva;
    final color = isOrigen
        ? Colors.orange
        : isLibre
            ? const Color(0xFFE2E8F0)
            : _colorParaReserva(reserva.idReserva, _colorCache);

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
            color: isSeleccionado || isResaltado
                ? Colors.white
                : color.withOpacity(0.5),
            width: isSeleccionado || isResaltado ? 2.5 : 1,
          ),
          boxShadow: isResaltado || isSeleccionado
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.airline_seat_recline_normal_rounded,
              size: 18,
              color: isLibre ? const Color(0xFF94A3B8) : Colors.white,
            ),
            Text(
              layout.numero,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isLibre ? const Color(0xFF64748B) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanoCell() {
    return Container(
      width: 100,
      height: 48,
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🚽', style: TextStyle(fontSize: 16)),
          Text('Baño', style: TextStyle(fontSize: 9, color: Color(0xFF16A34A))),
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
                const Icon(
                  Icons.people_rounded,
                  size: 18,
                  color: SaasPalette.brand600,
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
                separatorBuilder: (_, __) => const SizedBox(height: 8),
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

  void _cancelarModoMover() => setState(() => _modoMover = null);

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

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _TourInfoCard extends StatelessWidget {
  final TourInfoManifiesto tour;
  const _TourInfoCard({required this.tour});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'es');
    return Container(
      width: double.infinity,
      color: SaasPalette.brand600,
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
              const Icon(
                Icons.directions_bus_rounded,
                size: 16,
                color: SaasPalette.brand600,
              ),
              const SizedBox(width: 6),
              Text(
                bus.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              _StatPill(
                label: '${bus.asientosOcupados} ocupados',
                color: SaasPalette.brand600,
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
                    : SaasPalette.brand600,
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
        color: const Color(0xFFF59E0B).withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
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
            ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8)]
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
                            color: color.withOpacity(0.1),
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
                Text(
                  '${persona!.nombre} · $label',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
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
