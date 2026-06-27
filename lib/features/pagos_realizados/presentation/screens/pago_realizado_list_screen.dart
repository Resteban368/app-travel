import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_snackbar.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/pago_realizado.dart';
import '../bloc/pago_realizado_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class PagoRealizadoListScreen extends StatelessWidget {
  const PagoRealizadoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _PagoRealizadoListBody());
  }
}

class _PagoRealizadoListBody extends StatefulWidget {
  const _PagoRealizadoListBody();

  @override
  State<_PagoRealizadoListBody> createState() => _PagoRealizadoListBodyState();
}

class _PagoRealizadoListBodyState extends State<_PagoRealizadoListBody> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _debounce;
  DateTimeRange? _selectedDateRange;
  int _currentPage = 1;
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !(_debounce?.isActive ?? false)) {
      final state = context.read<PagoRealizadoBloc>().state;
      if (state is PagosRealizadosLoaded && !state.hasReachedMax) {
        _loadNextPage();
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _loadFirstPage() {
    _currentPage = 1;
    context.read<PagoRealizadoBloc>().add(
      LoadPagos(
        page: _currentPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      ),
    );
  }

  void _loadNextPage() {
    _currentPage++;
    context.read<PagoRealizadoBloc>().add(
      LoadPagos(
        page: _currentPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
      ),
    );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadFirstPage();
    });
  }

  void _onFilterDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedDateRange = picked);
      _loadFirstPage();
    }
  }

  void _clearFilter() {
    setState(() => _selectedDateRange = null);
    _loadFirstPage();
  }

  String _pagoLabel(PagoRealizado pago) {
    if (pago.proveedorComercio.isNotEmpty) return pago.proveedorComercio;
    if (pago.concepto?.isNotEmpty == true) return pago.concepto!;
    if (pago.clienteNombre?.isNotEmpty == true) return pago.clienteNombre!;
    return '\$${pago.monto.toStringAsFixed(0)}';
  }

  void _deletePressed(PagoRealizado pago) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: 'Eliminar Pago',
        body:
            '¿Deseas eliminar este pago de ${_pagoLabel(pago)}? Esta acción no se puede deshacer.',
        confirmLabel: 'Eliminar',
        onConfirm: () {
          Navigator.pop(ctx);
          setState(() => _deletingId = pago.id);
          context.read<PagoRealizadoBloc>().add(DeletePago(pago.id));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: context.saas.bgApp,
        body: BlocConsumer<PagoRealizadoBloc, PagoRealizadoState>(
          listener: (context, state) {
            if (_deletingId != null) {
              if (state is PagoRealizadoSaved) {
                setState(() => _deletingId = null);
                SaasSnackBar.showSuccess(context, 'Pago eliminado exitosamente');
              } else if (state is PagoRealizadoError) {
                setState(() => _deletingId = null);
                SaasSnackBar.showError(context, state.message);
              }
            }
          },
          builder: (context, state) {
            List<PagoRealizado> pagos = [];
            if (state is PagosRealizadosLoaded) {
              pagos = state.pagos;
            } else if (state is PagoRealizadoSaving && state.pagos != null) {
              pagos = state.pagos!;
            }

            final isLoadingFirst = state is PagoRealizadoLoading && pagos.isEmpty;

            // Group by chat_id
            final Map<String, List<PagoRealizado>> grouped = {};
            for (var p in pagos) {
              grouped.putIfAbsent(p.chatId, () => []).add(p);
            }
            final chatIds = grouped.keys.toList();

            final authState = context.watch<AuthBloc>().state;
            final canDelete = authState is AuthAuthenticated
                ? authState.user.canWrite('pagosRealizados')
                : true;

            return RefreshIndicator(
              onRefresh: () async => _loadFirstPage(),
              color: context.saas.brand600,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header ──────────────────────────────────────────────
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

                  // ── Filters & Search ─────────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SaasSearchField(
                            controller: _searchController,
                            hintText: 'Buscar por referencia, comercio o chat...',
                            onChanged: _onSearchChanged,
                            onClear: () {
                              _searchController.clear();
                              _onSearchChanged('');
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

                  // ── Content ──────────────────────────────────────────────
                  if (isLoadingFirst)
                    SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: context.saas.brand600),
                      ),
                    )
                  else if (pagos.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: SaasEmptyState(
                        icon: (_searchQuery.isNotEmpty || _selectedDateRange != null)
                            ? Icons.search_off_rounded
                            : Icons.payments_rounded,
                        title: (_searchQuery.isNotEmpty || _selectedDateRange != null)
                            ? 'Sin coincidencias'
                            : 'Historial vacío',
                        subtitle: (_searchQuery.isNotEmpty || _selectedDateRange != null)
                            ? 'No encontramos pagos con los criterios actuales.'
                            : 'Los reportes de pagos registrados aparecerán aquí.',
                      ),
                    )
                  else ...[
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
                            canDelete: canDelete,
                            onDelete: _deletePressed,
                          );
                        }, childCount: chatIds.length),
                      ),
                    ),
                    if (state is PagosRealizadosLoaded && !state.hasReachedMax)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.saas.brand600,
                            ),
                          ),
                        ),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
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
                children: [
                  Text(
                    'Pagos Realizados',
                    style: TextStyle(
                      color: context.saas.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Seguimiento y conciliación de comprobantes de pago.',
                    style: TextStyle(
                      color: context.saas.textSecondary,
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
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: range != null ? context.saas.brand600 : context.saas.border,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: range != null
                          ? context.saas.brand600
                          : context.saas.textTertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        range == null
                            ? 'Filtrar por fecha de documento'
                            : '${dateFormat.format(range!.start)} - ${dateFormat.format(range!.end)}',
                        style: TextStyle(
                          color: range != null
                              ? context.saas.textPrimary
                              : context.saas.textSecondary,
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
                      color: context.saas.bgSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: context.saas.textTertiary,
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
  final bool canDelete;
  final void Function(PagoRealizado) onDelete;
  const _ChatGroupCard({
    required this.chatId,
    required this.pagos,
    required this.index,
    required this.canDelete,
    required this.onDelete,
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
          color: context.saas.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isExpanded ? context.saas.brand600 : context.saas.border,
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
                          decoration: BoxDecoration(
                            color: context.saas.brand50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_rounded,
                            color: context.saas.brand600,
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
                                color: context.saas.warning,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: context.saas.bgCanvas,
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
                            widget.chatId,
                            style: TextStyle(
                              color: context.saas.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${widget.pagos.length} pagos registrados',
                            style: TextStyle(
                              color: context.saas.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            color: context.saas.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          currencyFormat.format(total),
                          style: TextStyle(
                            color: context.saas.success,
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
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: context.saas.textTertiary,
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
                  Divider(height: 1, color: context.saas.border),
                  ...widget.pagos.map((p) => _PagoItem(pago: p, canDelete: widget.canDelete, onDelete: widget.onDelete)),
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
  final bool canDelete;
  final void Function(PagoRealizado) onDelete;
  const _PagoItem({required this.pago, required this.canDelete, required this.onDelete});

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
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.saas.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pago.proveedorComercio.isNotEmpty
                        ? pago.proveedorComercio
                        : pago.concepto ?? pago.entidadTipo,
                    style: TextStyle(
                      color: context.saas.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${pago.tipoDocumento} • ${pago.metodoPago}',
                    style: TextStyle(
                      color: context.saas.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    'Ref: ${pago.referencia}',
                    style: TextStyle(
                      color: context.saas.textTertiary,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (pago.sedeName != null || pago.sedeId != null)
                    Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          size: 10,
                          color: context.saas.brand600,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          pago.sedeName ?? pago.sedeId!,
                          style: TextStyle(
                            color: context.saas.brand600,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFormat.format(pago.monto),
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  pago.fechaDocumento,
                  style: TextStyle(
                    color: context.saas.textTertiary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                _StatusBadge(pago: pago),
              ],
            ),
            if (canDelete) ...[
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => onDelete(pago),
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: context.saas.danger,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Eliminar pago',
              ),
            ],
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: context.saas.textTertiary,
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
    Color color = context.saas.warning;

    if (pago.isValidated) {
      label = 'Validado';
      color = context.saas.success;
    } else if (pago.isRechazado) {
      label = 'Rechazado';
      color = context.saas.danger;
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
