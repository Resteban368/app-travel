import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../domain/entities/dash_analytics.dart';

// ── Colores de gráficas ───────────────────────────────────────────────────────
const _chartColors = [
  Color(0xFF2563EB),
  Color(0xFF16A34A),
  Color(0xFFD97706),
  Color(0xFFDC2626),
  Color(0xFF7C3AED),
  Color(0xFF0891B2),
  Color(0xFFDB2777),
  Color(0xFF65A30D),
];

Color _colorAt(int i) => _chartColors[i % _chartColors.length];

// ── Contenedor base de gráfica ────────────────────────────────────────────────
class ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;
  final double height;

  const ChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: SaasPalette.border, height: 1),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }
}

// ── Vacío ─────────────────────────────────────────────────────────────────────
class _EmptyChart extends StatelessWidget {
  final String text;
  const _EmptyChart({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        style: const TextStyle(
          color: SaasPalette.textTertiary,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ── 1. Rendimiento por agente — Barras verticales agrupadas con números ────────
class RendimientoAgenteChart extends StatelessWidget {
  final List<RendimientoAgente> data;

  const RendimientoAgenteChart({super.key, required this.data});

  static const _barColors = [
    SaasPalette.brand600,
    SaasPalette.warning,
    Color(0xFF7C3AED),
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return ChartCard(
        title: 'Rendimiento por agente',
        icon: Icons.people_alt_rounded,
        color: SaasPalette.brand600,
        child: const _EmptyChart(text: 'Sin datos en este período'),
      );
    }

    // Máximo global para escalar todas las barras igual
    final globalMax = data
        .expand((ag) => [
              ag.reservasTour,
              ag.reservasVuelo,
              ag.respuestasCotizacion,
            ])
        .reduce((a, b) => a > b ? a : b);

    const chartHeight = 180.0;
    const barWidth = 14.0;
    const groupGap = 8.0;   // gap entre barras del mismo agente
    const agentGap = 20.0;  // gap entre agentes

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: SaasPalette.brand600.withAlpha(26),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.people_alt_rounded,
                      color: SaasPalette.brand600, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Rendimiento por agente',
                  style: TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: SaasPalette.border, height: 1),

          // ── Gráfico scrollable horizontal ────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Eje Y con líneas de referencia
                _YAxis(maxVal: globalMax, height: chartHeight),
                const SizedBox(width: 8),

                // Grupos de barras por agente — CustomPaint cubre todo el ancho
                CustomPaint(
                  painter: _BarGridPainter(
                    steps: 4,
                    chartHeight: chartHeight,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: data.map((ag) {
                      final valores = [
                        ag.reservasTour,
                        ag.reservasVuelo,
                        ag.respuestasCotizacion,
                      ];
                      return Padding(
                        padding: EdgeInsets.only(right: agentGap),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Barras
                            SizedBox(
                              height: chartHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: List.generate(3, (i) {
                                  final val = valores[i];
                                  final pct =
                                      globalMax > 0 ? val / globalMax : 0.0;
                                  const labelReserved = 20.0;
                                  final barH =
                                      (pct * (chartHeight - labelReserved))
                                          .clamp(4.0, chartHeight - labelReserved);
                                  final color = _barColors[i];

                                  return Padding(
                                    padding: EdgeInsets.only(
                                        right: i < 2 ? groupGap : 0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$val',
                                          style: TextStyle(
                                            color: val > 0
                                                ? SaasPalette.textPrimary
                                                : SaasPalette.textTertiary
                                                    .withAlpha(100),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 500),
                                          curve: Curves.easeOut,
                                          width: barWidth,
                                          height: barH,
                                          decoration: BoxDecoration(
                                            gradient: val > 0
                                                ? LinearGradient(
                                                    colors: [
                                                      color,
                                                      color.withValues(
                                                          alpha: 0.45),
                                                    ],
                                                    begin: Alignment.topCenter,
                                                    end: Alignment.bottomCenter,
                                                  )
                                                : null,
                                            color: val > 0
                                                ? null
                                                : SaasPalette.bgSubtle,
                                            borderRadius:
                                                const BorderRadius.vertical(
                                              top: Radius.circular(5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Nombre del agente
                            SizedBox(
                              width: barWidth * 3 + groupGap * 2 + 28,
                              child: Text(
                                ag.agenteNombre,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: const TextStyle(
                                  color: SaasPalette.textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// Eje Y con líneas de referencia
class _YAxis extends StatelessWidget {
  final int maxVal;
  final double height;

  const _YAxis({required this.maxVal, required this.height});

  @override
  Widget build(BuildContext context) {
    final steps = 4;
    return SizedBox(
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(steps + 1, (i) {
          final val = ((maxVal * (steps - i)) / steps).round();
          return Text(
            '$val',
            style: const TextStyle(
              color: SaasPalette.textTertiary,
              fontSize: 9,
            ),
          );
        }),
      ),
    );
  }
}

// Líneas horizontales de referencia para RendimientoAgenteChart
class _BarGridPainter extends CustomPainter {
  final int steps;
  final double chartHeight;
  const _BarGridPainter({this.steps = 4, required this.chartHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = SaasPalette.border
      ..strokeWidth = 1;
    for (int i = 0; i <= steps; i++) {
      final y = chartHeight * i / steps;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_BarGridPainter old) =>
      old.chartHeight != chartHeight || old.steps != steps;
}

// ── 2. Ingresos por tour — Barras ─────────────────────────────────────────────
class IngresosPorTourChart extends StatelessWidget {
  final List<IngresoTour> data;
  final NumberFormat currFmt;

  const IngresosPorTourChart({
    super.key,
    required this.data,
    required this.currFmt,
  });

  @override
  Widget build(BuildContext context) {
    final topN = data.take(6).toList();

    if (topN.isEmpty) {
      return ChartCard(
        title: 'Ingresos por tour',
        icon: Icons.monetization_on_rounded,
        color: SaasPalette.success,
        child: const _EmptyChart(text: 'Sin ingresos en este período'),
      );
    }

    final maxVal = topN
        .map((e) => e.montoRecaudado)
        .reduce((a, b) => a > b ? a : b);

    return ChartCard(
      title: 'Ingresos por tour',
      icon: Icons.monetization_on_rounded,
      color: SaasPalette.success,
      height: 260,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 24, 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxVal > 0 ? maxVal * 1.55 : 1,
            barTouchData: BarTouchData(
              handleBuiltInTouches: false,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 6,
                getTooltipItem: (group, _, rod, _) {
                  final t = topN[group.x];
                  return BarTooltipItem(
                    currFmt.format(t.montoRecaudado),
                    const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= topN.length) return const SizedBox();
                    final words = topN[i].tourNombre.split(' ');
                    final label = words.take(2).join(' ');
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: SaasPalette.textTertiary,
                          fontSize: 9,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: SaasPalette.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(topN.length, (i) {
              return BarChartGroupData(
                x: i,
                showingTooltipIndicators: [0],
                barRods: [
                  BarChartRodData(
                    toY: topN[i].montoRecaudado,
                    gradient: LinearGradient(
                      colors: [
                        SaasPalette.success,
                        SaasPalette.success.withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    width: 22,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── 3. Tours más vendidos — Barras horizontales ───────────────────────────────
class ToursMasVendidosChart extends StatelessWidget {
  final List<TourVendido> data;

  const ToursMasVendidosChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final topN = data.take(5).toList();

    if (topN.isEmpty) {
      return ChartCard(
        title: 'Tours más vendidos',
        icon: Icons.emoji_events_rounded,
        color: SaasPalette.warning,
        child: const _EmptyChart(text: 'Sin ventas en este período'),
      );
    }

    return ChartCard(
      title: 'Tours más vendidos',
      icon: Icons.emoji_events_rounded,
      color: SaasPalette.warning,
      height: 40.0 + topN.length * 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: List.generate(topN.length, (i) {
            final t = topN[i];
            final maxR = topN.first.totalReservas;
            final pct = maxR > 0 ? t.totalReservas / maxR : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Rank
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? SaasPalette.warning
                          : SaasPalette.bgSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i == 0
                              ? Colors.white
                              : SaasPalette.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.tourNombre,
                          style: const TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: SaasPalette.bgSubtle,
                            color: _colorAt(i),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${t.totalReservas}',
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── 4. Destinos más solicitados — PieChart ────────────────────────────────────
class DestinosPieChart extends StatefulWidget {
  final List<DestinoSolicitado> data;

  const DestinosPieChart({super.key, required this.data});

  @override
  State<DestinosPieChart> createState() => _DestinosPieChartState();
}

class _DestinosPieChartState extends State<DestinosPieChart> {
  int _touched = -1;

  @override
  Widget build(BuildContext context) {
    final topN = widget.data.take(6).toList();

    if (topN.isEmpty) {
      return ChartCard(
        title: 'Destinos más solicitados',
        icon: Icons.flight_takeoff_rounded,
        color: const Color(0xFF7C3AED),
        child: const _EmptyChart(text: 'Sin cotizaciones en este período'),
      );
    }

    final total = topN.fold<int>(0, (s, d) => s + d.total);

    return ChartCard(
      title: 'Destinos más solicitados',
      icon: Icons.flight_takeoff_rounded,
      color: const Color(0xFF7C3AED),
      height: 260,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Row(
          children: [
            // Pie
            SizedBox(
              width: 160,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response?.touchedSection != null &&
                            event is FlTapUpEvent) {
                          _touched =
                              response!.touchedSection!.touchedSectionIndex;
                        } else if (!event.isInterestedForInteractions) {
                          _touched = -1;
                        }
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: List.generate(topN.length, (i) {
                    final isTouched = i == _touched;
                    final pct = total > 0 ? topN[i].total / total * 100 : 0.0;
                    return PieChartSectionData(
                      color: _colorAt(i),
                      value: topN[i].total.toDouble(),
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: isTouched ? 52 : 44,
                      titleStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Leyenda
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(topN.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _colorAt(i),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _capitalize(topN[i].destino),
                            style: const TextStyle(
                              color: SaasPalette.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${topN[i].total}',
                          style: const TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── 5. Servicios más contratados — Barras ─────────────────────────────────────
class ServiciosChart extends StatelessWidget {
  final List<ServicioContratado> data;

  const ServiciosChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final topN = data.take(5).toList();

    if (topN.isEmpty) {
      return ChartCard(
        title: 'Servicios adicionales',
        icon: Icons.room_service_rounded,
        color: const Color(0xFF0891B2),
        child: const _EmptyChart(text: 'Sin servicios contratados'),
      );
    }

    final maxVal = topN.first.vecesContratado.toDouble();

    return ChartCard(
      title: 'Servicios adicionales',
      icon: Icons.room_service_rounded,
      color: const Color(0xFF0891B2),
      height: 40.0 + topN.length * 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: List.generate(topN.length, (i) {
            final s = topN[i];
            final pct = maxVal > 0 ? s.vecesContratado / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        color: SaasPalette.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.nombre,
                          style: const TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: SaasPalette.bgSubtle,
                            color: const Color(0xFF0891B2),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '×${s.vecesContratado}',
                    style: const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── 6. Ocupación por tour — Progress cards ────────────────────────────────────
class OcupacionTourChart extends StatelessWidget {
  final List<OcupacionTour> data;

  const OcupacionTourChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return ChartCard(
        title: 'Ocupación por tour',
        icon: Icons.event_seat_rounded,
        color: SaasPalette.danger,
        child: const _EmptyChart(text: 'Sin tours activos con cupos'),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: SaasPalette.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.event_seat_rounded,
                    color: SaasPalette.danger,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Ocupación por tour',
                  style: TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: SaasPalette.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: data.take(8).map((t) {
                final pct = t.porcentajeOcupacion / 100;
                final color = pct >= 0.9
                    ? SaasPalette.danger
                    : pct >= 0.6
                        ? SaasPalette.warning
                        : SaasPalette.success;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.tourNombre,
                              style: const TextStyle(
                                color: SaasPalette.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${t.porcentajeOcupacion}%',
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          backgroundColor: SaasPalette.bgSubtle,
                          color: color,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.cuposOcupados} ocupados · ${t.cuposDisponibles} disponibles de ${t.cuposTotales}',
                        style: const TextStyle(
                          color: SaasPalette.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 7. Evolución de reservas — LineChart ──────────────────────────────────────
class EvolucionReservasChart extends StatelessWidget {
  final List<EvolucionDia> data;

  const EvolucionReservasChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return ChartCard(
        title: 'Evolución de reservas',
        icon: Icons.show_chart_rounded,
        color: SaasPalette.brand600,
        child: const _EmptyChart(text: 'Sin reservas en este período'),
      );
    }

    final maxY = data.map((e) => e.total.toDouble()).reduce((a, b) => a > b ? a : b);

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.total.toDouble());
    }).toList();

    return ChartCard(
      title: 'Evolución de reservas',
      icon: Icons.show_chart_rounded,
      color: SaasPalette.brand600,
      height: 220,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: (maxY * 1.3).ceilToDouble(),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => SaasPalette.textPrimary,
                getTooltipItems: (spots) => spots.map((s) {
                  final d = data[s.x.toInt()];
                  final parts = d.fecha.split('-');
                  final label = '${parts[2]}/${parts[1]}';
                  return LineTooltipItem(
                    '$label\n${s.y.toInt()} reservas',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                }).toList(),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: SaasPalette.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text(
                    '${v.toInt()}',
                    style: const TextStyle(
                        color: SaasPalette.textTertiary, fontSize: 9),
                  ),
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (data.length / 5).ceilToDouble(),
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox();
                    final parts = data[i].fecha.split('-');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${parts[2]}/${parts[1]}',
                        style: const TextStyle(
                            color: SaasPalette.textTertiary, fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: SaasPalette.brand600,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: data.length <= 15,
                  getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: 3,
                    color: SaasPalette.brand600,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      SaasPalette.brand600.withAlpha(51),
                      SaasPalette.brand600.withAlpha(0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 8. Evolución de pagos — LineChart ─────────────────────────────────────────
class EvolucionPagosChart extends StatelessWidget {
  final List<EvolucionPagoDia> data;
  final NumberFormat currFmt;

  const EvolucionPagosChart({super.key, required this.data, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return ChartCard(
        title: 'Evolución de pagos',
        icon: Icons.trending_up_rounded,
        color: SaasPalette.success,
        child: const _EmptyChart(text: 'Sin pagos en este período'),
      );
    }

    final maxY = data.map((e) => e.monto).reduce((a, b) => a > b ? a : b);
    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.monto);
    }).toList();

    return ChartCard(
      title: 'Evolución de pagos',
      icon: Icons.trending_up_rounded,
      color: SaasPalette.success,
      height: 220,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY * 1.3,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => SaasPalette.textPrimary,
                getTooltipItems: (spots) => spots.map((s) {
                  final d = data[s.x.toInt()];
                  final parts = d.fecha.split('-');
                  return LineTooltipItem(
                    '${parts[2]}/${parts[1]}\n${currFmt.format(d.monto)}',
                    const TextStyle(color: Colors.white, fontSize: 11),
                  );
                }).toList(),
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: SaasPalette.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: (data.length / 5).ceilToDouble(),
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox();
                    final parts = data[i].fecha.split('-');
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${parts[2]}/${parts[1]}',
                        style: const TextStyle(
                            color: SaasPalette.textTertiary, fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: SaasPalette.success,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: data.length <= 15,
                  getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                    radius: 3,
                    color: SaasPalette.success,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      SaasPalette.success.withAlpha(51),
                      SaasPalette.success.withAlpha(0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 9. Cotizaciones por día de la semana — BarChart ───────────────────────────
class CotizacionesPorDiaChart extends StatelessWidget {
  final List<CotizacionDiaSemana> data;

  const CotizacionesPorDiaChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxY = data.isEmpty
        ? 1.0
        : data.map((e) => e.total.toDouble()).reduce((a, b) => a > b ? a : b);

    // Días abreviados
    const abrev = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

    return ChartCard(
      title: 'Cotizaciones por día',
      icon: Icons.calendar_month_rounded,
      color: SaasPalette.warning,
      height: 240,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (maxY * 1.55).ceilToDouble(),
            barTouchData: BarTouchData(
              handleBuiltInTouches: false,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                tooltipMargin: 6,
                getTooltipItem: (group, _, rod, _) {
                  final total = data[group.x].total;
                  if (total == 0) return null;
                  return BarTooltipItem(
                    '$total',
                    const TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ),
            gridData: FlGridData(
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) =>
                  const FlLine(color: SaasPalette.border, strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final i = value.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        abrev[data[i].diaIndex],
                        style: const TextStyle(
                            color: SaasPalette.textTertiary, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: List.generate(data.length, (i) {
              final isMax = data[i].total == maxY.toInt() && maxY > 0;
              return BarChartGroupData(
                x: i,
                showingTooltipIndicators: data[i].total > 0 ? [0] : [],
                barRods: [
                  BarChartRodData(
                    toY: data[i].total.toDouble(),
                    color: isMax ? SaasPalette.warning : SaasPalette.warning.withAlpha(140),
                    width: 28,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ── 10. Tours próximos a salir ────────────────────────────────────────────────
class ToursProximosCard extends StatelessWidget {
  final List<TourProximo> data;

  const ToursProximosCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return ChartCard(
        title: 'Tours próximos (30 días)',
        icon: Icons.flight_land_rounded,
        color: const Color(0xFF0891B2),
        child: const _EmptyChart(text: 'Sin tours programados en los próximos 30 días'),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0891B2).withAlpha(26),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.flight_land_rounded,
                      color: Color(0xFF0891B2), size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Tours próximos (30 días)',
                  style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0891B2).withAlpha(26),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data.length}',
                    style: const TextStyle(
                        color: Color(0xFF0891B2),
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: SaasPalette.border, height: 1),
          ...data.map((t) {
            final pct = t.porcentajeOcupacion / 100;
            final color = pct >= 0.9
                ? SaasPalette.danger
                : pct >= 0.6
                    ? SaasPalette.warning
                    : SaasPalette.success;
            final urgente = t.diasRestantes <= 7;
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: SaasPalette.border)),
              ),
              child: Row(
                children: [
                  // Días restantes
                  Container(
                    width: 44,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: urgente
                          ? SaasPalette.danger.withAlpha(20)
                          : SaasPalette.bgSubtle,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${t.diasRestantes}',
                          style: TextStyle(
                            color: urgente
                                ? SaasPalette.danger
                                : SaasPalette.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'días',
                          style: TextStyle(
                            color: urgente
                                ? SaasPalette.danger
                                : SaasPalette.textTertiary,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.tourNombre,
                          style: const TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct.clamp(0.0, 1.0),
                            backgroundColor: SaasPalette.bgSubtle,
                            color: color,
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${t.cuposOcupados}/${t.cuposTotales} cupos · ${t.porcentajeOcupacion}%',
                          style: const TextStyle(
                              color: SaasPalette.textTertiary, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── 11. Tours cupos críticos ──────────────────────────────────────────────────
class ToursCuposCriticosCard extends StatelessWidget {
  final List<OcupacionTour> data;

  const ToursCuposCriticosCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.danger.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: SaasPalette.danger.withAlpha(20),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: SaasPalette.danger, size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Cupos críticos (>80%)',
                  style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SaasPalette.danger.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${data.length}',
                    style: const TextStyle(
                        color: SaasPalette.danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: SaasPalette.border, height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: data.map((t) {
                final pct = t.porcentajeOcupacion / 100;
                final color = t.porcentajeOcupacion >= 100
                    ? const Color(0xFF7C3AED)
                    : SaasPalette.danger;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              t.tourNombre,
                              style: const TextStyle(
                                  color: SaasPalette.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${t.porcentajeOcupacion}%',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0.0, 1.0),
                          backgroundColor: SaasPalette.bgSubtle,
                          color: color,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.cuposDisponibles} cupos libres de ${t.cuposTotales}',
                        style: const TextStyle(
                            color: SaasPalette.textTertiary, fontSize: 10),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leyenda rendimiento agente ────────────────────────────────────────────────
class RendimientoLegend extends StatelessWidget {
  const RendimientoLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(SaasPalette.brand600),
        const SizedBox(width: 4),
        const Text('Tour', style: TextStyle(fontSize: 11, color: SaasPalette.textSecondary)),
        const SizedBox(width: 16),
        _dot(SaasPalette.warning),
        const SizedBox(width: 4),
        const Text('Vuelo', style: TextStyle(fontSize: 11, color: SaasPalette.textSecondary)),
        const SizedBox(width: 16),
        _dot(Color(0xFF7C3AED)),
        const SizedBox(width: 4),
        const Text('Cotizaciones', style: TextStyle(fontSize: 11, color: SaasPalette.textSecondary)),
      ],
    );
  }

  Widget _dot(Color c) => Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
      );
}
