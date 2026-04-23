import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/pago_realizado.dart';
import '../bloc/pago_realizado_bloc.dart';

class PagoRealizadoListScreen extends StatelessWidget {
  const PagoRealizadoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 9, child: _PagoRealizadoListBody());
  }
}

class _PagoRealizadoListBody extends StatefulWidget {
  const _PagoRealizadoListBody();

  @override
  State<_PagoRealizadoListBody> createState() => _PagoRealizadoListBodyState();
}

class _PagoRealizadoListBodyState extends State<_PagoRealizadoListBody> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    final currentState = context.read<PagoRealizadoBloc>().state;
    DateTime? startDate, endDate;
    if (currentState is PagosRealizadosLoaded) {
      startDate = currentState.filterStartDate;
      endDate = currentState.filterEndDate;
    }
    context.read<PagoRealizadoBloc>().add(
      LoadPagos(page: page, startDate: startDate, endDate: endDate),
    );
  }

  void _onFilterDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: SaasPalette.brand600,
              onPrimary: Colors.white,
              surface: SaasPalette.bgCanvas,
              onSurface: SaasPalette.textPrimary,
            ),
            dialogBackgroundColor: SaasPalette.bgCanvas,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedDateRange = picked);
      context.read<PagoRealizadoBloc>().add(
        LoadPagos(page: 1, startDate: picked.start, endDate: picked.end),
      );
    }
  }

  void _clearFilter() {
    setState(() => _selectedDateRange = null);
    context.read<PagoRealizadoBloc>().add(const LoadPagos(page: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocBuilder<PagoRealizadoBloc, PagoRealizadoState>(
        builder: (context, state) {
          List<PagoRealizado> pagos = [];
          if (state is PagosRealizadosLoaded) {
            pagos = state.pagos;
          } else if (state is PagoRealizadoSaving && state.pagos != null) {
            pagos = state.pagos!;
          }

          final query = _searchQuery.toLowerCase();
          final filtered = pagos
              .where(
                (p) =>
                    p.chatId.toLowerCase().contains(query) ||
                    p.referencia.toLowerCase().contains(query) ||
                    p.proveedorComercio.toLowerCase().contains(query),
              )
              .toList();

          final isLoading = state is PagoRealizadoLoading && pagos.isEmpty;

          // Group by chat_id
          final Map<String, List<PagoRealizado>> grouped = {};
          for (var p in filtered) {
            grouped.putIfAbsent(p.chatId, () => []).add(p);
          }
          final chatIds = grouped.keys.toList();

          return RefreshIndicator(
            onRefresh: () async =>
                context.read<PagoRealizadoBloc>().add(const LoadPagos(page: 1)),
            color: SaasPalette.brand600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _PagoHeader(
                      onAdd: () => Navigator.pushNamed(
                        context,
                        AppRouter.pagoRealizadoCreate,
                      ),
                    ),
                  ),
                ),

                // ── Filters & Search ────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SaasSearchField(
                          controller: _searchController,
                          hintText: 'Buscar por referencia, comercio o chat...',
                          onChanged: (v) => setState(() => _searchQuery = v),
                          onClear: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                        const SizedBox(height: 12),
                        _DateFilterBar(
                          range: _selectedDateRange,
                          onFilter: _onFilterDates,
                          onClear: _clearFilter,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Content ────────────────────────────────────────────────
                if (isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const SaasListSkeleton(),
                        childCount: 4,
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: SaasEmptyState(
                      icon: (query.isNotEmpty || _selectedDateRange != null)
                          ? Icons.search_off_rounded
                          : Icons.payments_rounded,
                      title: (query.isNotEmpty || _selectedDateRange != null)
                          ? 'Sin coincidencias'
                          : 'Historial vacío',
                      subtitle: (query.isNotEmpty || _selectedDateRange != null)
                          ? 'No encontramos pagos con los criterios actuales.'
                          : 'Los reportes de pagos registrados aparecerán aquí.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final chatId = chatIds[index];
                        final chatPagos = grouped[chatId]!;
                        return _ChatGroupCard(
                          chatId: chatId,
                          pagos: chatPagos,
                          index: index,
                        );
                      }, childCount: chatIds.length),
                    ),
                  ),

                // ── Pagination ─────────────────────────────────────────────
                if (state is PagosRealizadosLoaded && state.totalPages > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: _PaginationBar(
                        page: state.page,
                        totalPages: state.totalPages,
                        total: state.total,
                        onPageChanged: _goToPage,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _PagoHeader extends StatelessWidget {
  final VoidCallback onAdd;
  const _PagoHeader({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Finanzas', 'Pagos Recibidos']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Pagos Realizados',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Seguimiento y conciliación de comprobantes de pago.',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            SaasButton(
              label: 'Registrar Pago',
              icon: Icons.add_circle_outline_rounded,
              onPressed: onAdd,
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DATE FILTER BAR
// ─────────────────────────────────────────────────────────────────────────────
class _DateFilterBar extends StatelessWidget {
  final DateTimeRange? range;
  final VoidCallback onFilter;
  final VoidCallback onClear;

  const _DateFilterBar({
    this.range,
    required this.onFilter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy');
    return Container(
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: range != null ? SaasPalette.brand600 : SaasPalette.border,
          width: range != null ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onFilter,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(12),
                right: Radius.circular(0),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: range != null
                          ? SaasPalette.brand600
                          : SaasPalette.textTertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        range == null
                            ? 'Filtrar por rango de fechas'
                            : '${dateFormat.format(range!.start)} - ${dateFormat.format(range!.end)}',
                        style: TextStyle(
                          color: range != null
                              ? SaasPalette.textPrimary
                              : SaasPalette.textSecondary,
                          fontSize: 13,
                          fontWeight: range != null
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (range != null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: 'Limpiar fechas',
                child: GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: SaasPalette.bgSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: SaasPalette.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CHAT GROUP CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ChatGroupCard extends StatefulWidget {
  final String chatId;
  final List<PagoRealizado> pagos;
  final int index;
  const _ChatGroupCard({
    required this.chatId,
    required this.pagos,
    required this.index,
  });

  @override
  State<_ChatGroupCard> createState() => _ChatGroupCardState();
}

class _ChatGroupCardState extends State<_ChatGroupCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final total = widget.pagos.fold<double>(0, (sum, p) => sum + p.monto);
    final hasUnconfirmed = widget.pagos.any(
      (p) => !p.isValidated && !p.isRechazado,
    );
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded ? SaasPalette.brand600 : SaasPalette.border,
            width: _isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_isExpanded ? 0.08 : 0.03),
              blurRadius: _isExpanded ? 16 : 8,
              offset: Offset(0, _isExpanded ? 4 : 2),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(16),
                bottom: Radius.circular(_isExpanded ? 0 : 16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: SaasPalette.brand50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: SaasPalette.brand600,
                            size: 22,
                          ),
                        ),
                        if (hasUnconfirmed)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: SaasPalette.warning,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: SaasPalette.bgCanvas,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat: ${widget.chatId}',
                            style: const TextStyle(
                              color: SaasPalette.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${widget.pagos.length} pagos registrados',
                            style: const TextStyle(
                              color: SaasPalette.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(
                            color: SaasPalette.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          currencyFormat.format(total),
                          style: const TextStyle(
                            color: SaasPalette.success,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: SaasPalette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Column(
                children: [
                  const Divider(height: 1, color: SaasPalette.border),
                  ...widget.pagos.map((p) => _PagoItem(pago: p)),
                  const SizedBox(height: 8),
                ],
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGO ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _PagoItem extends StatelessWidget {
  final PagoRealizado pago;
  const _PagoItem({required this.pago});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    return InkWell(
      onTap: () => Navigator.pushNamed(
        context,
        AppRouter.pagoRealizadoEdit,
        arguments: pago,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: SaasPalette.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pago.proveedorComercio,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${pago.tipoDocumento} • ${pago.metodoPago}',
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Ref: ${pago.referencia}',
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(pago.monto),
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  pago.fechaDocumento,
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusBadge(pago: pago),
              ],
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right_rounded,
              color: SaasPalette.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final PagoRealizado pago;
  const _StatusBadge({required this.pago});

  @override
  Widget build(BuildContext context) {
    String label = 'Por validar';
    Color color = SaasPalette.warning;

    if (pago.isValidated) {
      label = 'Validado';
      color = SaasPalette.success;
    } else if (pago.isRechazado) {
      label = 'Rechazado';
      color = SaasPalette.danger;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGINATION BAR
// ─────────────────────────────────────────────────────────────────────────────
class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int total;
  final void Function(int) onPageChanged;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SaasPalette.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PageArrow(
              icon: Icons.chevron_left_rounded,
              enabled: page > 1,
              onTap: () => onPageChanged(page - 1),
            ),
            Column(
              children: [
                Text(
                  'Página $page de $totalPages',
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$total registros en total',
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            _PageArrow(
              icon: Icons.chevron_right_rounded,
              enabled: page < totalPages,
              onTap: () => onPageChanged(page + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon),
      color: SaasPalette.brand600,
      disabledColor: SaasPalette.textTertiary.withOpacity(0.3),
      style: IconButton.styleFrom(
        backgroundColor: enabled
            ? SaasPalette.brand50
            : SaasPalette.bgApp.withOpacity(0.5),
        padding: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
