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

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
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
                color: SaasPalette.brand600.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: SaasPalette.brand600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Rendimiento y Analítica',
              style: TextStyle(
                color: SaasPalette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            // Período selector
            Container(
              decoration: BoxDecoration(
                color: SaasPalette.bgSubtle,
                borderRadius: BorderRadius.circular(10),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? SaasPalette.bgCanvas
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                        boxShadow: selected
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
                        p.$2,
                        style: TextStyle(
                          color: selected
                              ? SaasPalette.textPrimary
                              : SaasPalette.textTertiary,
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
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
                          color: SaasPalette.bgCanvas,
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
                  color: SaasPalette.bgCanvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SaasPalette.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: SaasPalette.danger,
                      size: 24,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudieron cargar los datos analíticos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: SaasPalette.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    TextButton(
                      onPressed: _fetch,
                      child: const Text(
                        'Reintentar',
                        style: TextStyle(color: SaasPalette.brand600),
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
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        icon: Icons.check_circle_rounded,
                        color: SaasPalette.success,
                        label: 'Pagos validados',
                        value: '${data.pagosTotal}',
                        sub: currFmt.format(data.pagosMontoTotal),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        icon: Icons.tour_rounded,
                        color: SaasPalette.brand600,
                        label: 'Reservas tour',
                        value: '${data.reservasTourTotal}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        icon: Icons.request_quote_rounded,
                        color: SaasPalette.warning,
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
                  color: SaasPalette.success,
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
                  color: SaasPalette.brand600,
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
                  color: SaasPalette.warning,
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
              ],
            );
          },
        ),
      ],
    );
  }
}
