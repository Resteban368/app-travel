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
        tourNombre: value.trim().isEmpty ? null : value.trim(),
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
            child: BlocBuilder<SaldoPendienteBloc, SaldoPendienteState>(
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
              IconButton(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                color: SaasPalette.textSecondary,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 14),
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
                      hintText: 'Buscar por nombre de tour…',
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
        ],
      ),
    );
  }
}

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
        return _TourCard(
          tour: loaded.tours[index],
          currFmt: currFmt,
        );
      },
    );
  }
}

class _TourCard extends StatelessWidget {
  final TourConSaldo tour;
  final NumberFormat currFmt;

  const _TourCard({
    required this.tour,
    required this.currFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SaasPalette.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/saldos-pendientes/detalle',
            arguments: tour,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SaasPalette.brand600.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.tour_rounded,
                  color: SaasPalette.brand600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour.tourNombre,
                      style: const TextStyle(
                        color: SaasPalette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (tour.fechaTour != null) ...[
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: SaasPalette.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatFecha(tour.fechaTour),
                            style: const TextStyle(
                              color: SaasPalette.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        const Icon(
                          Icons.people_rounded,
                          size: 12,
                          color: SaasPalette.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tour.totalReservas} reserva${tour.totalReservas != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: SaasPalette.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    currFmt.format(tour.totalSaldoPendiente),
                    style: const TextStyle(
                      color: SaasPalette.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    'Saldo total',
                    style: TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (tour.totalPorValidar > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      currFmt.format(tour.totalPorValidar),
                      style: const TextStyle(
                        color: SaasPalette.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'Por validar',
                      style: TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: SaasPalette.textTertiary,
              ),
            ],
          ),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 64, color: SaasPalette.success.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          const Text('No hay saldos pendientes',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: SaasPalette.textPrimary)),
          const SizedBox(height: 8),
          const Text('¡Todo está al día!',
              style: TextStyle(color: SaasPalette.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Actualizar'),
          ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: SaasPalette.danger),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: SaasPalette.textPrimary)),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
