import 'dart:convert';
import 'package:agente_viajes/features/cotizaciones/presentation/bloc/cotizacion_bloc.dart';
import 'package:agente_viajes/features/cotizaciones/presentation/bloc/cotizacion_event.dart';
import 'package:agente_viajes/features/cotizaciones/presentation/bloc/cotizacion_state.dart';
import 'package:agente_viajes/features/dashboard/presentation/screens/widgets/dialog_detail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../tour/domain/entities/tour.dart';
import '../../../tour/presentation/bloc/tour_bloc.dart';
import '../../../pagos_realizados/presentation/bloc/pago_realizado_bloc.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../config/app_router.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import 'package:http/http.dart' as http;

// ─── Root screen ─────────────────────────────────────────────────────────────
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 0, child: _DashboardBody());
  }
}

// ─── Body (StatefulWidget) ───────────────────────────────────────────────────
class _DashboardBody extends StatefulWidget {
  const _DashboardBody();
  @override
  State<_DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<_DashboardBody>
    with TickerProviderStateMixin {
  // ── controllers de filtrado/búsqueda ──
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();

  // ── animation controllers ──
  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _cardsOpacity;
  late final Animation<Offset> _cardsSlide;
  late final Animation<double> _floatY;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    context.read<PagoRealizadoBloc>().add(const LoadPagos());
    context.read<CotizacionBloc>().add(LoadCotizaciones());

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat(reverse: true);

    _headerOpacity = _fade(0.00, 0.35);
    _headerSlide = _slideAnim(0.00, 0.35, const Offset(0, -0.06));
    _cardsOpacity = _fade(0.20, 0.55);
    _cardsSlide = _slideAnim(0.20, 0.55, const Offset(0, 0.08));
    _floatY = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _shimmer = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();
  }

