import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/saldo_pendiente_bloc.dart';
import '../../domain/entities/saldo_pendiente.dart';

String _formatFecha(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  try {
    final dt = DateTime.parse(raw).toLocal();
    return DateFormat('dd/MM/yyyy', 'es_CO').format(dt);
  } catch (_) {
    return raw;
  }
}

class SaldoPendienteScreen extends StatefulWidget {
  const SaldoPendienteScreen({super.key});

  @override
  State<SaldoPendienteScreen> createState() => _SaldoPendienteScreenState();
}

class _SaldoPendienteScreenState extends State<SaldoPendienteScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  final _currFmt = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    context.read<SaldoPendienteBloc>().add(const LoadSaldosPendientes());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SaldoPendienteBloc>().add(const LoadMoreSaldosPendientes());
    }
  }

  void _onSearch(String value) {
    final state = context.read<SaldoPendienteBloc>().state;
    bool sinRec = false;
    if (state is SaldoPendienteLoaded) {
      sinRec = state.sinRecordatorioReciente;
    }

    context.read<SaldoPendienteBloc>().add(
      LoadSaldosPendientes(
        responsable: value.trim().isEmpty ? null : value.trim(),
        sinRecordatorioReciente: sinRec,
      ),
    );
  }

  void _refresh() {
    _searchController.clear();
    context.read<SaldoPendienteBloc>().add(const LoadSaldosPendientes());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: Column(
        children: [
          _Header(
            searchController: _searchController,
            onSearch: _onSearch,
            onRefresh: _refresh,
          ),
          Expanded(
            child: BlocConsumer<SaldoPendienteBloc, SaldoPendienteState>(
              listenWhen: (_, s) =>
                  s is RecordatorioEnviado || s is RecordatorioFallido,
              listener: (context, state) {
                if (state is RecordatorioEnviado) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Recordatorio enviado a ${state.result.responsable} (${state.result.telefono})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: SaasPalette.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } else if (state is RecordatorioFallido) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              state.message,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: SaasPalette.danger,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is SaldoPendienteLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: SaasPalette.brand600,
                    ),
                  );
                }

                if (state is SaldoPendienteError) {
                  return _ErrorView(message: state.message, onRetry: _refresh);
                }

                SaldoPendienteLoaded? loaded;
                bool isLoadingMore = false;
                if (state is SaldoPendienteLoaded) loaded = state;
                if (state is SaldoPendienteLoadingMore) {
                  loaded = state.previous;
                  isLoadingMore = true;
                }
                if (state is RecordatorioEnviando) loaded = state.previous;
                if (state is RecordatorioEnviado) loaded = state.previous;
                if (state is RecordatorioFallido) loaded = state.previous;

                if (loaded == null) return const SizedBox();

                if (loaded.tours.isEmpty) {
                  return _EmptyView(onRefresh: _refresh);
                }

                return _Body(
                  loaded: loaded,
                  isLoadingMore: isLoadingMore,
                  scrollController: _scrollController,
                  currFmt: _currFmt,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final TextEditingController searchController;
  final ValueChanged<String> onSearch;
  final VoidCallback onRefresh;

  const _Header({
    required this.searchController,
    required this.onSearch,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SaasPalette.bgCanvas,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SaasPalette.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: SaasPalette.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Saldos Pendientes',
                style: TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              BlocBuilder<SaldoPendienteBloc, SaldoPendienteState>(
                builder: (context, state) {
                  int totalTours = 0;
                  if (state is SaldoPendienteLoaded) {
                    totalTours = state.totalTours;
                  } else if (state is SaldoPendienteLoadingMore) {
                    totalTours = state.previous.totalTours;
                  }
                  if (totalTours == 0) return const SizedBox();
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: SaasPalette.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$totalTours tour${totalTours != 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: SaasPalette.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                color: SaasPalette.textSecondary,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Search bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: SaasPalette.bgApp,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SaasPalette.border),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.search_rounded,
                    size: 18,
                    color: SaasPalette.textTertiary,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearch,
                    decoration: const InputDecoration(
                      hintText: 'Buscar por responsable o documento…',
                      hintStyle: TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Filters row
          BlocBuilder<SaldoPendienteBloc, SaldoPendienteState>(
            builder: (context, state) {
              bool active = false;
              if (state is SaldoPendienteLoaded) {
                active = state.sinRecordatorioReciente;
              } else if (state is SaldoPendienteLoadingMore) {
                active = state.previous.sinRecordatorioReciente;
              } else if (state is RecordatorioEnviando) {
                active = state.previous.sinRecordatorioReciente;
              } else if (state is RecordatorioEnviado) {
                active = state.previous.sinRecordatorioReciente;
              } else if (state is RecordatorioFallido) {
                active = state.previous.sinRecordatorioReciente;
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text(
                        'Sin recordatorio reciente',
                        style: TextStyle(fontSize: 12),
                      ),
                      selected: active,
                      onSelected: (val) {
                        final bloc = context.read<SaldoPendienteBloc>();
                        String? tourId;
                        String? resp;
                        String? idRes;

                        if (state is SaldoPendienteLoaded) {
                          tourId = state.filterTourId;
                          resp = state.filterResponsable;
                          idRes = state.filterIdReserva;
                        }

                        bloc.add(
                          LoadSaldosPendientes(
                            tourId: tourId,
                            responsable: resp,
                            idReserva: idRes,
                            sinRecordatorioReciente: val,
                          ),
                        );
                      },
                      selectedColor: SaasPalette.warning.withValues(alpha: 0.2),
                      checkmarkColor: SaasPalette.warning,
                      labelStyle: TextStyle(
                        color: active
                            ? SaasPalette.warning
                            : SaasPalette.textSecondary,
                        fontWeight: active
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      backgroundColor: SaasPalette.bgApp,
                      side: BorderSide(
                        color: active
                            ? SaasPalette.warning
                            : SaasPalette.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final SaldoPendienteLoaded loaded;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final NumberFormat currFmt;

  const _Body({
    required this.loaded,
    required this.isLoadingMore,
    required this.scrollController,
    required this.currFmt,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      itemCount: loaded.tours.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == loaded.tours.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CircularProgressIndicator(color: SaasPalette.brand600),
            ),
          );
        }
        return _TourGroup(
          tour: loaded.tours[index],
          currFmt: currFmt,
        );
      },
    );
  }
}

// ── Grupo por Tour ────────────────────────────────────────────────────────────

class _TourGroup extends StatefulWidget {
  final TourConSaldo tour;
  final NumberFormat currFmt;

  const _TourGroup({
    required this.tour,
    required this.currFmt,
  });

  @override
  State<_TourGroup> createState() => _TourGroupState();
}

class _TourGroupState extends State<_TourGroup> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final fmt = widget.currFmt;
    final tour = widget.tour;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        children: [
          // ── Tour header ────────────────────────────────────────────────
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: SaasPalette.brand600.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tour_rounded,
                      color: SaasPalette.brand600,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tour.tourNombre,
                      style: const TextStyle(
                        color: SaasPalette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  // Total saldo del tour (from API)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.format(tour.saldoTotalTour),
                        style: const TextStyle(
                          color: SaasPalette.danger,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${tour.totalReservas} reserva${tour.totalReservas != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: SaasPalette.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: SaasPalette.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(color: SaasPalette.border, height: 1),
            ...tour.reservas.asMap().entries.map((entry) {
              final i = entry.key;
              final reserva = entry.value;
              return Column(
                children: [
                  _ReservaCard(reserva: reserva, currFmt: fmt),
                  if (i < tour.reservas.length - 1)
                    const Divider(
                      color: SaasPalette.border,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

// ── Tarjeta de Reserva ────────────────────────────────────────────────────────

class _ReservaCard extends StatefulWidget {
  final SaldoPendiente reserva;
  final NumberFormat currFmt;

  const _ReservaCard({required this.reserva, required this.currFmt});

  @override
  State<_ReservaCard> createState() => _ReservaCardState();
}

class _ReservaCardState extends State<_ReservaCard> {
  bool _pagosExpanded = false;

  @override
  Widget build(BuildContext context) {
    final reserva = widget.reserva;
    final currFmt = widget.currFmt;
    final pct = reserva.valorTotal > 0
        ? (reserva.totalPagado / reserva.valorTotal).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: ID + estado ─────────────────────────────────────
            Row(
              children: [
                Text(
                  reserva.idReserva,
                  style: const TextStyle(
                    color: SaasPalette.brand600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                _EstadoBadge(estado: reserva.estado),
                const Spacer(),
                _WhatsAppReminderButton(reserva: reserva),
              ],
            ),
            const SizedBox(height: 10),

            // ── Responsable ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_rounded,
                  size: 14,
                  color: SaasPalette.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reserva.responsable.nombre,
                        style: const TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${reserva.responsable.tipoDocumento} ${reserva.responsable.documento}',
                        style: const TextStyle(
                          color: SaasPalette.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (reserva.responsable.telefono.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_rounded,
                        size: 13,
                        color: SaasPalette.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reserva.responsable.telefono,
                        style: const TextStyle(
                          color: SaasPalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Montos ───────────────────────────────────────────────────
            Row(
              children: [
                _MontoChip(
                  label: 'Total',
                  value: currFmt.format(reserva.valorTotal),
                  color: SaasPalette.textSecondary,
                ),
                const SizedBox(width: 8),
                _MontoChip(
                  label: 'Pagado',
                  value: currFmt.format(reserva.totalPagado),
                  color: SaasPalette.success,
                ),
                const SizedBox(width: 8),
                _MontoChip(
                  label: 'Saldo',
                  value: currFmt.format(reserva.saldoPendiente),
                  color: SaasPalette.danger,
                  highlighted: true,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Barra de progreso ────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: SaasPalette.bgSubtle,
                      color: pct >= 1.0
                          ? SaasPalette.success
                          : pct >= 0.5
                          ? SaasPalette.warning
                          : SaasPalette.danger,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            // ── Recordatorios ────────────────────────────────────────────
            if (reserva.totalRecordatorios > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.notifications_rounded,
                    size: 13,
                    color: _kWhatsApp.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${reserva.totalRecordatorios} recordatorio${reserva.totalRecordatorios != 1 ? 's' : ''} enviado${reserva.totalRecordatorios != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 11,
                    ),
                  ),
                  if (reserva.ultimoRecordatorio != null) ...[
                    const SizedBox(width: 6),
                    const Text(
                      '·',
                      style: TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: SaasPalette.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatFecha(reserva.ultimoRecordatorio),
                      style: const TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // ── Pagos realizados (expandible) ─────────────────────────────
            if (reserva.pagos.isNotEmpty) ...[
              const SizedBox(height: 10),
              InkWell(
                onTap: () => setState(() => _pagosExpanded = !_pagosExpanded),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: SaasPalette.bgSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: SaasPalette.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.receipt_long_rounded,
                        size: 14,
                        color: SaasPalette.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${reserva.pagos.length} pago${reserva.pagos.length != 1 ? 's' : ''} registrado${reserva.pagos.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: SaasPalette.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _pagosExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: SaasPalette.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_pagosExpanded) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: SaasPalette.bgApp,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SaasPalette.border),
                  ),
                  child: Column(
                    children: reserva.pagos.asMap().entries.map((entry) {
                      final i = entry.key;
                      final pago = entry.value;
                      return Column(
                        children: [
                          _PagoRow(pago: pago, currFmt: currFmt),
                          if (i < reserva.pagos.length - 1)
                            const Divider(
                              color: SaasPalette.border,
                              height: 1,
                              indent: 12,
                              endIndent: 12,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

// ── Botón WhatsApp Recordatorio ───────────────────────────────────────────────

const _kWhatsApp = SaasPalette.success;

class _WhatsAppReminderButton extends StatelessWidget {
  final SaldoPendiente reserva;
  const _WhatsAppReminderButton({required this.reserva});

  void _confirm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _RecordatorioDialog(
        reserva: reserva,
        bloc: context.read<SaldoPendienteBloc>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _confirm(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kWhatsApp,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: Size(100, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/whatsapp.png', width: 14, height: 14),
          const SizedBox(width: 6),
          const Text(
            'Recordatorio',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Diálogo de confirmación de recordatorio ───────────────────────────────────

class _RecordatorioDialog extends StatefulWidget {
  final SaldoPendiente reserva;
  final SaldoPendienteBloc bloc;

  const _RecordatorioDialog({required this.reserva, required this.bloc});

  @override
  State<_RecordatorioDialog> createState() => _RecordatorioDialogState();
}

class _RecordatorioDialogState extends State<_RecordatorioDialog> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    widget.bloc.add(EnviarRecordatorio(reservaId: widget.reserva.reservaId));
    // Espera el resultado escuchando el bloc
    await for (final state in widget.bloc.stream) {
      if (state is RecordatorioEnviado || state is RecordatorioFallido) {
        if (mounted) Navigator.of(context).pop();
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserva = widget.reserva;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kWhatsApp.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: _kWhatsApp.withValues(alpha: 0.08),
              blurRadius: 32,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kWhatsApp.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/whatsapp.png',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enviar recordatorio',
              style: TextStyle(
                color: SaasPalette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '¿Deseas enviar un recordatorio de pago por WhatsApp a '
              '${reserva.responsable.nombre}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SaasPalette.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (reserva.responsable.telefono.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.phone_rounded,
                    size: 13,
                    color: SaasPalette.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reserva.responsable.telefono,
                    style: const TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _sending
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SaasPalette.textSecondary,
                      side: const BorderSide(color: SaasPalette.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kWhatsApp,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/whatsapp.png',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Enviar',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
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
}

// ── Fila de Pago ──────────────────────────────────────────────────────────────

class _PagoRow extends StatelessWidget {
  final PagoSaldo pago;
  final NumberFormat currFmt;

  const _PagoRow({required this.pago, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final IconData statusIcon;
    final String statusLabel;

    if (pago.isRechazado) {
      statusColor = SaasPalette.danger;
      statusIcon = Icons.cancel_rounded;
      statusLabel = 'Rechazado';
    } else if (pago.isValidated) {
      statusColor = SaasPalette.success;
      statusIcon = Icons.check_circle_rounded;
      statusLabel = 'Validado';
    } else {
      statusColor = SaasPalette.warning;
      statusIcon = Icons.schedule_rounded;
      statusLabel = 'Pendiente';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(statusIcon, size: 16, color: statusColor),
          ),
          const SizedBox(width: 10),

          // Main info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Monto
                Text(
                  currFmt.format(pago.monto),
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                // Método + proveedor
                Row(
                  children: [
                    const Icon(
                      Icons.payment_rounded,
                      size: 11,
                      color: SaasPalette.textTertiary,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      pago.metodoPago,
                      style: const TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                    if (pago.proveedorComercio.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.store_rounded,
                        size: 11,
                        color: SaasPalette.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          pago.proveedorComercio,
                          style: const TextStyle(
                            color: SaasPalette.textTertiary,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Fecha creación + fecha documento
                Row(
                  children: [
                    if (pago.fechaCreacion != null) ...[
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 11,
                        color: SaasPalette.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatFecha(pago.fechaCreacion),
                        style: const TextStyle(
                          color: SaasPalette.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (pago.fechaDocumento != null) ...[
                      if (pago.fechaCreacion != null) const SizedBox(width: 10),
                      const Icon(
                        Icons.insert_invitation_rounded,
                        size: 11,
                        color: SaasPalette.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        _formatFecha(pago.fechaDocumento),
                        style: const TextStyle(
                          color: SaasPalette.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Referencia + teléfono + chat_id
                Row(
                  children: [
                    if (pago.referencia.isNotEmpty) ...[
                      const Icon(
                        Icons.tag_rounded,
                        size: 11,
                        color: SaasPalette.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          pago.referencia,
                          style: const TextStyle(
                            color: SaasPalette.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    if (pago.telefono.isNotEmpty) ...[
                      const Icon(
                        Icons.phone_rounded,
                        size: 11,
                        color: SaasPalette.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        pago.telefono,
                        style: const TextStyle(
                          color: SaasPalette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    if (pago.chatId.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 11,
                        color: SaasPalette.textTertiary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        pago.chatId,
                        style: const TextStyle(
                          color: SaasPalette.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                // Motivo rechazo
                if (pago.isRechazado && pago.motivoRechazo.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: SaasPalette.danger.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 11,
                          color: SaasPalette.danger,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            pago.motivoRechazo,
                            style: const TextStyle(
                              color: SaasPalette.danger,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _MontoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool highlighted;

  const _MontoChip({
    required this.label,
    required this.value,
    required this.color,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: highlighted
              ? color.withValues(alpha: 0.08)
              : SaasPalette.bgApp,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlighted
                ? color.withValues(alpha: 0.3)
                : SaasPalette.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: SaasPalette.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    final isPendiente = estado.toLowerCase() == 'pendiente';
    final color = isPendiente ? SaasPalette.warning : SaasPalette.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyView({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 48,
            color: SaasPalette.success,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin saldos pendientes',
            style: TextStyle(
              color: SaasPalette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Todas las reservas están al día.',
            style: TextStyle(color: SaasPalette.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: onRefresh, child: const Text('Actualizar')),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: SaasPalette.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              'Error al cargar los datos',
              style: TextStyle(
                color: SaasPalette.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SaasPalette.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: SaasPalette.brand600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
