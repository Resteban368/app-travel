import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/di/injection_container.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import '../../data/services/web_notification_service.dart';
import '../../domain/entities/notificacion.dart';
import '../bloc/notificacion_bloc.dart';

// ─── Bell icon con badge ──────────────────────────────────

class NotificacionBell extends StatelessWidget {
  const NotificacionBell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificacionBloc, NotificacionState>(
      builder: (context, state) {
        final count =
            state is NotificacionesCargadas ? state.totalNoLeidas : 0;
        return Tooltip(
          message: 'Notificaciones',
          child: InkWell(
            onTap: () => _handleTap(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_rounded,
                    size: 20,
                    color: count > 0
                        ? context.saas.brand600
                        : context.saas.textSecondary,
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        decoration: BoxDecoration(
                          color: context.saas.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count > 99 ? '99+' : count.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    final webNotif = sl<WebNotificationService>();
    if (webNotif.isSupported && webNotif.permission == 'default') {
      final agreed = await _showPermissionPrompt(context);
      if (agreed == true) await webNotif.requestPermission();
    }
    if (context.mounted) _showPanel(context);
  }

  Future<bool?> _showPermissionPrompt(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.saas.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.notifications_active_rounded,
                color: Color(0xFFF59E0B), size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Notificaciones del navegador',
                style: TextStyle(
                  color: context.saas.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Activa las notificaciones para recibir alertas aunque estés en otra pestaña del navegador.',
          style: TextStyle(color: context.saas.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Ahora no',
              style: TextStyle(color: context.saas.textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.notifications_rounded, size: 16),
            label: const Text('Activar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPanel(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      barrierLabel: 'Cerrar',
      transitionDuration: const Duration(milliseconds: 180),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.02),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      pageBuilder: (ctx, a1, a2) => BlocProvider.value(
        value: context.read<NotificacionBloc>(),
        child: Builder(
          builder: (innerCtx) => Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 12),
              child: Material(
                color: Colors.transparent,
                child: _NotificacionPanel(
                  onClose: () => Navigator.of(ctx).pop(),
                  isAdmin: _isAdmin(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isAdmin(BuildContext context) {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) return auth.user.isAdmin;
    return false;
  }
}

// ─── Panel de notificaciones ─────────────────────────────

class _NotificacionPanel extends StatelessWidget {
  final VoidCallback onClose;
  final bool isAdmin;

  const _NotificacionPanel({
    required this.onClose,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            Divider(height: 1, color: context.saas.border),
            Flexible(child: _buildList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<NotificacionBloc, NotificacionState>(
      builder: (context, state) {
        final count =
            state is NotificacionesCargadas ? state.totalNoLeidas : 0;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Icon(
                Icons.notifications_rounded,
                size: 18,
                color: context.saas.brand600,
              ),
              const SizedBox(width: 8),
              Text(
                'Notificaciones',
                style: TextStyle(
                  color: context.saas.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.saas.danger,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (count > 0)
                TextButton(
                  onPressed: () =>
                      context.read<NotificacionBloc>().add(MarcarTodasLeidas()),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Leer todo',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.saas.brand600,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onClose,
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: context.saas.textSecondary,
                ),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDetail(BuildContext context, Notificacion n) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _NotificacionDetailDialog(notificacion: n, isAdmin: isAdmin),
    );
  }

  Widget _buildList(BuildContext context) {
    return BlocBuilder<NotificacionBloc, NotificacionState>(
      builder: (context, state) {
        if (state is NotificacionCargando) {
          return SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.saas.brand600,
              ),
            ),
          );
        }

        final items = state is NotificacionesCargadas ? state.items : <Notificacion>[];

        if (items.isEmpty) {
          return SizedBox(
            height: 140,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 36,
                    color: context.saas.textTertiary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sin notificaciones',
                    style: TextStyle(
                      color: context.saas.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              Divider(height: 1, color: context.saas.border),
          itemBuilder: (ctx, i) => _NotificacionTile(
            notificacion: items[i],
            isAdmin: isAdmin,
            onTap: () {
              if (!items[i].leida) {
                context.read<NotificacionBloc>().add(MarcarLeida(items[i].id));
              }
              _showDetail(ctx, items[i]);
            },
            onDelete: isAdmin
                ? () => context
                    .read<NotificacionBloc>()
                    .add(EliminarNotificacion(items[i].id))
                : null,
          ),
        );
      },
    );
  }
}

// ─── Tile de notificación ─────────────────────────────────

class _NotificacionTile extends StatefulWidget {
  final Notificacion notificacion;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _NotificacionTile({
    required this.notificacion,
    required this.isAdmin,
    required this.onTap,
    this.onDelete,
  });

  @override
  State<_NotificacionTile> createState() => _NotificacionTileState();
}

class _NotificacionTileState extends State<_NotificacionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<Offset> _slide;
  late final Animation<double> _fade;
  late final Animation<double> _size;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _slide = Tween<Offset>(begin: Offset.zero, end: const Offset(1.2, 0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInCubic));
    _fade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.2, 0.9, curve: Curves.easeIn),
      ),
    );
    _size = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.55, 1.0, curve: Curves.easeInCubic),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleDelete() {
    if (_deleting) return;
    setState(() => _deleting = true);
    widget.onDelete?.call();
    _ctrl.forward();
  }

  static String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return DateFormat('dd MMM', 'es_CO').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final unread = !widget.notificacion.leida;
    return SizeTransition(
      sizeFactor: _size,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: InkWell(
            onTap: widget.onTap,
            child: Container(
              color: unread
                  ? context.saas.brand600.withValues(alpha: 0.04)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TipoIcon(tipo: widget.notificacion.tipo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.notificacion.titulo,
                                style: TextStyle(
                                  color: context.saas.textPrimary,
                                  fontSize: 13,
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (unread)
                              Container(
                                width: 7,
                                height: 7,
                                margin: const EdgeInsets.only(left: 6),
                                decoration: BoxDecoration(
                                  color: context.saas.brand600,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.notificacion.mensaje,
                          style: TextStyle(
                            color: context.saas.textSecondary,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (widget.notificacion.esGeneral)
                              _SmallBadge(
                                label: 'General',
                                color: context.saas.textTertiary,
                              ),
                            if (widget.notificacion.esGeneral)
                              const SizedBox(width: 6),
                            Text(
                              _formatTime(widget.notificacion.createdAt),
                              style: TextStyle(
                                color: context.saas.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.onDelete != null)
                    IconButton(
                      onPressed: _deleting ? null : _handleDelete,
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _deleting
                            ? SizedBox(
                                key: ValueKey('spinner'),
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: context.saas.textTertiary,
                                ),
                              )
                            : const Icon(
                                key: ValueKey('icon'),
                                Icons.delete_outline_rounded,
                                size: 16,
                              ),
                      ),
                      color: context.saas.textTertiary,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ícono por tipo ───────────────────────────────────────

class _TipoIcon extends StatelessWidget {
  final String tipo;
  const _TipoIcon({required this.tipo});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (tipo) {
      'cotizacion' => (Icons.request_quote_rounded, const Color(0xFF7C3AED)),
      'pago' => (Icons.payments_rounded, const Color(0xFF059669)),
      'reserva' => (Icons.airplane_ticket_rounded, context.saas.brand600),
      'sistema' => (Icons.settings_rounded, context.saas.textSecondary),
      _ => (Icons.campaign_rounded, const Color(0xFFD97706)),
    };
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 17, color: color),
    );
  }
}

// ─── Diálogo de detalle ───────────────────────────────────

class _NotificacionDetailDialog extends StatelessWidget {
  final Notificacion notificacion;
  final bool isAdmin;

  const _NotificacionDetailDialog({
    required this.notificacion,
    required this.isAdmin,
  });

  static String _tipoLabel(String tipo) => switch (tipo) {
    'cotizacion' => 'Cotización',
    'pago'       => 'Pago',
    'reserva'    => 'Reserva',
    'sistema'    => 'Sistema',
    _            => 'General',
  };

  @override
  Widget build(BuildContext context) {
    final n = notificacion;
    final (icon, color) = switch (n.tipo) {
      'cotizacion' => (Icons.request_quote_rounded,  const Color(0xFF7C3AED)),
      'pago'       => (Icons.payments_rounded,        const Color(0xFF059669)),
      'reserva'    => (Icons.airplane_ticket_rounded, context.saas.brand600),
      'sistema'    => (Icons.settings_rounded,        context.saas.textSecondary),
      _            => (Icons.campaign_rounded,         const Color(0xFFD97706)),
    };

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabecera ──────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          n.titulo,
                          style: TextStyle(
                            color: context.saas.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _SmallBadge(
                              label: _tipoLabel(n.tipo),
                              color: color,
                            ),
                            if (n.esGeneral)
                              _SmallBadge(
                                label: 'General',
                                color: context.saas.textTertiary,
                              )
                            else
                              _SmallBadge(
                                label: 'Personal',
                                color: context.saas.brand600,
                              ),
                            _SmallBadge(
                              label: n.leida ? 'Leída' : 'No leída',
                              color: n.leida
                                  ? context.saas.textTertiary
                                  : context.saas.danger,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: context.saas.textSecondary,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              Divider(color: context.saas.border, height: 1),
              const SizedBox(height: 18),

              // ── Mensaje completo ──────────────────────────────────────────
              Text(
                'Mensaje',
                style: TextStyle(
                  color: context.saas.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                n.mensaje,
                style: TextStyle(
                  color: context.saas.textPrimary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 18),
              Divider(color: context.saas.border, height: 1),
              const SizedBox(height: 14),

              // ── Metadatos ─────────────────────────────────────────────────
              _MetaRow(
                icon: Icons.schedule_rounded,
                label: 'Fecha',
                value: DateFormat('dd/MM/yyyy – HH:mm', 'es_CO')
                    .format(n.createdAt),
              ),
              const SizedBox(height: 8),
              _MetaRow(
                icon: Icons.label_rounded,
                label: 'Tipo',
                value: _tipoLabel(n.tipo),
              ),
              if (isAdmin && n.usuarioId != null) ...[
                const SizedBox(height: 8),
                _MetaRow(
                  icon: Icons.person_rounded,
                  label: 'Usuario ID',
                  value: n.usuarioId.toString(),
                ),
              ],
              if (isAdmin && n.creadoBy != null) ...[
                const SizedBox(height: 8),
                _MetaRow(
                  icon: Icons.manage_accounts_rounded,
                  label: 'Creado por',
                  value: n.creadoBy.toString(),
                ),
              ],
              if (isAdmin) ...[
                const SizedBox(height: 8),
                _MetaRow(
                  icon: Icons.tag_rounded,
                  label: 'ID',
                  value: '#${n.id}',
                ),
              ],

              const SizedBox(height: 20),

              // ── Botón cerrar ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.saas.brand600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontWeight: FontWeight.w600),
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

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: context.saas.textTertiary),
        const SizedBox(width: 6),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: context.saas.textTertiary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: context.saas.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
