import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../domain/entities/dash_analytics.dart';
import 'dash_tiles.dart';
import 'dash_analytics_widgets.dart';
import 'dash_chart_widgets.dart';

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: context.saas.border, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: context.saas.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Expanded(child: Divider(color: context.saas.border, height: 1)),
      ],
    );
  }
}

class DashAnalyticsSection extends StatefulWidget {
  const DashAnalyticsSection({super.key});

  @override
  State<DashAnalyticsSection> createState() => _DashAnalyticsSectionState();
}

class _DashAnalyticsSectionState extends State<DashAnalyticsSection> {
  String _periodo = 'mes';
  Future<AnalyticsData>? _future;

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

  Future<AnalyticsData> _loadAnalytics(String periodo) async {
    final client = sl<http.Client>();
    final uri = Uri.parse(
      '${ApiConstants.kBaseUrl}/v1/analytics?periodo=$periodo',
    );
    final response = await client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return AnalyticsData.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('Error al cargar analítica: ${response.statusCode}');
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.saas.border.withOpacity(0.5)),
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
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? context.saas.bgCanvas : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                p.$2,
                style: TextStyle(
                  color: selected
                      ? context.saas.textPrimary
                      : context.saas.textTertiary,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd MMM · HH:mm', 'es');

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ────────────────────────────────────────────────────────────
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.saas.brand600.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.bar_chart_rounded,
                          color: context.saas.brand600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Rendimiento y Analítica',
                          style: TextStyle(
                            color: context.saas.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPeriodSelector(),
                ],
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: context.saas.brand600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: context.saas.brand600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Rendimiento y Analítica',
                    style: TextStyle(
                      color: context.saas.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  _buildPeriodSelector(),
                ],
              ),
        const SizedBox(height: 20),

        // ── Content ───────────────────────────────────────────────────────────
        FutureBuilder<AnalyticsData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ShimmerLoading(
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: context.saas.bgCanvas,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.saas.bgCanvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.saas.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: context.saas.danger,
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudieron cargar los datos analíticos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.saas.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _fetch,
                      child: Text(
                        'Reintentar',
                        style: TextStyle(color: context.saas.brand600),
                      ),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!;

            return Column(
              children: [
                // ── Summary cards ──────────────────────────────────────────
                if (isMobile)
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SummaryCard(
                          icon: Icons.check_circle_rounded,
                          color: context.saas.success,
                          label: 'Pagos validados',
                          value: '${data.pagosTotal}',
                          sub: currFmt.format(data.pagosMontoTotal),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SummaryCard(
                              icon: Icons.tour_rounded,
                              color: context.saas.brand600,
                              label: 'Reservas tour',
                              value: '${data.reservasTourTotal}',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SummaryCard(
                              icon: Icons.request_quote_rounded,
                              color: context.saas.warning,
                              label: 'Cotizaciones',
                              value: '${data.cotizacionesTotal}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SummaryCard(
                          icon: Icons.check_circle_rounded,
                          color: context.saas.success,
                          label: 'Pagos validados',
                          value: '${data.pagosTotal}',
                          sub: currFmt.format(data.pagosMontoTotal),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          icon: Icons.tour_rounded,
                          color: context.saas.brand600,
                          label: 'Reservas tour',
                          value: '${data.reservasTourTotal}',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SummaryCard(
                          icon: Icons.request_quote_rounded,
                          color: context.saas.warning,
                          label: 'Cotizaciones',
                          value: '${data.cotizacionesTotal}',
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // ── Pagos validados ────────────────────────────────────────
                AnalyticsExpansionCard(
                  icon: Icons.payments_rounded,
                  color: context.saas.success,
                  title: 'Pagos validados',
                  count: data.pagosTotal,
                  emptyText: 'Sin pagos validados en este período',
                  children: data.pagos
                      .map(
                        (p) => PagoTile(
                          pago: p,
                          currFmt: currFmt,
                          dateFmt: dateFmt,
                        ),
                      )
                      .toList(),
                ),

                // ── Reservas de tour ───────────────────────────────────────
                AnalyticsExpansionCard(
                  icon: Icons.tour_rounded,
                  color: context.saas.brand600,
                  title: 'Reservas de tour',
                  count: data.reservasTourTotal,
                  emptyText: 'Sin reservas de tour en este período',
                  children: data.reservasTour
                      .map(
                        (r) => ReservaTourTile(
                          reserva: r,
                          currFmt: currFmt,
                          dateFmt: dateFmt,
                        ),
                      )
                      .toList(),
                ),

                // ── Cotizaciones ───────────────────────────────────────────
                AnalyticsExpansionCard(
                  icon: Icons.request_quote_rounded,
                  color: context.saas.warning,
                  title: 'Cotizaciones recibidas',
                  count: data.cotizacionesTotal,
                  emptyText: 'Sin cotizaciones en este período',
                  children: data.cotizaciones
                      .map((c) => CotizacionTile(cot: c, dateFmt: dateFmt))
                      .toList(),
                ),

                // ── Vuelos por agente ──────────────────────────────────────
                if (data.vuelosPorAgente.isNotEmpty)
                  VuelosPorAgenteCard(
                    grupos: data.vuelosPorAgente,
                    currFmt: currFmt,
                    dateFmt: dateFmt,
                  ),

                const SizedBox(height: 8),
                const _SectionDivider(label: 'Gráficas y análisis'),
                const SizedBox(height: 16),

                // ── Rendimiento por agente ──────────────────────────────────
                if (data.rendimientoPorAgente.isNotEmpty) ...[
                  RendimientoAgenteChart(data: data.rendimientoPorAgente),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: RendimientoLegend(),
                  ),
                ],

                // ── Ingresos por tour ───────────────────────────────────────
                IngresosPorTourChart(
                  data: data.ingresosPorTour,
                  currFmt: currFmt,
                ),

                // ── Tours más vendidos ──────────────────────────────────────
                ToursMasVendidosChart(data: data.toursMasVendidos),

                // ── Destinos más solicitados ────────────────────────────────
                DestinosPieChart(data: data.destinosMasSolicitados),

                // ── Servicios más contratados ───────────────────────────────
                ServiciosChart(data: data.serviciosMasContratados),

                // ── Ocupación por tour ──────────────────────────────────────
                OcupacionTourChart(data: data.ocupacionPorTour),

                const SizedBox(height: 8),
                const _SectionDivider(label: 'Tendencias temporales'),
                const SizedBox(height: 16),

                // ── Evolución de reservas ───────────────────────────────────
                EvolucionReservasChart(data: data.evolucionReservas),

                // ── Evolución de pagos ──────────────────────────────────────
                EvolucionPagosChart(
                  data: data.evolucionPagos,
                  currFmt: currFmt,
                ),

                // ── Cotizaciones por día de la semana ───────────────────────
                CotizacionesPorDiaChart(data: data.cotizacionesPorDia),

                const SizedBox(height: 8),
                const _SectionDivider(label: 'Tours'),
                const SizedBox(height: 16),

                // ── Cupos críticos (primero — más urgente) ──────────────────
                if (data.toursCuposCriticos.isNotEmpty)
                  ToursCuposCriticosCard(data: data.toursCuposCriticos),

                // ── Tours próximos ──────────────────────────────────────────
                ToursProximosCard(data: data.toursProximos),

                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ],
    );
  }
}
