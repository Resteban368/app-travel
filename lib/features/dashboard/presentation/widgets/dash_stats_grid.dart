import 'package:flutter/material.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/saas_ui_components.dart';

class DashStatsGrid extends StatelessWidget {
  final int pendingPagos;
  final int totalActive;
  final int totalPromos;
  final int unreadCotizaciones;
  final VoidCallback onPagosTap;
  final VoidCallback onToursTap;
  final VoidCallback onPromosTap;
  final VoidCallback onCotizacionesTap;

  const DashStatsGrid({
    super.key,
    required this.pendingPagos,
    required this.totalActive,
    required this.totalPromos,
    required this.unreadCotizaciones,
    required this.onPagosTap,
    required this.onToursTap,
    required this.onPromosTap,
    required this.onCotizacionesTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final crossAxisCount = width < 600 ? 1 : (width < 1000 ? 2 : 4);
      
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: width < 600 ? 3.5 : 2.2,
        children: [
          _InkStatWrapper(
            onTap: onPagosTap,
            child: SaasStatCard(
              label: 'Pagos Pendientes',
              value: '$pendingPagos',
              trend: pendingPagos > 0 ? 'Requieren validación' : 'Todo al día',
              color: pendingPagos > 0 ? SaasPalette.danger : SaasPalette.success,
            ),
          ),
          _InkStatWrapper(
            onTap: onToursTap,
            child: SaasStatCard(
              label: 'Tours Activos',
              value: '$totalActive',
              trend: 'Experiencias publicadas',
              color: SaasPalette.brand600,
            ),
          ),
          _InkStatWrapper(
            onTap: onPromosTap,
            child: SaasStatCard(
              label: 'Promociones',
              value: '$totalPromos',
              trend: 'Vigentes hoy',
              color: SaasPalette.warning,
            ),
          ),
          _InkStatWrapper(
            onTap: onCotizacionesTap,
            child: SaasStatCard(
              label: 'Cotizaciones',
              value: '$unreadCotizaciones',
              trend: unreadCotizaciones > 0 ? 'Nuevas solicitudes' : 'Todo atendido',
              color: SaasPalette.brand600,
            ),
          ),
        ],
      );
    });
  }
}

class _InkStatWrapper extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _InkStatWrapper({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }
}
