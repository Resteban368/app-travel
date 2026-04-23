import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/config/app_router.dart';
import 'package:agente_viajes/features/cotizaciones/presentation/bloc/cotizacion_bloc.dart';
import 'package:agente_viajes/features/cotizaciones/presentation/bloc/cotizacion_event.dart';
import 'package:agente_viajes/features/cotizaciones/presentation/bloc/cotizacion_state.dart';
import 'package:agente_viajes/features/dashboard/presentation/screens/widgets/dialog_detail.dart';
import 'package:agente_viajes/features/dashboard/presentation/widgets/dash_analytics_section.dart';
import 'package:agente_viajes/features/dashboard/presentation/widgets/dash_header.dart';
import 'package:agente_viajes/features/dashboard/presentation/widgets/dash_stats_grid.dart';
import 'package:agente_viajes/features/tour/presentation/bloc/tour_bloc.dart';
import 'package:agente_viajes/features/pagos_realizados/presentation/bloc/pago_realizado_bloc.dart';
import 'package:agente_viajes/features/tour/domain/entities/tour.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'es');

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  void _refreshAll() {
    context.read<TourBloc>().add(LoadTours());
    context.read<PagoRealizadoBloc>().add(const LoadPagos());
    context.read<CotizacionBloc>().add(LoadCotizaciones());
  }

  void _showTourDetail(Tour tour) {
    showDialog(
      context: context,
      builder: (context) => DialogDetailTour(
        tour: tour,
        currencyFormat: _currencyFormat,
        dateFormat: _dateFormat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TourBloc, TourState>(
      builder: (context, tourState) {
        return BlocBuilder<PagoRealizadoBloc, PagoRealizadoState>(
          builder: (context, pagosState) {
            final tours = tourState is ToursLoaded ? tourState.tours : <Tour>[];
            final normalTours = tours
                .where((t) => !t.isPromotion && t.isActive && !t.isDraft)
                .toList();
            final promoTours = tours
                .where((t) => t.isPromotion && t.isActive && !t.isDraft)
                .toList();

            final totalActive = normalTours.length;
            final totalPromos = promoTours.length;

            final pendingPagos = pagosState is PagosRealizadosLoaded
                ? pagosState.pagos.where((p) => !p.isValidated).length
                : 0;

            final isLoading = tourState is TourLoading;

            return Scaffold(
              backgroundColor: SaasPalette.bgApp,
              body: RefreshIndicator(
                onRefresh: () async => _refreshAll(),
                color: SaasPalette.brand600,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // ── Header ───────────────────────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      sliver: SliverToBoxAdapter(child: DashHeader()),
                    ),

                    // ── Stats Grid ───────────────────────────────────────────
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      sliver: SliverToBoxAdapter(
                        child: BlocBuilder<CotizacionBloc, CotizacionState>(
                          builder: (context, cotState) {
                            final unread = cotState is CotizacionLoaded
                                ? cotState.cotizaciones
                                      .where((c) => !c.isRead)
                                      .length
                                : 0;
                            return DashStatsGrid(
                              pendingPagos: pendingPagos,
                              totalActive: totalActive,
                              totalPromos: totalPromos,
                              unreadCotizaciones: unread,
                              onPagosTap: () => Navigator.pushNamed(
                                context,
                                AppRouter.pagosRealizados,
                              ),
                              onToursTap: () =>
                                  Navigator.pushNamed(context, AppRouter.tours),
                              onPromosTap: () =>
                                  Navigator.pushNamed(context, AppRouter.tours),
                              onCotizacionesTap: () => Navigator.pushNamed(
                                context,
                                AppRouter.cotizaciones,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Analytics Section ───────────────────────────────────
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
                      sliver: SliverToBoxAdapter(child: DashAnalyticsSection()),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
