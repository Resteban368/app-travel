// lib/core/widgets/premium_form_widgets.dart
//
// Biblioteca de widgets reutilizables de estilo premium para formularios.
// Importa este archivo en cualquier módulo de la app que necesite el diseño
// glassmorphism unificado.
//
// Uso:
//   import 'package:agente_viajes/core/widgets/premium_form_widgets.dart';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/premium_palette.dart';

// ──────────────────────────────────────────────────────────────────────────────
// 1. FONDO DE PANTALLA CON EFECTO GLASSMORPHISM
// ──────────────────────────────────────────────────────────────────────────────

/// Wrapper de fondo premium con orbes ambientados y filtro de desenfoque.
/// Úsalo como capa base dentro del [Stack] del body de cualquier [Scaffold].
///
/// Ejemplo:
/// ```dart
/// Scaffold(
///   backgroundColor: D.bg,
///   body: Stack(
///     children: [
///       const PremiumBackground(),
///       // ... tu contenido ...
///     ],
///   ),
/// )
/// ```
class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Orbe superior izquierdo (royalBlue)
        Positioned(
          top: -100,
          left: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: D.royalBlue.withOpacity(0.15),
            ),
          ),
        ),
        // Orbe inferior derecho (skyBlue)
        Positioned(
          bottom: 100,
          right: -50,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: D.skyBlue.withOpacity(0.1),
            ),
          ),
        ),
        // Desenfoque masivo que unifica los orbes
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: const SizedBox(),
          ),
        ),
        // Puntos de cuadrícula decorativos
        Positioned.fill(child: CustomPaint(painter: DotGridPainter())),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 2. SLIVER APP BAR PREMIUM (encabezado colapsable)
// ──────────────────────────────────────────────────────────────────────────────

/// [SliverAppBar] premium con fondo transparente y título grande que se
/// colapsa al hacer scroll. Úsalo como primer elemento de un [CustomScrollView].
///
/// Ejemplo:
/// ```dart
/// CustomScrollView(
///   slivers: [
///     PremiumSliverAppBar(title: 'Nueva Cotización'),
///     SliverToBoxAdapter(child: /* tu formulario */),
///   ],
/// )
/// ```
class PremiumSliverAppBar extends StatelessWidget {
  final String title;
  final Widget? actions;

  const PremiumSliverAppBar({super.key, required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      //flecga de atras
      leading: actions,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 3. TARJETA GLASSMORPHISM PARA SECCIONES DE FORMULARIO
// ──────────────────────────────────────────────────────────────────────────────

/// Contenedor glassmorphism para agrupar campos relacionados visualmente.
/// Siempre incluye un encabezado de sección ([PremiumSectionHeader]).
///
/// Ejemplo:
/// ```dart
/// PremiumSectionCard(
///   title: 'DATOS PERSONALES',
///   icon: Icons.person_rounded,
///   children: [
///     PremiumTextField(controller: nameCtrl, label: 'Nombre *', icon: Icons.badge_rounded),
///     const SizedBox(height: 20),
///     PremiumTextField(controller: emailCtrl, label: 'Email *', icon: Icons.email_rounded),
///   ],
/// )
/// ```
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding ?? const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: D.surfaceHigh.withOpacity(0.4),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PremiumSectionHeader(title: title, icon: icon),
              const SizedBox(height: 24),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 4. ENCABEZADO DE SECCIÓN
// ──────────────────────────────────────────────────────────────────────────────

/// Encabezado visual con icono y texto en mayúsculas para identificar
/// las secciones dentro de [PremiumSectionCard].
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
            color: D.skyBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: D.skyBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 5. CAMPO DE TEXTO PREMIUM
// ──────────────────────────────────────────────────────────────────────────────

/// Campo de texto estilizado con label, icono de prefijo y bordes de cristal.
/// Incluye validación de "Requerido" automática si [label] contiene '*'.
///
/// Ejemplo:
/// ```dart
/// PremiumTextField(
///   controller: _nameCtrl,
///   label: 'Nombre Completo *',
///   icon: Icons.person_rounded,
/// )
/// ```
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
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    // If multiline and no keyboard type specified, use multiline
    final kType =
        widget.keyboardType ??
        (widget.isNumeric
            ? TextInputType.number
            : (widget.maxLines > 1
                  ? TextInputType.multiline
                  : TextInputType.text));

    // If multiline and no action specified, use newline
    final tAction =
        widget.textInputAction ??
        (widget.maxLines > 1 ? TextInputAction.newline : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: D.slate400,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
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
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(widget.icon, color: D.skyBlue, size: 20),
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: D.slate400,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  )
                : null,
            filled: true,
            fillColor: D.surfaceHigh.withOpacity(0.5),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: D.skyBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: D.rose.withOpacity(0.5)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: D.rose, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
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

/// Botón de acción principal con gradiente y sombra luminosa.
/// Muestra un [CircularProgressIndicator] cuando [isLoading] es true.
///
/// Ejemplo:
/// ```dart
/// PremiumActionButton(
///   label: 'GUARDAR',
///   icon: Icons.save_rounded,
///   isLoading: isSaving,
///   onTap: () => _save(),
/// )
/// ```
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
        duration: const Duration(milliseconds: 300),
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [D.skyBlue, D.royalBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: D.royalBlue.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1,
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
// 7. SWITCH DE ESTADO PREMIUM
// ──────────────────────────────────────────────────────────────────────────────

/// Switch con etiqueta estilizada para activar/desactivar estados del modelo.
///
/// Ejemplo:
/// ```dart
/// PremiumStatusSwitch(
///   label: 'Activo',
///   value: _isActive,
///   onChanged: (v) => setState(() => _isActive = v),
///   activeColor: D.emerald,
/// )
/// ```
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
              color: D.slate400,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Switch(
            value: value,
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.3),
            inactiveThumbColor: D.slate400,
            inactiveTrackColor: D.bg.withOpacity(0.5),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// 8. CHIP PREMIUM PARA LISTAS DINÁMICAS
// ──────────────────────────────────────────────────────────────────────────────

/// Tag/chip con borde coloreado y opción de eliminación.
/// Usado en listas de inclusiones, exclusiones, etiquetas, permisos, etc.
///
/// Ejemplo:
/// ```dart
/// PremiumChip(
///   label: 'Desayuno incluido',
///   color: D.emerald,
///   onRemove: () => setState(() => list.remove(item)),
/// )
/// ```
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close_rounded, color: color, size: 16),
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

/// Widget para mostrar cuando una lista dinámica está vacía.
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
              Icon(icon, color: D.slate600, size: 32),
              const SizedBox(height: 12),
            ],
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: D.slate600,
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

/// [CustomPainter] que dibuja una cuadrícula de puntos sutiles en el fondo.
/// Úsalo dentro de un [CustomPaint] con [Positioned.fill].
class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = D.border.withOpacity(0.2);
    const spacing = 32.0;
    for (double i = 0; i < size.width; i += spacing) {
      for (double j = 0; j < size.height; j += spacing) {
        canvas.drawCircle(Offset(i, j), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
