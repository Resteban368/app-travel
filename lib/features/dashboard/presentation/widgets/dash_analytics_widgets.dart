import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../domain/entities/dash_analytics.dart';
import 'dash_tiles.dart';

class SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? sub;

  const SummaryCard({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Icon Splash
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              icon,
              size: 80,
              color: color.withOpacity(0.04),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  value,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (sub != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sub!,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VuelosPorAgenteCard extends StatelessWidget {
  final List<AgentGroup> grupos;
  final NumberFormat currFmt;
  final DateFormat dateFmt;

  const VuelosPorAgenteCard({
    super.key,
    required this.grupos,
    required this.currFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Vuelos por Agente',
            style: TextStyle(
              color: SaasPalette.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...grupos.map(
          (g) => AnalyticsExpansionCard(
            icon: Icons.person_outline_rounded,
            color: SaasPalette.brand600,
            title: g.agenteNombre,
            count: g.totalReservas,
            emptyText: 'Sin reservas asignadas',
            children: g.reservas
                .map(
                  (r) => Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SaasPalette.bgApp,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: SaasPalette.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reserva: ${r.idReserva}',
                                style: const TextStyle(
                                  color: SaasPalette.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                r.correo,
                                style: const TextStyle(
                                  color: SaasPalette.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          currFmt.format(r.valorTotal),
                          style: const TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
