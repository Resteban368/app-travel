import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/tour.dart';
import '../bloc/tour_bloc.dart';

class TourListScreen extends StatefulWidget {
  const TourListScreen({super.key});

  @override
  State<TourListScreen> createState() => _TourListScreenState();
}

class _TourListScreenState extends State<TourListScreen> {
  bool _filtersVisible = false;
  DateTimeRange? _dateRange;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _activeTab = 'Todos'; // Todos, Tours, Promos
  final _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() => _filtersVisible = false);
    context.read<TourBloc>().add(
      FilterTours(startDate: _dateRange?.start, endDate: _dateRange?.end),
    );
  }

  void _clearFilters() {
    setState(() {
      _dateRange = null;
      _searchQuery = '';
      _searchCtrl.clear();
      _filtersVisible = false;
    });
    context.read<TourBloc>().add(LoadTours());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;

    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocBuilder<TourBloc, TourState>(
        builder: (context, state) {
          final authState = context.watch<AuthBloc>().state;
          final canWrite =
              authState is AuthAuthenticated &&
              authState.user.hasPermission('tours');

          List<Tour>? tours;
          if (state is ToursLoaded) {
            tours = state.filteredTours;
          } else if (state is TourSaving && state.tours != null) {
            tours = state.tours;
          } else if (state is TourSaved && state.tours != null) {
            tours = state.tours;
          }

          if (tours != null) {
            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              tours = tours
                  .where((t) => t.name.toLowerCase().contains(query))
                  .toList();
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
                  child: _buildModernHeader(context, canWrite, width),
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
                  child: _buildSearchAndFilterTabs(width),
                ),
              ),
              if (_filtersVisible)
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 32 : 16,
                  ),
                  sliver: SliverToBoxAdapter(child: _buildFilterPanel(context)),
                ),
              _buildListGridContent(context, state, tours, canWrite, isDesktop),
              const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, bool canWrite, double width) {
    final isTab = width < 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(
          items: ['Inicio', 'Gestión de Tours', 'Catálogo'],
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
                    'Catálogo de aventuras',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Explora y administra los tours mundiales disponibles para tus clientes.',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SaasButton(
                  label: isTab ? '' : 'Filtros',
                  icon: Icons.filter_list_rounded,
                  isPrimary: false,
                  onPressed: () =>
                      setState(() => _filtersVisible = !_filtersVisible),
                ),
                const SizedBox(width: 12),
                if (canWrite)
                  SaasButton(
                    label: isTab ? '' : 'Nuevo tour',
                    icon: Icons.add,
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRouter.tourCreate),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterTabs(double width) {
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
              const Icon(
                Icons.search,
                size: 18,
                color: SaasPalette.textTertiary,
              ),
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
                    hintText: 'Buscar experiencia...',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? SaasPalette.bgCanvas
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
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
                firstDate: DateTime(2023),
                lastDate: DateTime(2030),
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
                        : '${DateFormat('dd/MM').format(_dateRange!.start)} - ${DateFormat('dd/MM').format(_dateRange!.end)}',
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

  Widget _buildListGridContent(
    BuildContext context,
    TourState state,
    List<Tour>? tours,
    bool canWrite,
    bool isDesktop,
  ) {
    if (state is TourLoading && tours == null) {
      return SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _SkelCard(),
            childCount: 5,
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
          (context, index) => _TourRow(
            tour: tours[index],
            canWrite: canWrite,
            currencyFormat: _currencyFormat,
          ),
          childCount: tours.length,
        ),
      ),
    );
  }
}

class _TourRow extends StatefulWidget {
  final Tour tour;
  final bool canWrite;
  final NumberFormat currencyFormat;
  const _TourRow({
    required this.tour,
    required this.canWrite,
    required this.currencyFormat,
  });

  @override
  State<_TourRow> createState() => _TourRowState();
}

class _TourRowState extends State<_TourRow> {
  bool _hovered = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _SaaSConfirmDialog(
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
              color: Colors.black.withOpacity(_hovered ? 0.07 : 0.03),
              blurRadius: _hovered ? 16 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: InkWell(
          onTap: () =>
              Navigator.pushNamed(context, AppRouter.tourEdit, arguments: tour),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPromo ? Icons.local_offer_rounded : Icons.map_outlined,
                    color: typeText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Main info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + badges
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: SaasPalette.bgSubtle,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#TT-${tour.idTour}',
                              style: const TextStyle(
                                color: SaasPalette.textTertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Dates + location
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 12,
                            color: SaasPalette.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${DateFormat('dd MMM').format(tour.startDate)} — ${DateFormat('dd MMM yyyy').format(tour.endDate)}',
                            style: const TextStyle(
                              color: SaasPalette.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: SaasPalette.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              tour.departurePoint,
                              style: const TextStyle(
                                color: SaasPalette.textSecondary,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 5,
                                backgroundColor: SaasPalette.bgSubtle,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  progress > 0.8
                                      ? SaasPalette.warning
                                      : SaasPalette.brand600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$ocupados/$total cupos',
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
                const SizedBox(width: 16),

                // Price
                Text(
                  widget.currencyFormat.format(tour.price),
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),

                // Actions
                if (widget.canWrite)
                  InkWell(
                    onTap: () => _confirmDelete(context),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: SaasPalette.danger,
                        size: 18,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SaasPalette.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
          size: 64,
          color: SaasPalette.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          isSearch
              ? 'No se encontraron resultados'
              : 'No hay tours disponibles',
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
              : 'Pronto tendremos nuevas aventuras para ti.',
          style: const TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    ),
  );
}

class _SaaSConfirmDialog extends StatelessWidget {
  final String title, content;
  final VoidCallback onConfirm;
  const _SaaSConfirmDialog({
    required this.title,
    required this.content,
    required this.onConfirm,
  });
  @override
  Widget build(BuildContext context) => Dialog(
    elevation: 0,
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 400),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: SaasPalette.danger.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: SaasPalette.danger,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: SaasPalette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: SaasPalette.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: SaasPalette.textTertiary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SaasButton(label: 'Eliminar', onPressed: onConfirm),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
