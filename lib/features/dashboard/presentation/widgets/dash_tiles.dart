import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../domain/entities/dash_analytics.dart';

class AnalyticsExpansionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final int count;
  final String emptyText;
  final List<Widget> children;

  const AnalyticsExpansionCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.count,
    required this.emptyText,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: SaasPalette.bgSubtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          iconColor: SaasPalette.textTertiary,
          collapsedIconColor: SaasPalette.textTertiary,
          children: count == 0
              ? [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(
                      emptyText,
                      style: const TextStyle(color: SaasPalette.textTertiary, fontSize: 13),
                    ),
                  ),
                ]
              : children,
        ),
      ),
    );
  }
}

class PagoTile extends StatelessWidget {
  final AnalyticsPago pago;
  final NumberFormat currFmt;
  final DateFormat dateFmt;

  const PagoTile({
    super.key,
    required this.pago,
    required this.currFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  pago.proveedorComercio,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pago.metodoPago} · Ref: ${pago.referencia}',
                  style: const TextStyle(color: SaasPalette.textSecondary, fontSize: 12),
                ),
                Text(
                  dateFmt.format(pago.fechaCreacion.toLocal()),
                  style: const TextStyle(color: SaasPalette.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            currFmt.format(pago.monto),
            style: const TextStyle(
              color: SaasPalette.success,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class ReservaTourTile extends StatelessWidget {
  final AnalyticsReserva reserva;
  final NumberFormat currFmt;
  final DateFormat dateFmt;

  const ReservaTourTile({
    super.key,
    required this.reserva,
    required this.currFmt,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  reserva.tourNombre ?? 'Tour s/n',
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ID: ${reserva.idReserva} · ${reserva.correo}',
                  style: const TextStyle(color: SaasPalette.textSecondary, fontSize: 12),
                ),
                Text(
                  dateFmt.format(reserva.fechaCreacion.toLocal()),
                  style: const TextStyle(color: SaasPalette.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currFmt.format(reserva.valorTotal),
                style: const TextStyle(
                  color: SaasPalette.brand600,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                reserva.estado,
                style: const TextStyle(color: SaasPalette.textTertiary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CotizacionTile extends StatelessWidget {
  final AnalyticsCotizacion cot;
  final DateFormat dateFmt;

  const CotizacionTile({
    super.key,
    required this.cot,
    required this.dateFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                Row(
                  children: [
                    Text(
                      cot.nombreCompleto,
                      style: const TextStyle(
                        color: SaasPalette.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (!cot.isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: SaasPalette.brand600,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${cot.detallesPlan} · ${cot.numeroPasajeros} pax',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: SaasPalette.textSecondary, fontSize: 12),
                ),
                Text(
                  dateFmt.format(cot.createdAt.toLocal()),
                  style: const TextStyle(color: SaasPalette.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: SaasPalette.bgSubtle,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              cot.estado,
              style: const TextStyle(
                color: SaasPalette.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
