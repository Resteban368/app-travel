import 'package:flutter/material.dart';
import '../theme/saas_palette.dart';

/// Breadcrumbs component for SaaS layout.
class SaasBreadcrumbs extends StatelessWidget {
  final List<String> items;

  const SaasBreadcrumbs({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: items.asMap().entries.map((entry) {
        final isLast = entry.key == items.length - 1;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.value,
              style: TextStyle(
                color: isLast
                    ? context.saas.textPrimary
                    : context.saas.textTertiary,
                fontSize: 12,
                fontWeight: isLast ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (!isLast)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: context.saas.textTertiary,
                ),
              ),
          ],
        );
      }).toList(),
    );
  }
}

/// A card for displaying statistics in the SaaS dashboard.
class SaasStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? trend;
  final bool isPositiveTrend;
  final Color? color;

  const SaasStatCard({
    super.key,
    required this.label,
    required this.value,
    this.trend,
    this.isPositiveTrend = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: context.saas.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color ?? context.saas.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (trend != null) ...[
              const SizedBox(height: 2),
              Text(
                trend!,
                style: TextStyle(
                  color: isPositiveTrend
                      ? context.saas.textTertiary
                      : context.saas.danger,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A modern action button for SaaS UI.
class SaasButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const SaasButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isPrimary ? context.saas.brand600 : context.saas.bgCanvas;
    final fgColor = isPrimary ? Colors.white : context.saas.textPrimary;
    final border = isPrimary ? null : Border.all(color: context.saas.border);

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: border,
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: context.saas.brand600.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: fgColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Search field with focus-animated border ──────────────────────────────
/// Replaces all private _SearchBar / _PremiumSearch copies in feature screens.
class SaasSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const SaasSearchField({
    super.key,
    required this.controller,
    this.hintText = 'Buscar…',
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<SaasSearchField> createState() => _SaasSearchFieldState();
}

class _SaasSearchFieldState extends State<SaasSearchField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(10),

        boxShadow: _focused
            ? [
                BoxShadow(
                  color: context.saas.brand600.withOpacity(0.08),
                  blurRadius: 10,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        onChanged: widget.onChanged,
        style: TextStyle(color: context.saas.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: context.saas.textTertiary),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _focused ? context.saas.brand600 : context.saas.textTertiary,
            size: 20,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: context.saas.textTertiary,
                  ),
                  onPressed: widget.onClear,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

/// ─── Status badge (Activo / Inactivo) ─────────────────────────────────────
/// Generic two-state badge reusable in any list/card widget.
class SaasStatusBadge extends StatelessWidget {
  final bool active;
  final String? activeLabel;
  final String? inactiveLabel;

  const SaasStatusBadge({
    super.key,
    required this.active,
    this.activeLabel,
    this.inactiveLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? context.saas.success : context.saas.textTertiary;
    final label = active
        ? (activeLabel ?? 'Activo')
        : (inactiveLabel ?? 'Inactivo');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Empty state ──────────────────────────────────────────────────────────
/// Centered empty state with an icon, title, and subtitle.
class SaasEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SaasEmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: context.saas.bgSubtle,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 36, color: context.saas.textTertiary),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              color: context.saas.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.saas.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── List skeleton ────────────────────────────────────────────────────────
/// A single shimmer-like skeleton row for list loading states.
class SaasListSkeleton extends StatelessWidget {
  final double height;

  const SaasListSkeleton({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: context.saas.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.saas.border),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.saas.bgSubtle,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 13,
                    width: 160,
                    decoration: BoxDecoration(
                      color: context.saas.bgSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 110,
                    decoration: BoxDecoration(
                      color: context.saas.bgSubtle,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ─── Banner skeleton ──────────────────────────────────────────────────────
/// A shimmer-like skeleton for the top banner in forms.
class SaasBannerSkeleton extends StatelessWidget {
  const SaasBannerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.saas.brand600.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.brand600.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.saas.brand600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 150,
                    height: 14,
                    decoration: BoxDecoration(
                      color: context.saas.brand600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 100,
                    height: 10,
                    decoration: BoxDecoration(
                      color: context.saas.brand600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            height: 12,
            decoration: BoxDecoration(
              color: context.saas.brand600.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 200,
            height: 12,
            decoration: BoxDecoration(
              color: context.saas.brand600.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// ─── Confirm delete / destructive action dialog ───────────────────────────
/// Reusable dialog for any destructive confirmation in the app.
class SaasConfirmDialog extends StatelessWidget {
  final String title;
  final String body;
  final String confirmLabel;
  final VoidCallback onConfirm;

  const SaasConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    this.confirmLabel = 'Eliminar',
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: context.saas.bgCanvas,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.saas.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.saas.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: context.saas.danger,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: context.saas.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                body,
                style: TextStyle(
                  color: context.saas.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SaasButton(
                      label: 'Cancelar',
                      isPrimary: false,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.saas.danger,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