  Animation<double> _fade(double s, double e) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );

  Animation<Offset> _slideAnim(double s, double e, Offset begin) =>
      Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TourBloc, TourState>(
      builder: (context, tourState) {
        return BlocBuilder<PagoRealizadoBloc, PagoRealizadoState>(
          builder: (context, pagosState) {
            final totalActive = tourState is ToursLoaded
                ? tourState.tours.where((t) => !t.isPromotion).length
                : 0;
            final totalPromos = tourState is ToursLoaded
                ? tourState.tours.where((t) => t.isPromotion).length
                : 0;
            final pendingPagos = pagosState is PagosRealizadosLoaded
                ? pagosState.pagos.where((p) => !p.isValidated).length
                : 0;

            return SizedBox.expand(
              child: Stack(
                children: [
                  // ── Fondo animado ──────────────────────────────────────────
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_floatCtrl, _shimmerCtrl]),
                      builder: (_, child) => _DashboardBackground(
                        shimmer: _shimmer.value,
                        floatY: _floatY.value,
                      ),
                    ),
                  ),

                  // ── Contenido scrolleable ──────────────────────────────────
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        AnimatedBuilder(
                          animation: _entryCtrl,
                          builder: (_, child) => FadeTransition(
                            opacity: _headerOpacity,
                            child: SlideTransition(
                              position: _headerSlide,
                              child: const _DashboardHeader(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Stat cards
                        AnimatedBuilder(
                          animation: _entryCtrl,
                          builder: (_, child) => FadeTransition(
                            opacity: _cardsOpacity,
                            child: SlideTransition(
                              position: _cardsSlide,
                              child:
                                  BlocBuilder<CotizacionBloc, CotizacionState>(
                                    builder: (context, cotState) {
                                      final unread =
                                          cotState is CotizacionLoaded
                                          ? cotState.cotizaciones
                                                .where((c) => !c.isRead)
                                                .length
                                          : 0;
                                      return _StatsGrid(
                                        pendingPagos: pendingPagos,
                                        totalActive: totalActive,
                                        totalPromos: totalPromos,
                                        unreadCotizaciones: unread,
                                        onPagosTap: () {
                                          context.read<PagoRealizadoBloc>().add(
                                            const LoadPagos(),
                                          );
                                          Navigator.pushReplacementNamed(
                                            context,
                                            AppRouter.pagosRealizados,
                                          );
                                        },
                                        onToursTap: () {
                                          context.read<TourBloc>().add(
                                            LoadTours(),
                                          );
                                          Navigator.pushReplacementNamed(
                                            context,
                                            AppRouter.tours,
                                          );
                                        },
                                        onPromosTap: () {
                                          context.read<TourBloc>().add(
                                            LoadTours(),
                                          );
                                          Navigator.pushReplacementNamed(
                                            context,
                                            AppRouter.tours,
                                          );
                                        },
                                        onCotizacionesTap: () {
                                          context.read<CotizacionBloc>().add(
                                            LoadCotizaciones(),
                                          );
                                          Navigator.pushNamed(
                                            context,
                                            AppRouter.cotizaciones,
                                          );
                                        },
                                      );
                                    },
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Analytics section
                        const _AnalyticsSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  FONDO ANIMADO
// ═══════════════════════════════════════════════════════════════════════════════
class _DashboardBackground extends StatelessWidget {
  final double shimmer;
  final double floatY;

  const _DashboardBackground({required this.shimmer, required this.floatY});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo base
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [D.bg, Color(0xFF080F1D), Color(0xFF060C17)],
            ),
          ),
        ),

        // Patrón de puntos
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),
      ],
    );
  }
}

// ─── Dot grid painter ─────────────────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A2E45).withOpacity(0.55)
      ..strokeCap = StrokeCap.round;
    const step = 26.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter _) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  HEADER
// ═══════════════════════════════════════════════════════════════════════════════
class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.dashboard_rounded, color: Colors.white, size: 12),
              SizedBox(width: 5),
              Text(
                'PANEL DE ADMINISTRACIÓN',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Saludo
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            colors: [D.white, D.skyBlue],
          ).createShader(r),
          child: Text(
            _greeting(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Aquí tienes un resumen de Travel Tours Florencia',
          style: TextStyle(fontSize: 13, color: D.slate400, letterSpacing: 0.1),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  STATS GRID
// ═══════════════════════════════════════════════════════════════════════════════
class _StatsGrid extends StatelessWidget {
  final int pendingPagos;
  final int totalActive;
  final int totalPromos;
  final int unreadCotizaciones;
  final VoidCallback onPagosTap;
  final VoidCallback onToursTap;
  final VoidCallback onPromosTap;
  final VoidCallback onCotizacionesTap;

  const _StatsGrid({
    required this.pendingPagos,
    required this.totalActive,
    required this.totalPromos,
    required this.unreadCotizaciones,
    required this.onPagosTap,
    required this.onToursTap,
    required this.onPromosTap,
    required this.onCotizacionesTap,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCardData(
        label: 'Pagos Pendientes',
        count: pendingPagos,
        icon: Icons.payments_rounded,
        gradient: const LinearGradient(colors: [D.rose, Color(0xFFFF6B6B)]),
        accentColor: D.rose,
        onTap: onPagosTap,
        showBadge: pendingPagos > 0,
      ),
      _StatCardData(
        label: 'Tours Activos',
        count: totalActive,
        icon: Icons.tour_rounded,
        gradient: const LinearGradient(colors: [D.emerald, Color(0xFF34D399)]),
        accentColor: D.emerald,
        onTap: onToursTap,
        showBadge: false,
      ),
      _StatCardData(
        label: 'Promociones',
        count: totalPromos,
        icon: Icons.local_offer_rounded,
        gradient: LinearGradient(colors: [D.royalBlue, D.skyBlue]),
        accentColor: D.skyBlue,
        onTap: onPromosTap,
        showBadge: false,
      ),
      _StatCardData(
        label: 'Cotizaciones',
        count: unreadCotizaciones,
        icon: Icons.request_quote_rounded,
        gradient: const LinearGradient(colors: [D.indigo, Color(0xFFA78BFA)]),
        accentColor: D.indigo,
        onTap: onCotizacionesTap,
        showBadge: unreadCotizaciones > 0,
        badgeLabel: unreadCotizaciones > 0 ? 'NUEVAS' : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 600;
        if (isWide) {
          return Row(
            children: cards
                .map(
                  (d) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: d == cards.last ? 0 : 10),
                      child: _StatCard(data: d),
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _StatCard(data: cards[0])),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(data: cards[1])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _StatCard(data: cards[2])),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(data: cards[3])),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatCardData {
  final String label;
  final int count;
  final IconData icon;
  final Gradient gradient;
  final Color accentColor;
  final VoidCallback onTap;
  final bool showBadge;
  final String? badgeLabel;

  const _StatCardData({
    required this.label,
    required this.count,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.onTap,
    required this.showBadge,
    this.badgeLabel,
  });
}

class _StatCard extends StatefulWidget {
  final _StatCardData data;
  const _StatCard({required this.data});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: _hovered
            ? (Matrix4.identity()..setTranslationRaw(0, -3, 0))
            : Matrix4.identity(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: d.onTap,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _hovered ? D.surfaceHigh : D.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _hovered ? d.accentColor.withOpacity(0.4) : D.border,
                  width: 1,
                ),
                boxShadow: _hovered
                    ? [
                        BoxShadow(
                          color: d.accentColor.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Icon box
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: d.gradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(d.icon, color: Colors.white, size: 20),
                      ),
                      const Spacer(),
                      // Badge
                      if (d.showBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: d.accentColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: d.accentColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            d.badgeLabel ?? 'NUEVO',
                            style: TextStyle(
                              color: d.accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Count
                  Text(
                    d.count.toString(),
                    style: const TextStyle(
                      color: D.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    d.label,
                    style: const TextStyle(
                      color: D.slate400,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Accent bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(gradient: d.gradient),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  BUSCADOR Y FILTROS
// ═══════════════════════════════════════════════════════════════════════════════
class _SearchFilterPanel extends StatefulWidget {
  final TextEditingController searchCtrl;
  final TextEditingController minPriceCtrl;
  final TextEditingController maxPriceCtrl;
  final String searchQuery;
  final bool filtersVisible;
  final DateTimeRange? dateRange;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleFilters;
  final VoidCallback onClearSearch;
  final VoidCallback onClearFilters;
  final ValueChanged<DateTimeRange> onDateRangePicked;
  final VoidCallback onFilterChanged;

  const _SearchFilterPanel({
    required this.searchCtrl,
    required this.minPriceCtrl,
    required this.maxPriceCtrl,
    required this.searchQuery,
    required this.filtersVisible,
    required this.dateRange,
    required this.onSearchChanged,
    required this.onToggleFilters,
    required this.onClearSearch,
    required this.onClearFilters,
    required this.onDateRangePicked,
    required this.onFilterChanged,
  });

  @override
  State<_SearchFilterPanel> createState() => _SearchFilterPanelState();
}

class _SearchFilterPanelState extends State<_SearchFilterPanel> {
  final FocusNode _searchFocus = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _isFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  int get _activeFilters =>
      (widget.dateRange != null ? 1 : 0) +
      (widget.minPriceCtrl.text.isNotEmpty ? 1 : 0) +
      (widget.maxPriceCtrl.text.isNotEmpty ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Search bar ───────────────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: D.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isFocused ? D.skyBlue.withOpacity(0.7) : D.border,
              width: _isFocused ? 1.5 : 1,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: D.skyBlue.withOpacity(0.12),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Search icon with animated color
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.search_rounded,
                    key: ValueKey(_isFocused),
                    color: _isFocused ? D.skyBlue : D.slate400,
                    size: 20,
                  ),
                ),
              ),
              // Text field
              Expanded(
                child: TextField(
                  controller: widget.searchCtrl,
                  focusNode: _searchFocus,
                  onChanged: widget.onSearchChanged,
                  style: const TextStyle(
                    color: D.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    //color de fondo del input
                    fillColor: D.bg,
                    hintText: 'Buscar tours por nombre...',
                    hintStyle: TextStyle(color: D.slate400, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.searchQuery.isNotEmpty)
                    _IconBtn(
                      icon: Icons.close_rounded,
                      color: D.slate400,
                      onTap: widget.onClearSearch,
                    ),
                  _FilterToggleBtn(
                    active: widget.filtersVisible,
                    badgeCount: _activeFilters,
                    onTap: widget.onToggleFilters,
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ],
          ),
        ),

        // ── Filter panel ─────────────────────────────────────────────────────
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _FilterPanel(
            minPriceCtrl: widget.minPriceCtrl,
            maxPriceCtrl: widget.maxPriceCtrl,
            dateRange: widget.dateRange,
            activeFilters: _activeFilters,
            onClearFilters: widget.onClearFilters,
            onDateRangePicked: widget.onDateRangePicked,
            onFilterChanged: widget.onFilterChanged,
          ),
          crossFadeState: widget.filtersVisible
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 280),
          sizeCurve: Curves.easeOutCubic,
        ),
      ],
    );
  }
}

// ─── Filter toggle button ─────────────────────────────────────────────────────
class _FilterToggleBtn extends StatelessWidget {
  final bool active;
  final int badgeCount;
  final VoidCallback onTap;

  const _FilterToggleBtn({
    required this.active,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active ? D.skyBlue.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? D.skyBlue.withOpacity(0.35) : D.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.tune_rounded : Icons.tune_rounded,
              color: active ? D.skyBlue : D.slate400,
              size: 16,
            ),
            if (badgeCount > 0) ...[
              const SizedBox(width: 5),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Icon button helper ───────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ─── Filter panel ─────────────────────────────────────────────────────────────
class _FilterPanel extends StatelessWidget {
  final TextEditingController minPriceCtrl;
  final TextEditingController maxPriceCtrl;
  final DateTimeRange? dateRange;
  final int activeFilters;
  final VoidCallback onClearFilters;
  final ValueChanged<DateTimeRange> onDateRangePicked;
  final VoidCallback onFilterChanged;

  const _FilterPanel({
    required this.minPriceCtrl,
    required this.maxPriceCtrl,
    required this.dateRange,
    required this.activeFilters,
    required this.onClearFilters,
    required this.onDateRangePicked,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: D.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: D.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: D.indigo.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.filter_alt_rounded,
                    color: D.indigo,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Filtros Avanzados',
                  style: TextStyle(
                    color: D.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                if (activeFilters > 0)
                  GestureDetector(
                    onTap: onClearFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: D.rose.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: D.rose.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.close_rounded,
                            color: D.rose,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Limpiar ($activeFilters)',
                            style: const TextStyle(
                              color: D.rose,
                              fontSize: 11,
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

          // Filter inputs
          Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 560;

                // Date chip
                final dateChip = _DateRangeChip(
                  dateRange: dateRange,
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2028),
                      initialDateRange: dateRange,
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: Theme.of(
                            ctx,
                          ).colorScheme.copyWith(primary: D.skyBlue),
                        ),
                        child: child!,
                      ),
                    );
                    if (range != null) onDateRangePicked(range);
                  },
                );

                // Price range inputs
                final priceRow = _PriceRangeInputs(
                  minCtrl: minPriceCtrl,
                  maxCtrl: maxPriceCtrl,
                  onChanged: onFilterChanged,
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: dateChip),
                      const SizedBox(width: 12),
                      Expanded(flex: 6, child: priceRow),
                    ],
                  );
                }
                return Column(
                  children: [dateChip, const SizedBox(height: 10), priceRow],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Date range chip ─────────────────────────────────────────────────────────
class _DateRangeChip extends StatefulWidget {
  final DateTimeRange? dateRange;
  final VoidCallback onTap;

  const _DateRangeChip({required this.dateRange, required this.onTap});

  @override
  State<_DateRangeChip> createState() => _DateRangeChipState();
}

class _DateRangeChipState extends State<_DateRangeChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasDate = widget.dateRange != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: hasDate ? D.cyan.withOpacity(0.07) : D.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasDate
                  ? D.cyan.withOpacity(0.4)
                  : _hovered
                  ? D.slate600
                  : D.border,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: hasDate ? D.cyan : D.slate400,
                size: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rango de fechas',
                      style: TextStyle(
                        color: hasDate ? D.cyan.withOpacity(0.8) : D.slate600,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasDate
                          ? '${DateFormat('dd MMM yy').format(widget.dateRange!.start)} — ${DateFormat('dd MMM yy').format(widget.dateRange!.end)}'
                          : 'Seleccionar fechas...',
                      style: TextStyle(
                        color: hasDate ? D.white : D.slate400,
                        fontSize: 12,
                        fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: hasDate ? D.cyan : D.slate600,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Price range inputs ───────────────────────────────────────────────────────
class _PriceRangeInputs extends StatefulWidget {
  final TextEditingController minCtrl;
  final TextEditingController maxCtrl;
  final VoidCallback onChanged;

  const _PriceRangeInputs({
    required this.minCtrl,
    required this.maxCtrl,
    required this.onChanged,
  });

  @override
  State<_PriceRangeInputs> createState() => _PriceRangeInputsState();
}

class _PriceRangeInputsState extends State<_PriceRangeInputs> {
  final FocusNode _minFocus = FocusNode();
  final FocusNode _maxFocus = FocusNode();
  bool _minFocused = false;
  bool _maxFocused = false;

  @override
  void initState() {
    super.initState();
    _minFocus.addListener(
      () => setState(() => _minFocused = _minFocus.hasFocus),
    );
    _maxFocus.addListener(
      () => setState(() => _maxFocused = _maxFocus.hasFocus),
    );
  }

  @override
  void dispose() {
    _minFocus.dispose();
    _maxFocus.dispose();
    super.dispose();
  }

  Widget _priceField({
    required TextEditingController ctrl,
    required FocusNode focus,
    required bool isFocused,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: D.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFocused ? iconColor.withOpacity(0.5) : D.border,
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [BoxShadow(color: iconColor.withOpacity(0.08), blurRadius: 10)]
            : [],
      ),
      child: TextField(
        controller: ctrl,
        focusNode: focus,
        keyboardType: TextInputType.number,
        onChanged: (_) => widget.onChanged(),
        style: const TextStyle(color: D.white, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: D.slate400, fontSize: 12),
          prefixIcon: Icon(icon, color: iconColor, size: 15),
          prefixText: '\$ ',
          prefixStyle: const TextStyle(
            color: D.slate400,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rango de precio',
          style: TextStyle(
            color: D.slate600,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _priceField(
                ctrl: widget.minCtrl,
                focus: _minFocus,
                isFocused: _minFocused,
                hint: 'Mínimo',
                icon: Icons.south_rounded,
                iconColor: D.emerald,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 16,
              height: 1,
              color: D.border,
            ),
            Expanded(
              child: _priceField(
                ctrl: widget.maxCtrl,
                focus: _maxFocus,
                isFocused: _maxFocused,
                hint: 'Máximo',
                icon: Icons.north_rounded,
                iconColor: D.rose,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SLIDER SECTION (DARK)
// ═══════════════════════════════════════════════════════════════════════════════
class _DarkSliderSection extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<Tour> tours;
  final NumberFormat currencyFormat;
  final bool isLoading;
  final String emptyMessage;
  final void Function(Tour) onTourTap;

  const _DarkSliderSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.tours,
    required this.currencyFormat,
    required this.isLoading,
    required this.emptyMessage,
    required this.onTourTap,
  });

  @override
  State<_DarkSliderSection> createState() => _DarkSliderSectionState();
}

class _DarkSliderSectionState extends State<_DarkSliderSection> {
  final ScrollController _scrollCtrl = ScrollController();
  bool _canLeft = false;
  bool _canRight = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_update);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void didUpdateWidget(covariant _DarkSliderSection old) {
    super.didUpdateWidget(old);
    WidgetsBinding.instance.addPostFrameCallback((_) => _update());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _update() {
    if (!_scrollCtrl.hasClients) return;
    setState(() {
      _canLeft = _scrollCtrl.offset > 0;
      _canRight = _scrollCtrl.offset < _scrollCtrl.position.maxScrollExtent;
    });
  }

  void _scrollBy(double delta) {
    _scrollCtrl.animateTo(
      (_scrollCtrl.offset + delta).clamp(
        0.0,
        _scrollCtrl.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.accentColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: widget.accentColor.withOpacity(0.25)),
              ),
              child: Icon(widget.icon, color: widget.accentColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              widget.title,
              style: const TextStyle(
                color: D.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            if (widget.tours.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.tours.length}',
                  style: TextStyle(
                    color: widget.accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            const Spacer(),
            if (widget.tours.length > 1) ...[
              _DarkArrowBtn(
                icon: Icons.chevron_left_rounded,
                enabled: _canLeft,
                accentColor: widget.accentColor,
                onTap: () => _scrollBy(-300),
              ),
              const SizedBox(width: 6),
              _DarkArrowBtn(
                icon: Icons.chevron_right_rounded,
                enabled: _canRight,
                accentColor: widget.accentColor,
                onTap: () => _scrollBy(300),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // Content
        if (widget.isLoading)
          SizedBox(
            height: 270,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, _) => ShimmerLoading(
                child: Container(
                  width: 290,
                  decoration: BoxDecoration(
                    color: D.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          )
        else if (widget.tours.isEmpty)
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: D.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: D.border),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 36, color: D.slate600),
                  const SizedBox(height: 8),
                  Text(
                    widget.emptyMessage,
                    style: const TextStyle(color: D.slate400, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 270,
            child: ListView.separated(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              itemCount: widget.tours.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) => SizedBox(
                width: 290,
                child: _DarkTourCard(
                  tour: widget.tours[i],
                  currencyFormat: widget.currencyFormat,
                  accentColor: widget.accentColor,
                  onTap: () => widget.onTourTap(widget.tours[i]),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Arrow button (dark) ─────────────────────────────────────────────────────
class _DarkArrowBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _DarkArrowBtn({
    required this.icon,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: enabled ? accentColor.withOpacity(0.12) : D.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? accentColor.withOpacity(0.3) : D.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? accentColor : D.slate600,
          ),
        ),
      ),
    );
  }
}

// ─── Tour card (dark glassmorphism) ──────────────────────────────────────────
class _DarkTourCard extends StatefulWidget {
  final Tour tour;
  final NumberFormat currencyFormat;
  final Color accentColor;
  final VoidCallback onTap;

  const _DarkTourCard({
    required this.tour,
    required this.currencyFormat,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_DarkTourCard> createState() => _DarkTourCardState();
}

class _DarkTourCardState extends State<_DarkTourCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yy', 'es');
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          transform: _hovered
              ? (Matrix4.identity()..setTranslationRaw(0, -5, 0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: D.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? widget.accentColor.withOpacity(0.4) : D.border,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.tour.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: D.surfaceHigh,
                          child: const Icon(
                            Icons.image_rounded,
                            size: 40,
                            color: D.slate600,
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 70,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.75),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Price badge
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                widget.accentColor,
                                widget.accentColor.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: widget.accentColor.withOpacity(
                                  _hovered ? 0.25 : 0.1,
                                ),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.currencyFormat.format(widget.tour.price),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      // Badges row
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Row(
                          children: [
                            if (widget.tour.isPromotion)
                              _badge('PROMO', D.gold),
                            if (!widget.tour.isActive) ...[
                              if (widget.tour.isPromotion)
                                const SizedBox(width: 4),
                              _badge('INACTIVO', D.rose),
                            ],
                          ],
                        ),
                      ),
                      // Eye button
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: widget.onTap,
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.visibility_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tour.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: D.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${dateFormat.format(widget.tour.startDate)} — ${dateFormat.format(widget.tour.endDate)}',
                          style: const TextStyle(
                            color: D.slate400,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 12,
                              color: widget.accentColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.tour.departurePoint,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: D.slate400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.85),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ANALYTICS DATA MODELS
// ═══════════════════════════════════════════════════════════════════════════════

class _AnalyticsPago {
  final int idPago;
  final double monto;
  final String metodoPago;
  final String referencia;
  final String proveedorComercio;
  final int? reservaId;
  final DateTime fechaCreacion;

  _AnalyticsPago({
    required this.idPago,
    required this.monto,
    required this.metodoPago,
    required this.referencia,
    required this.proveedorComercio,
    this.reservaId,
    required this.fechaCreacion,
  });

  factory _AnalyticsPago.fromJson(Map<String, dynamic> j) => _AnalyticsPago(
    idPago: j['id_pago'] as int,
    monto: (j['monto'] as num).toDouble(),
    metodoPago: j['metodo_pago'] as String? ?? '',
    referencia: j['referencia'] as String? ?? '',
    proveedorComercio: j['proveedor_comercio'] as String? ?? '',
    reservaId: j['reserva_id'] as int?,
    fechaCreacion: DateTime.parse(j['fecha_creacion'] as String),
  );
}

class _AnalyticsReserva {
  final int id;
  final String idReserva;
  final String correo;
  final String estado;
  final double valorTotal;
  final int integrantesCount;
  final String? tourNombre;
  final DateTime fechaCreacion;

  _AnalyticsReserva({
    required this.id,
    required this.idReserva,
    required this.correo,
    required this.estado,
    required this.valorTotal,
    required this.integrantesCount,
    this.tourNombre,
    required this.fechaCreacion,
  });

  factory _AnalyticsReserva.fromJson(Map<String, dynamic> j) => _AnalyticsReserva(
    id: j['id'] as int,
    idReserva: j['id_reserva'] as String? ?? '',
    correo: j['correo'] as String? ?? '',
    estado: j['estado'] as String? ?? '',
    valorTotal: (j['valor_total'] as num).toDouble(),
    integrantesCount: (j['integrantes_count'] as num?)?.toInt() ?? 1,
    tourNombre: j['tour_nombre'] as String?,
    fechaCreacion: DateTime.parse(j['fecha_creacion'] as String),
  );
}

class _AnalyticsCotizacion {
  final int id;
  final String nombreCompleto;
  final String detallesPlan;
  final int numeroPasajeros;
  final String? origenDestino;
  final String estado;
  final bool isRead;
  final DateTime createdAt;

  _AnalyticsCotizacion({
    required this.id,
    required this.nombreCompleto,
    required this.detallesPlan,
    required this.numeroPasajeros,
    this.origenDestino,
    required this.estado,
    required this.isRead,
    required this.createdAt,
  });

  factory _AnalyticsCotizacion.fromJson(Map<String, dynamic> j) => _AnalyticsCotizacion(
    id: j['id'] as int,
    nombreCompleto: j['nombre_completo'] as String? ?? '',
    detallesPlan: j['detalles_plan'] as String? ?? '',
    numeroPasajeros: (j['numero_pasajeros'] as num?)?.toInt() ?? 1,
    origenDestino: j['origen_destino'] as String?,
    estado: j['estado'] as String? ?? '',
    isRead: j['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class _VueloReservaItem {
  final int id;
  final String idReserva;
  final String correo;
  final String estado;
  final double valorTotal;
  final DateTime fechaCreacion;

  _VueloReservaItem({
    required this.id,
    required this.idReserva,
    required this.correo,
    required this.estado,
    required this.valorTotal,
    required this.fechaCreacion,
  });

  factory _VueloReservaItem.fromJson(Map<String, dynamic> j) => _VueloReservaItem(
    id: j['id'] as int,
    idReserva: j['id_reserva'] as String? ?? '',
    correo: j['correo'] as String? ?? '',
    estado: j['estado'] as String? ?? '',
    valorTotal: (j['valor_total'] as num).toDouble(),
    fechaCreacion: DateTime.parse(j['fecha_creacion'] as String),
  );
}

class _AgentGroup {
  final int? agenteId;
  final String agenteNombre;
  final int totalReservas;
  final List<_VueloReservaItem> reservas;

  _AgentGroup({
    this.agenteId,
    required this.agenteNombre,
    required this.totalReservas,
    required this.reservas,
  });

  factory _AgentGroup.fromJson(Map<String, dynamic> j) => _AgentGroup(
    agenteId: j['agente_id'] as int?,
    agenteNombre: j['agente_nombre'] as String? ?? 'Sin agente',
    totalReservas: (j['total_reservas'] as num).toInt(),
    reservas: (j['reservas'] as List<dynamic>)
        .map((r) => _VueloReservaItem.fromJson(r as Map<String, dynamic>))
        .toList(),
  );
}

class _AnalyticsData {
  final String periodo;
  final int pagosTotal;
  final double pagosMontoTotal;
  final List<_AnalyticsPago> pagos;
  final int reservasTourTotal;
  final List<_AnalyticsReserva> reservasTour;
  final int cotizacionesTotal;
  final List<_AnalyticsCotizacion> cotizaciones;
  final List<_AgentGroup> vuelosPorAgente;

  _AnalyticsData({
    required this.periodo,
    required this.pagosTotal,
    required this.pagosMontoTotal,
    required this.pagos,
    required this.reservasTourTotal,
    required this.reservasTour,
    required this.cotizacionesTotal,
    required this.cotizaciones,
    required this.vuelosPorAgente,
  });

  factory _AnalyticsData.fromJson(Map<String, dynamic> j) => _AnalyticsData(
    periodo: j['periodo'] as String,
    pagosTotal: (j['pagos_validados']['total'] as num).toInt(),
    pagosMontoTotal: (j['pagos_validados']['monto_total'] as num).toDouble(),
    pagos: (j['pagos_validados']['items'] as List<dynamic>)
        .map((p) => _AnalyticsPago.fromJson(p as Map<String, dynamic>))
        .toList(),
    reservasTourTotal: (j['reservas_tour']['total'] as num).toInt(),
    reservasTour: (j['reservas_tour']['items'] as List<dynamic>)
        .map((r) => _AnalyticsReserva.fromJson(r as Map<String, dynamic>))
        .toList(),
    cotizacionesTotal: (j['cotizaciones']['total'] as num).toInt(),
    cotizaciones: (j['cotizaciones']['items'] as List<dynamic>)
        .map((c) => _AnalyticsCotizacion.fromJson(c as Map<String, dynamic>))
        .toList(),
    vuelosPorAgente: (j['vuelos_por_agente'] as List<dynamic>)
        .map((a) => _AgentGroup.fromJson(a as Map<String, dynamic>))
        .toList(),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ANALYTICS SECTION
// ═══════════════════════════════════════════════════════════════════════════════

class _AnalyticsSection extends StatefulWidget {
  const _AnalyticsSection();

  @override
  State<_AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<_AnalyticsSection> {
  String _periodo = 'mes';
  Future<_AnalyticsData>? _future;

  static const _periodos = [
    ('dia', 'Hoy'),
    ('semana', 'Semana'),
    ('mes', 'Mes'),
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    setState(() {
      _future = _loadAnalytics(_periodo);
    });
  }

  Future<_AnalyticsData> _loadAnalytics(String periodo) async {
    final client = sl<http.Client>();
    final uri = Uri.parse('${ApiConstants.kBaseUrl}/v1/analytics?periodo=$periodo');
    final response = await client.get(uri, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });
    if (response.statusCode == 200) {
      return _AnalyticsData.fromJson(json.decode(response.body) as Map<String, dynamic>);
    }
    throw Exception('Error al cargar analítica: ${response.statusCode}');
  }

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM · HH:mm', 'es');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: D.indigo.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: D.indigo.withOpacity(0.25)),
              ),
              child: const Icon(Icons.bar_chart_rounded, color: D.indigo, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Analítica',
              style: TextStyle(
                color: D.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            // Período selector
            Container(
              decoration: BoxDecoration(
                color: D.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: D.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _periodos.map((p) {
                  final selected = _periodo == p.$1;
                  return GestureDetector(
                    onTap: () {
                      if (_periodo != p.$1) {
                        _periodo = p.$1;
                        _fetch();
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? D.indigo : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        p.$2,
                        style: TextStyle(
                          color: selected ? Colors.white : D.slate400,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Content ───────────────────────────────────────────────────────────
        FutureBuilder<_AnalyticsData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ShimmerLoading(
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: D.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: D.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: D.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: D.rose, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Error al cargar datos. Toca para reintentar.',
                        style: const TextStyle(color: D.slate400, fontSize: 13),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetch,
                      child: const Text('Reintentar', style: TextStyle(color: D.indigo)),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;

            return Column(
              children: [
                // ── Summary cards ──────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.check_circle_rounded,
                        color: D.emerald,
                        label: 'Pagos validados',
                        value: '${data.pagosTotal}',
                        sub: currFmt.format(data.pagosMontoTotal),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.tour_rounded,
                        color: D.skyBlue,
                        label: 'Reservas tour',
                        value: '${data.reservasTourTotal}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryCard(
                        icon: Icons.request_quote_rounded,
                        color: D.gold,
                        label: 'Cotizaciones',
                        value: '${data.cotizacionesTotal}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Pagos validados ────────────────────────────────────────
                _AnalyticsExpansionCard(
                  icon: Icons.payments_rounded,
                  color: D.emerald,
                  title: 'Pagos validados',
                  count: data.pagosTotal,
                  emptyText: 'Sin pagos validados en este período',
                  children: data.pagos.map((p) => _PagoTile(
                    pago: p,
                    currFmt: currFmt,
                    dateFmt: dateFmt,
                  )).toList(),
                ),
                const SizedBox(height: 10),

                // ── Reservas de tour ───────────────────────────────────────
                _AnalyticsExpansionCard(
                  icon: Icons.tour_rounded,
                  color: D.skyBlue,
                  title: 'Reservas de tour',
                  count: data.reservasTourTotal,
                  emptyText: 'Sin reservas de tour en este período',
                  children: data.reservasTour.map((r) => _ReservaTourTile(
                    reserva: r,
                    currFmt: currFmt,
                    dateFmt: dateFmt,
                  )).toList(),
                ),
                const SizedBox(height: 10),

                // ── Cotizaciones ───────────────────────────────────────────
                _AnalyticsExpansionCard(
                  icon: Icons.request_quote_rounded,
                  color: D.gold,
                  title: 'Cotizaciones recibidas',
                  count: data.cotizacionesTotal,
                  emptyText: 'Sin cotizaciones en este período',
                  children: data.cotizaciones.map((c) => _CotizacionTile(
                    cot: c,
                    dateFmt: dateFmt,
                  )).toList(),
                ),
                const SizedBox(height: 10),

                // ── Vuelos por agente ──────────────────────────────────────
                if (data.vuelosPorAgente.isNotEmpty)
                  _VuelosPorAgenteCard(
                    grupos: data.vuelosPorAgente,
                    currFmt: currFmt,
                    dateFmt: dateFmt,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? sub;

  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: D.slate400, fontSize: 10, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Analytics expansion card ─────────────────────────────────────────────────
class _AnalyticsExpansionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final String emptyText;
  final List<Widget> children;

  const _AnalyticsExpansionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: D.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          title: Row(
            children: [
              Text(
                title,
                style: const TextStyle(color: D.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          iconColor: D.slate400,
          collapsedIconColor: D.slate400,
          children: count == 0
              ? [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(emptyText, style: const TextStyle(color: D.slate400, fontSize: 12)),
                  ),
                ]
              : children,
        ),
      ),
    );
  }
}

// ─── Pago tile ────────────────────────────────────────────────────────────────
class _PagoTile extends StatelessWidget {
  final _AnalyticsPago pago;
  final NumberFormat currFmt;
  final DateFormat dateFmt;

  const _PagoTile({required this.pago, required this.currFmt, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: D.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: D.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pago.proveedorComercio,
                  style: const TextStyle(color: D.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pago.metodoPago} · Ref: ${pago.referencia}',
                  style: const TextStyle(color: D.slate400, fontSize: 11),
                ),
                Text(
                  dateFmt.format(pago.fechaCreacion.toLocal()),
                  style: const TextStyle(color: D.slate400, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            currFmt.format(pago.monto),
            style: const TextStyle(color: D.emerald, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ─── Reserva tour tile ────────────────────────────────────────────────────────
class _ReservaTourTile extends StatelessWidget {
  final _AnalyticsReserva reserva;
  final NumberFormat currFmt;
  final DateFormat dateFmt;

  const _ReservaTourTile({required this.reserva, required this.currFmt, required this.dateFmt});

  Color _estadoColor(String e) {
    switch (e) {
      case 'al dia':
        return D.emerald;
      case 'cancelado':
        return D.rose;
      default:
        return D.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _estadoColor(reserva.estado);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: D.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: D.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reserva.idReserva,
                      style: const TextStyle(
                        color: D.white, fontSize: 12, fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        reserva.estado,
                        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                if (reserva.tourNombre != null)
                  Text(
                    reserva.tourNombre!,
                    style: const TextStyle(color: D.slate400, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  '${reserva.correo} · ${reserva.integrantesCount} persona${reserva.integrantesCount != 1 ? "s" : ""}',
                  style: const TextStyle(color: D.slate400, fontSize: 11),
                ),
                Text(
                  dateFmt.format(reserva.fechaCreacion.toLocal()),
                  style: const TextStyle(color: D.slate400, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            currFmt.format(reserva.valorTotal),
            style: const TextStyle(color: D.skyBlue, fontSize: 13, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

// ─── Cotizacion tile ──────────────────────────────────────────────────────────
class _CotizacionTile extends StatelessWidget {
  final _AnalyticsCotizacion cot;
  final DateFormat dateFmt;

  const _CotizacionTile({required this.cot, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: D.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cot.isRead ? D.border : D.gold.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!cot.isRead)
            Padding(
              padding: const EdgeInsets.only(top: 3, right: 6),
              child: Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: D.gold, shape: BoxShape.circle),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cot.nombreCompleto,
                  style: const TextStyle(color: D.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  cot.detallesPlan,
                  style: const TextStyle(color: D.slate400, fontSize: 11),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${cot.numeroPasajeros} pax${cot.origenDestino != null ? " · ${cot.origenDestino}" : ""} · ${dateFmt.format(cot.createdAt.toLocal())}',
                  style: const TextStyle(color: D.slate400, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vuelos por agente card ───────────────────────────────────────────────────
class _VuelosPorAgenteCard extends StatelessWidget {
  final List<_AgentGroup> grupos;
  final NumberFormat currFmt;
  final DateFormat dateFmt;

  const _VuelosPorAgenteCard({
    required this.grupos,
    required this.currFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    final total = grupos.fold(0, (sum, g) => sum + g.totalReservas);
    return Container(
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: D.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          initiallyExpanded: true,
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: D.royalBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.flight_rounded, color: D.royalBlue, size: 16),
          ),
          title: Row(
            children: [
              const Text(
                'Vuelos por agente',
                style: TextStyle(color: D.white, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: D.royalBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$total reservas',
                  style: const TextStyle(
                    color: D.royalBlue, fontSize: 11, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          iconColor: D.slate400,
          collapsedIconColor: D.slate400,
          children: grupos.map((g) => _AgentGroupTile(
            grupo: g,
            currFmt: currFmt,
            dateFmt: dateFmt,
          )).toList(),
        ),
      ),
    );
  }
}

class _AgentGroupTile extends StatelessWidget {
  final _AgentGroup grupo;
  final NumberFormat currFmt;
  final DateFormat dateFmt;

  const _AgentGroupTile({
    required this.grupo,
    required this.currFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: D.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: D.royalBlue.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: EdgeInsets.zero,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: D.royalBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                grupo.agenteNombre.isNotEmpty ? grupo.agenteNombre[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: D.royalBlue, fontSize: 14, fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          title: Text(
            grupo.agenteNombre,
            style: const TextStyle(color: D.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${grupo.totalReservas} reserva${grupo.totalReservas != 1 ? "s" : ""}',
            style: const TextStyle(color: D.slate400, fontSize: 11),
          ),
          iconColor: D.slate400,
          collapsedIconColor: D.slate400,
          children: grupo.reservas.map((r) {
            Color estadoColor;
            switch (r.estado) {
              case 'al dia':
                estadoColor = D.emerald;
                break;
              case 'cancelado':
                estadoColor = D.rose;
                break;
              default:
                estadoColor = D.gold;
            }
            return Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: D.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: D.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              r.idReserva,
                              style: const TextStyle(
                                color: D.white, fontSize: 11, fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: estadoColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                r.estado,
                                style: TextStyle(
                                  color: estadoColor, fontSize: 9, fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${r.correo} · ${dateFmt.format(r.fechaCreacion.toLocal())}',
                          style: const TextStyle(color: D.slate400, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currFmt.format(r.valorTotal),
                    style: const TextStyle(
                      color: D.royalBlue, fontSize: 12, fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Unused — kept for possible future reference from other files
// ignore: unused_element
Widget _pulsatingOrb(double size, Color color) => Container(
  width: size,
  height: size,
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: RadialGradient(colors: [color, Colors.transparent]),
  ),
);
