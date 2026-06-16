import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_snackbar.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/tour.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/tour_bloc.dart';
import '../bloc/tour_historico_bloc.dart';

class TourHistoricoScreen extends StatefulWidget {
  const TourHistoricoScreen({super.key});

  @override
  State<TourHistoricoScreen> createState() => _TourHistoricoScreenState();
}

class _TourHistoricoScreenState extends State<TourHistoricoScreen> {
  bool _filtersVisible = false;
  DateTimeRange? _dateRange;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _activeTab = 'Todos';
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final bloc = context.read<TourHistoricoBloc>();
    if (bloc.state is TourHistoricoInitial) {
      bloc.add(LoadToursHistoricos());
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() => _filtersVisible = false);
    context.read<TourHistoricoBloc>().add(
      FilterToursHistoricos(
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _searchQuery = '';
      _searchCtrl.clear();
      _filtersVisible = false;
    });
    context.read<TourHistoricoBloc>().add(LoadToursHistoricos());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final authState = context.watch<AuthBloc>().state;
    final canWrite = authState is AuthAuthenticated
        ? authState.user.canWrite('historico_tours')
        : false;

    return BlocListener<TourBloc, TourState>(
      listener: (context, state) {
        if (state is TourDuplicado) {
          SaasSnackBar.showSuccess(context, 'Tour duplicado exitosamente');
          context.read<TourHistoricoBloc>().add(LoadToursHistoricos());
        } else if (state is TourError) {
          SaasSnackBar.showError(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: SaasPalette.bgApp,
        body: BlocBuilder<TourHistoricoBloc, TourHistoricoState>(
          builder: (context, state) {
            List<Tour>? tours;
            if (state is ToursHistoricosLoaded) {
              tours = state.filteredTours;
            }

            if (tours != null) {
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                tours = tours.where((t) => t.name.toLowerCase().contains(query)).toList();
              }
              if (_activeTab == 'Tours') {
                tours = tours.where((t) => !t.isPromotion).toList();
              } else if (_activeTab == 'Promos') {
                tours = tours.where((t) => t.isPromotion).toList();
              }
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 16,
                    32,
                    isDesktop ? 32 : 16,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildHeader(context, width),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isDesktop ? 32 : 16,
                    24,
                    isDesktop ? 32 : 16,
                    16,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _buildSearchAndTabs(width),
                  ),
                ),
                if (_filtersVisible)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
                    sliver: SliverToBoxAdapter(child: _buildFilterPanel(context)),
                  ),
                _buildContent(context, state, tours, isDesktop, canWrite),
                const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double width) {
    final isTab = width < 900;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(
          items: ['Inicio', 'Gestión de Tours', 'Histórico'],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Histórico de tours',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Registro de tours y promociones finalizados.',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            SaasButton(
              label: isTab ? '' : 'Filtros',
              icon: Icons.filter_list_rounded,
              isPrimary: false,
              onPressed: () => setState(() => _filtersVisible = !_filtersVisible),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndTabs(double width) {
    final isMobile = width < 650;

    final content = [
      Expanded(
        flex: isMobile ? 0 : 1,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: SaasPalette.border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.search, size: 18, color: SaasPalette.textTertiary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nombre...',
                    hintStyle: TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      if (isMobile) const SizedBox(height: 12),
      Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SaasPalette.bgSubtle,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: isMobile ? MainAxisSize.max : MainAxisSize.min,
          children: ['Todos', 'Tours', 'Promos'].map((tab) {
            final isSelected = _activeTab == tab;
            return Expanded(
              flex: isMobile ? 1 : 0,
              child: GestureDetector(
                onTap: () => setState(() => _activeTab = tab),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? SaasPalette.bgCanvas : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isSelected
                          ? SaasPalette.textPrimary
                          : SaasPalette.textTertiary,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content.map((e) => e is Expanded ? e.child : e).toList(),
      );
    }
    return Row(children: content);
  }

  Widget _buildFilterPanel(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por fecha',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SaasPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (range != null) setState(() => _dateRange = range);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: SaasPalette.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: SaasPalette.textTertiary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _dateRange == null
                        ? 'Seleccionar rango'
                        : '${DateFormat('dd/MM/yyyy').format(_dateRange!.start)} — ${DateFormat('dd/MM/yyyy').format(_dateRange!.end)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: SaasPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Limpiar'),
              ),
              const SizedBox(width: 12),
              SaasButton(label: 'Aplicar', onPressed: _applyFilters),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    TourHistoricoState state,
    List<Tour>? tours,
    bool isDesktop,
    bool canWrite,
  ) {
    if (state is TourHistoricoLoading && tours == null) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, _i) => _SkelCard(),
            childCount: 5,
          ),
        ),
      );
    }

    if (state is TourHistoricoError && tours == null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: SaasPalette.danger,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error al cargar el histórico',
                style: TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SaasPalette.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
              SaasButton(
                label: 'Reintentar',
                icon: Icons.refresh_rounded,
                onPressed: () =>
                    context.read<TourHistoricoBloc>().add(LoadToursHistoricos()),
              ),
            ],
          ),
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
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : 16,
        4,
        isDesktop ? 32 : 16,
        10,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _TourHistoricoRow(
            tour: tours[index],
            currencyFormat: _currencyFormat,
            canWrite: canWrite,
          ),
          childCount: tours.length,
        ),
      ),
    );
  }
}

