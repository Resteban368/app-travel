import 'package:agente_viajes/core/widgets/SmallBtn_widget.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/tour.dart';
import '../bloc/tour_bloc.dart';
import '../../../settings/domain/entities/sede.dart';
import '../../../settings/presentation/bloc/sede_bloc.dart';

class TourListScreen extends StatefulWidget {
  const TourListScreen({super.key});

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _contentOpacity;

  bool _filtersVisible = false;
  DateTimeRange? _dateRange;
  final _minPriceCtrl = TextEditingController();
  final _maxPriceCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
          ),
        );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final minPrice = double.tryParse(
      _minPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final maxPrice = double.tryParse(
      _maxPriceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    context.read<TourBloc>().add(
      FilterTours(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        minPrice: minPrice,
        maxPrice: maxPrice,
      ),
    );
    setState(() => _filtersVisible = false);
  }

  void _clearFilters() {
    _minPriceCtrl.clear();
    _maxPriceCtrl.clear();
    setState(() {
      _dateRange = null;
      _searchQuery = '';
      _searchCtrl.clear();
    });
    context.read<TourBloc>().add(LoadTours());
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentIndex: 1,
      child: Scaffold(
        backgroundColor: D.bg,
        body: Stack(
          children: [
            // Background Orbs
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, _) => Stack(
                children: [
                  Positioned(
                    top: -150 + math.sin(_bgCtrl.value * math.pi * 2) * 40,
                    right: -100 + math.cos(_bgCtrl.value * math.pi * 2) * 30,
                    child: _Orb(
                      color: D.royalBlue.withOpacity(0.12),
                      size: 500,
                    ),
                  ),
                  Positioned(
                    bottom: -100 + math.cos(_bgCtrl.value * math.pi * 2) * 50,
                    left: -50 + math.sin(_bgCtrl.value * math.pi * 2) * 40,
                    child: _Orb(color: D.indigo.withOpacity(0.08), size: 400),
                  ),
                ],
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

            BlocProvider(
              create: (_) => sl<SedeBloc>()..add(LoadSedes()),
              child: BlocBuilder<SedeBloc, SedeState>(
                builder: (context, sedeState) {
                  final sedes = sedeState is SedesLoaded
                      ? sedeState.sedes
                      : <Sede>[];
                  return BlocBuilder<TourBloc, TourState>(
                    builder: (context, state) {
                      final authState = context.watch<AuthBloc>().state;
                      final canWrite =
                          authState is AuthAuthenticated &&
                          authState.user.canWrite('tours');

                      List<Tour>? tours;
                      if (state is ToursLoaded) {
                        tours = state.filteredTours;
                      } else if (state is TourSaving && state.tours != null) {
                        tours = state.tours;
                      } else if (state is TourSaved && state.tours != null) {
                        tours = state.tours;
                      }

                      if (tours != null && _searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase();
                        tours = tours
                            .where((t) => t.name.toLowerCase().contains(query))
                            .toList();
                      }

                      return CustomScrollView(
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          // Header
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                            sliver: SliverToBoxAdapter(
                              child: FadeTransition(
                                opacity: _headerOpacity,
                                child: SlideTransition(
                                  position: _headerSlide,
                                  child: _buildHeader(context, canWrite),
                                ),
                              ),
                            ),
                          ),
                          _buildSearchBar(),
                          if (_filtersVisible) _buildFilterPanel(context),
                          SliverFadeTransition(
                            opacity: _contentOpacity,
                            sliver: _buildListContent(
                              context,
                              state,
                              tours,
                              canWrite,
                              sedes,
                            ),
                          ),
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 100),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool canWrite) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.explore_rounded, color: Colors.white, size: 10),
                  SizedBox(width: 6),
                  Text(
                    'GESTIÓN DE TOURS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Catálogo de Aventuras',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Explora y administra tours mundiales.',
              style: TextStyle(color: D.slate400, fontSize: 13),
            ),
          ],
        ),
        if (canWrite)
          _AddBtn(
            onPressed: () => Navigator.pushNamed(context, AppRouter.tourCreate),
          ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: D.surface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: D.border.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar experiencia...',
                    hintStyle: TextStyle(color: D.slate600, fontSize: 14),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: D.slate600,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _FilterToggle(
              isActive: _filtersVisible,
              onTap: () => setState(() => _filtersVisible = !_filtersVisible),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: D.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: D.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildFilterInput(
                    'Precio Mín',
                    _minPriceCtrl,
                    Icons.attach_money_rounded,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFilterInput(
                    'Precio Máx',
                    _maxPriceCtrl,
                    Icons.attach_money_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DateRangePicker(
              range: _dateRange,
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2030),
                );
                if (range != null) setState(() => _dateRange = range);
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _clearFilters,
                    child: const Text(
                      'Limpiar Todo',
                      style: TextStyle(color: D.slate400),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: D.royalBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Aplicar Filtros',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildFilterInput(
    String label,
    TextEditingController ctrl,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: D.slate600,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: D.bg.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: D.border),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '\$',
              hintStyle: TextStyle(color: D.slate800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListContent(
    BuildContext context,
    TourState state,
    List<Tour>? tours,
    bool canWrite,
    List<Sede> sedes,
  ) {
    if (state is TourLoading && tours == null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _SkelCard(),
          childCount: 3,
        ),
      );
    }
    if (tours == null || tours.isEmpty) {
      return SliverFillRemaining(
        child: _EmptyState(
          isSearch: _searchQuery.isNotEmpty || _dateRange != null,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final tour = tours[index];
          return _TourCard(
            tour: tour,
            canWrite: canWrite,
            index: index,
            currencyFormat: _currencyFormat,
            sedes: sedes,
          );
        }, childCount: tours.length),
      ),
    );
  }
}

class _TourCard extends StatefulWidget {
  final Tour tour;
  final bool canWrite;
  final int index;
  final NumberFormat currencyFormat;
  final List<Sede> sedes;
  const _TourCard({
    required this.tour,
    required this.canWrite,
    required this.index,
    required this.currencyFormat,
    required this.sedes,
  });

  @override
  State<_TourCard> createState() => _TourCardState();
}

class _TourCardState extends State<_TourCard> {
  bool _hovered = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumConfirmDialog(
        title: '¿Eliminar Experiencia?',
        content:
            'Confirma si deseas eliminar "${widget.tour.name}". Esta acción no se puede deshacer.',
        onConfirm: () {
          context.read<TourBloc>().add(DeleteTour(widget.tour.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final isActive = tour.isActive && !tour.isDraft;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isActive ? D.surface : D.surface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _hovered ? D.royalBlue.withOpacity(0.5) : D.border,
            width: 1.5,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: D.royalBlue.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, AppRouter.tourEdit, arguments: tour),
          borderRadius: BorderRadius.circular(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Header
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(color: D.bg),
                      child: Image.network(
                        tour.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: D.slate800,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _Tag(
                      label: tour.isPromotion ? 'PROMO' : 'TOUR',
                      color: tour.isPromotion ? D.gold : D.royalBlue,
                    ),
                  ),
                  if (tour.isDraft)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _Tag(label: 'BORRADOR', color: D.rose),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [D.surface, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: D.royalBlue,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 10),
                        ],
                      ),
                      child: Text(
                        widget.currencyFormat.format(tour.price),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
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
                    Text(
                      tour.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      text:
                          '${DateFormat('MMM dd').format(tour.startDate)} - ${DateFormat('MMM dd, yyyy').format(tour.endDate)}',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.place_rounded,
                      text: 'Salida: ${tour.departurePoint}',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.business_rounded,
                      text: () {
                        if (tour.sedeId == null) return 'Sin sede asignada';
                        final sede = widget.sedes
                            .where((s) => s.id == tour.sedeId)
                            .firstOrNull;
                        return sede != null
                            ? 'Sede: ${sede.nombreSede}'
                            : 'Sede #${tour.sedeId}';
                      }(),
                    ),
                    if (tour.cuposDisponibles != null || tour.cupos != null) ...[
                      const SizedBox(height: 8),
                      _CuposRow(
                        cuposDisponibles: tour.cuposDisponibles,
                        cupos: tour.cupos,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _InclusionsStrip(items: tour.inclusions),
                        ),
                        if (widget.canWrite) _buildAdminActions(context),
                      ],
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

  Widget _buildAdminActions(BuildContext context) {
    return SmallBtn(
      icon: Icons.delete_outline_rounded,
      color: D.rose,
      onTap: () => _confirmDelete(context),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
    ),
    child: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: D.slate600, size: 14),
      const SizedBox(width: 8),
      Expanded(
        child: Text(text, style: TextStyle(color: D.slate400, fontSize: 13)),
      ),
    ],
  );
}

class _CuposRow extends StatelessWidget {
  final int? cuposDisponibles;
  final int? cupos;
  const _CuposRow({this.cuposDisponibles, this.cupos});

  @override
  Widget build(BuildContext context) {
    final disponibles = cuposDisponibles ?? 0;
    final total = cupos;

    Color indicatorColor;
    if (disponibles == 0) {
      indicatorColor = D.rose;
    } else if (total != null && disponibles <= total * 0.2) {
      indicatorColor = D.gold;
    } else {
      indicatorColor = const Color(0xFF34D399);
    }

    final label = total != null
        ? '$disponibles / $total cupos disponibles'
        : '$disponibles cupos disponibles';

    return Row(
      children: [
        Icon(Icons.people_alt_rounded, color: D.slate600, size: 14),
        const SizedBox(width: 8),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: indicatorColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(color: D.slate400, fontSize: 13),
        ),
      ],
    );
  }
}

class _InclusionsStrip extends StatelessWidget {
  final List<String> items;
  const _InclusionsStrip({required this.items});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 30,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: math.min(items.length, 3),
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: D.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: D.border),
        ),
        alignment: Alignment.center,
        child: Text(
          items[i],
          style: TextStyle(color: D.slate400, fontSize: 11),
        ),
      ),
    ),
  );
}

