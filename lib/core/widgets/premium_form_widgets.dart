// lib/core/widgets/premium_form_widgets.dart
//
// Biblioteca de widgets reutilizables de estilo SaaS claro.
// Usa SaasPalette como fuente única de color.
//
// Uso:
//   import 'package:agente_viajes/core/widgets/premium_form_widgets.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/saas_palette.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 2. SLIVER APP BAR (encabezado colapsable)
// ──────────────────────────────────────────────────────────────────────────────

/// [SliverAppBar] con degradado brand y título centrado que se colapsa al scrollear.
class PremiumSliverAppBar extends StatelessWidget {
  final String title;
  final Widget? actions;

  const PremiumSliverAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: SaasPalette.brand900,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      leading: actions,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontSize: 15,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [SaasPalette.brand600, SaasPalette.brand900],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 3. TARJETA DE SECCIÓN DE FORMULARIO
// ──────────────────────────────────────────────────────────────────────────────

/// Contenedor limpio para agrupar campos relacionados.
class PremiumSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final EdgeInsets? padding;

  const PremiumSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PremiumSectionHeader(title: title, icon: icon),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 4. ENCABEZADO DE SECCIÓN
// ──────────────────────────────────────────────────────────────────────────────

class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: SaasPalette.brand50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: SaasPalette.brand600, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: SaasPalette.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 5. CAMPO DE TEXTO
// ──────────────────────────────────────────────────────────────────────────────

/// Campo de texto estilizado con label, icono y bordes claros.
/// Incluye validación automática si [label] contiene '*'.
class PremiumTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isNumeric;
  final bool readOnly;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool isPassword;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  const PremiumTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isNumeric = false,
    this.readOnly = false,
    this.maxLines = 1,
    this.validator,
    this.keyboardType,
    this.isPassword = false,
    this.textInputAction,
    this.focusNode,
    this.onChanged,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final kType =
        widget.keyboardType ??
        (widget.isNumeric
            ? TextInputType.number
            : (widget.maxLines > 1
                  ? TextInputType.multiline
                  : TextInputType.text));

    final tAction =
        widget.textInputAction ??
        (widget.maxLines > 1 ? TextInputAction.newline : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          readOnly: widget.readOnly,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: kType,
          textInputAction: tAction,
          focusNode: widget.focusNode,
          inputFormatters: widget.isNumeric
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: const TextStyle(color: SaasPalette.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(
              widget.icon,
              color: SaasPalette.brand600,
              size: 18,
            ),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: SaasPalette.textTertiary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  )
                : null,
            filled: true,
            fillColor: widget.readOnly
                ? SaasPalette.bgSubtle
                : SaasPalette.bgCanvas,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SaasPalette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: SaasPalette.brand600,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: SaasPalette.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: SaasPalette.danger,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          onChanged: widget.onChanged,
          validator:
              widget.validator ??
              (v) => (v == null || v.isEmpty) && widget.label.contains('*')
                  ? 'Requerido'
                  : null,
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 6. BOTÓN DE ACCIÓN PRINCIPAL (CTA)
// ──────────────────────────────────────────────────────────────────────────────

/// Botón principal con fondo sólido brand y sombra sutil.
class PremiumActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onTap;

  const PremiumActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          color: isLoading
              ? SaasPalette.brand600.withValues(alpha: 0.7)
              : SaasPalette.brand600,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: SaasPalette.brand600.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 7. SWITCH DE ESTADO
// ──────────────────────────────────────────────────────────────────────────────

class PremiumStatusSwitch extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool)? onChanged;
  final Color activeColor;

  const PremiumStatusSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: SaasPalette.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Switch(
            value: value,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withValues(alpha: 0.25),
            inactiveThumbColor: SaasPalette.textTertiary,
            inactiveTrackColor: SaasPalette.bgSubtle,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 8. CHIP PARA LISTAS DINÁMICAS
// ──────────────────────────────────────────────────────────────────────────────

class PremiumChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onRemove;

  const PremiumChip({
    super.key,
    required this.label,
    required this.color,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded, color: color, size: 15),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 9. INDICADOR DE ESTADO VACÍO
// ──────────────────────────────────────────────────────────────────────────────

class PremiumEmptyIndicator extends StatelessWidget {
  final String msg;
  final IconData? icon;

  const PremiumEmptyIndicator({super.key, required this.msg, this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: SaasPalette.textTertiary, size: 32),
              const SizedBox(height: 12),
            ],
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SaasPalette.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 10. PAINTER DE CUADRÍCULA DE PUNTOS (decorativo)
// ──────────────────────────────────────────────────────────────────────────────

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = SaasPalette.border.withValues(alpha: 0.4);
    const spacing = 28.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
