import 'package:flutter/material.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/saas_ui_components.dart';

class DashHeader extends StatelessWidget {
  const DashHeader({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMobile) ...[
          const SaasBreadcrumbs(items: ['Inicio', 'Dashboard']),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting()}, Administrador',
                    style: TextStyle(
                      color: context.saas.textPrimary,
                      fontSize: isMobile ? 20 : 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bienvenido al centro de operaciones de Agente Viajes.',
                    style: TextStyle(
                      color: context.saas.textSecondary,
                      fontSize: isMobile ? 12 : 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (!isMobile) ...[
              const SizedBox(width: 24),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.saas.bgSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.saas.border.withValues(alpha: 0.5)),
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: context.saas.brand600,
                  size: 24,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
