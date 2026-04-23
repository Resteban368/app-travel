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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Dashboard']),
        const SizedBox(height: 16),
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting()}, Administrador',
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Bienvenido al centro de operaciones de Travel Tours.',
                  style: TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Optional: User Avatar or Quick Action
            const CircleAvatar(
              radius: 20,
              backgroundColor: SaasPalette.bgSubtle,
              child: Icon(Icons.person_outline, color: SaasPalette.brand600),
            ),
          ],
        ),
      ],
    );
  }
}
