import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/saas_palette.dart';
import '../../features/notificaciones/domain/entities/notificacion.dart';

class SaasSnackBar {
  const SaasSnackBar._();

  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: context.saas.success,
      icon: Icons.check_circle_rounded,
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: context.saas.danger,
      icon: Icons.error_outline_rounded,
    );
  }

  static void showWarning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: context.saas.warning,
      icon: Icons.warning_amber_rounded,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message: message,
      backgroundColor: context.saas.brand600,
      icon: Icons.info_outline_rounded,
    );
  }

  // ─── Notification toast ─────────────────────────────────────────────────

  static OverlayEntry? _activeNotifEntry;

  static void showNotificacion(
    BuildContext context, {
    required Notificacion notificacion,
  }) {
    _activeNotifEntry?.remove();
    _activeNotifEntry = null;

    final overlayState = Overlay.of(context, rootOverlay: true);
    OverlayEntry? entry;

    entry = OverlayEntry(
      builder: (_) => _NotificacionToast(
        notificacion: notificacion,
        onDismiss: () {
          entry?.remove();
          if (_activeNotifEntry == entry) _activeNotifEntry = null;
        },
      ),
    );

    _activeNotifEntry = entry;
    overlayState.insert(entry);
  }

  // ─── Generic snackbar (success / error / warning / info) ────────────────

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// ─── Animated notification toast widget ─────────────────────────────────────

class _NotificacionToast extends StatefulWidget {
  final Notificacion notificacion;
  final VoidCallback onDismiss;

  const _NotificacionToast({
    required this.notificacion,
    required this.onDismiss,
  });

  @override
  State<_NotificacionToast> createState() => _NotificacionToastState();
}

class _NotificacionToastState extends State<_NotificacionToast>
    with TickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final AnimationController _progressCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;
  Timer? _dismissTimer;

  static const _duration = Duration(seconds: 5);
  static const _enterMs = Duration(milliseconds: 400);
  static const _exitMs = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();

    _entranceCtrl = AnimationController(vsync: this, duration: _enterMs);
    _progressCtrl = AnimationController(vsync: this, duration: _duration);

    _fade = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    _entranceCtrl.forward();
    _progressCtrl.forward();
    _dismissTimer = Timer(_duration, _dismiss);
  }

  Future<void> _dismiss() async {
    _dismissTimer?.cancel();
    if (!mounted) return;
    _entranceCtrl.duration = _exitMs;
    await _entranceCtrl.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _entranceCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  static (IconData, Color) _resolve(BuildContext context, String tipo) => switch (tipo) {
    'cotizacion' => (Icons.request_quote_rounded, const Color(0xFF7C3AED)),
    'pago'       => (Icons.payments_rounded,       const Color(0xFF059669)),
    'reserva'    => (Icons.airplane_ticket_rounded, context.saas.brand600),
    'sistema'    => (Icons.settings_rounded,        const Color(0xFF6B7280)),
    _            => (Icons.campaign_rounded,         const Color(0xFFD97706)),
  };

  static String _label(String tipo) => switch (tipo) {
    'cotizacion' => 'COTIZACIÓN',
    'pago'       => 'PAGO',
    'reserva'    => 'RESERVA',
    'sistema'    => 'SISTEMA',
    _            => 'NOTIFICACIÓN',
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _resolve(context, widget.notificacion.tipo);

    return Positioned(
      bottom: 28,
      right: 24,
      left: 24,
      child: Align(
        alignment: Alignment.centerRight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 368),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: ScaleTransition(
                scale: _scale,
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onTap: _dismiss,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.09),
                            blurRadius: 32,
                            spreadRadius: 0,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: color.withValues(alpha: 0.14),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // ── Left accent bar ──────────────────────
                                  Container(width: 4, color: color),

                                  // ── Icon ────────────────────────────────
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.09),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(icon, color: color, size: 21),
                                    ),
                                  ),

                                  // ── Text ────────────────────────────────
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(0, 13, 8, 13),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _label(widget.notificacion.tipo),
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.9,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.notificacion.titulo,
                                            style: const TextStyle(
                                              color: Color(0xFF111827),
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              height: 1.3,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (widget.notificacion.mensaje.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              widget.notificacion.mensaje,
                                              style: const TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 12,
                                                height: 1.35,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),

                                  // ── Close ───────────────────────────────
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(0, 10, 12, 0),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 15,
                                      color: const Color(0xFFD1D5DB),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // ── Progress bar ────────────────────────────
                            AnimatedBuilder(
                              animation: _progressCtrl,
                              builder: (_, child) => Container(
                                height: 3,
                                color: const Color(0xFFF3F4F6),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: 1.0 - _progressCtrl.value,
                                    child: Container(color: color),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