class _FilterToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onTap;
  const _FilterToggle({required this.isActive, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? D.royalBlue : D.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? D.royalBlue : D.border),
      ),
      child: Icon(
        isActive ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
        color: isActive ? Colors.white : D.slate600,
        size: 24,
      ),
    ),
  );
}

class _DateRangePicker extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onTap;
  const _DateRangePicker({required this.range, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: D.bg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: D.border),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, color: D.slate600, size: 20),
          const SizedBox(width: 12),
          Text(
            range == null
                ? 'Cualquier Fecha'
                : '${DateFormat('dd/MM/yyyy').format(range!.start)} - ${DateFormat('dd/MM/yyyy').format(range!.end)}',
            style: TextStyle(color: range == null ? D.slate600 : Colors.white),
          ),
          const Spacer(),
          Icon(Icons.expand_more_rounded, color: D.slate600),
        ],
      ),
    ),
  );
}

class _AddBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [D.royalBlue, D.indigo]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: D.royalBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = D.border.withOpacity(0.3);
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

class _SkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 300,
    margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
    decoration: BoxDecoration(
      color: D.surface.withOpacity(0.5),
      borderRadius: BorderRadius.circular(28),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({required this.isSearch});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSearch ? Icons.search_off_rounded : Icons.tour_rounded,
          size: 80,
          color: D.slate800,
        ),
        const SizedBox(height: 16),
        Text(
          isSearch
              ? 'No hay tours bajo esos filtros'
              : 'Aún no hay tours registrados',
          style: TextStyle(
            color: D.slate600,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _PremiumConfirmDialog extends StatelessWidget {
  final String title, content;
  final VoidCallback onConfirm;
  const _PremiumConfirmDialog({
    required this.title,
    required this.content,
    required this.onConfirm,
  });
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: D.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: D.rose, size: 54),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(color: D.slate400, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: D.slate400),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: D.rose,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