// ─── Tour Row ────────────────────────────────────────────

class _TourHistoricoRow extends StatefulWidget {
  final Tour tour;
  final NumberFormat currencyFormat;
  final bool canWrite;

  const _TourHistoricoRow({
    required this.tour,
    required this.currencyFormat,
    required this.canWrite,
  });

  @override
  State<_TourHistoricoRow> createState() => _TourHistoricoRowState();
}

class _TourHistoricoRowState extends State<_TourHistoricoRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tour = widget.tour;
    final isPromo = tour.isPromotion;

    final Color typeColor = isPromo
        ? SaasPalette.warning.withValues(alpha: 0.12)
        : SaasPalette.brand50;
    final Color typeText = isPromo ? SaasPalette.warning : SaasPalette.brand600;

    final ocupados = (tour.cupos ?? 0) - (tour.cuposDisponibles ?? 0);
    final total = tour.cupos ?? 1;
    final double progress = (ocupados / total).clamp(0.0, 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered ? SaasPalette.brand600 : SaasPalette.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _hovered ? 0.07 : 0.03),
              blurRadius: _hovered ? 16 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          onTap: () async {
            final bloc = context.read<TourHistoricoBloc>();
            await Navigator.pushNamed(
              context,
              AppRouter.tourHistoricoDetalle,
              arguments: tour,
            );
            bloc.add(LoadToursHistoricos());
          },
          borderRadius: BorderRadius.circular(14),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: isNarrow
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    // Ícono tipo
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: typeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isPromo
                            ? Icons.local_offer_rounded
                            : Icons.map_outlined,
                        color: typeText,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Contenido principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nombre + badge
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  tour.name,
                                  style: const TextStyle(
                                    color: SaasPalette.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  isPromo ? 'PROMO' : 'TOUR',
                                  style: TextStyle(
                                    color: typeText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Badge "FINALIZADO"
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: SaasPalette.textTertiary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Text(
                                  'FINALIZADO',
                                  style: TextStyle(
                                    color: SaasPalette.textTertiary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Fechas + ubicación
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 12,
                            runSpacing: 4,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Icon(
                                        Icons.calendar_today_outlined,
                                        size: 12,
                                        color: SaasPalette.textTertiary,
                                      ),
                                    ),
                                    const WidgetSpan(child: SizedBox(width: 4)),
                                    TextSpan(
                                      text: tour.startDate != null && tour.endDate != null
                                          ? '${DateFormat('dd MMM').format(tour.startDate!)} — ${DateFormat('dd MMM yyyy').format(tour.endDate!)}'
                                          : 'Fecha no disponible',
                                      style: const TextStyle(
                                        color: SaasPalette.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Icon(
                                        Icons.location_on_outlined,
                                        size: 12,
                                        color: SaasPalette.textTertiary,
                                      ),
                                    ),
                                    const WidgetSpan(child: SizedBox(width: 4)),
                                    TextSpan(
                                      text: tour.departurePoint,
                                      style: const TextStyle(
                                        color: SaasPalette.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (isNarrow) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  widget.currencyFormat.format(tour.price),
                                  style: const TextStyle(
                                    color: SaasPalette.brand600,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: SaasPalette.textTertiary,
                                  size: 20,
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 8),
                          // Barra de ocupación
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 5,
                                    backgroundColor: SaasPalette.bgSubtle,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      SaasPalette.textTertiary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '$ocupados/${tour.cupos ?? 0} cupos',
                                style: const TextStyle(
                                  color: SaasPalette.textTertiary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (!isNarrow) ...[
                      const SizedBox(width: 16),
                      Text(
                        widget.currencyFormat.format(tour.price),
                        style: const TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (widget.canWrite)
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert_rounded,
                          color: SaasPalette.textTertiary,
                          size: 20,
                        ),
                        color: SaasPalette.bgCanvas,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'duplicate') {
                            context.read<TourBloc>().add(DuplicarTour(tour.id));
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 16, color: SaasPalette.brand600),
                                SizedBox(width: 8),
                                Text('Duplicar', style: TextStyle(color: SaasPalette.textPrimary)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else if (!isNarrow)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: SaasPalette.textTertiary,
                        size: 20,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────

class _SkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 120,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: SaasPalette.bgCanvas,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SaasPalette.border),
    ),
  );
}

// ─── Empty State ─────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({required this.isSearch});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSearch ? Icons.search_off_rounded : Icons.history_rounded,
          size: 64,
          color: SaasPalette.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          isSearch
              ? 'No se encontraron resultados'
              : 'No hay tours en el histórico',
          style: const TextStyle(
            color: SaasPalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isSearch
              ? 'Intenta con otros términos o filtros.'
              : 'Los tours finalizados aparecerán aquí.',
          style: const TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}
