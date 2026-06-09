import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
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
            onTap: () => _showPanel(context),
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
                        ? SaasPalette.brand600
                        : SaasPalette.textSecondary,
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
                        decoration: const BoxDecoration(
                          color: SaasPalette.danger,
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
      pageBuilder: (ctx, _, __) => BlocProvider.value(
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
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
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
            const Divider(height: 1, color: SaasPalette.border),
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
              const Icon(
                Icons.notifications_rounded,
                size: 18,
                color: SaasPalette.brand600,
              ),
              const SizedBox(width: 8),
              const Text(
                'Notificaciones',
                style: TextStyle(
                  color: SaasPalette.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: SaasPalette.danger,
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
                  child: const Text(
                    'Leer todo',
                    style: TextStyle(
                      fontSize: 12,
                      color: SaasPalette.brand600,
                    ),
                  ),
                ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: SaasPalette.textSecondary,
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

  Widget _buildList(BuildContext context) {
    return BlocBuilder<NotificacionBloc, NotificacionState>(
      builder: (context, state) {
        if (state is NotificacionCargando) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SaasPalette.brand600,
              ),
            ),
          );
        }

        final items = state is NotificacionesCargadas ? state.items : <Notificacion>[];

        if (items.isEmpty) {
          return const SizedBox(
            height: 140,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 36,
                    color: SaasPalette.textTertiary,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sin notificaciones',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
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
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: SaasPalette.border),
          itemBuilder: (ctx, i) => _NotificacionTile(
            notificacion: items[i],
            isAdmin: isAdmin,
            onTap: () {
              if (!items[i].leida) {
                context.read<NotificacionBloc>().add(MarcarLeida(items[i].id));
              }
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

class _NotificacionTile extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final unread = !notificacion.leida;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: unread
            ? SaasPalette.brand600.withValues(alpha: 0.04)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TipoIcon(tipo: notificacion.tipo),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notificacion.titulo,
                          style: TextStyle(
                            color: SaasPalette.textPrimary,
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
                          decoration: const BoxDecoration(
                            color: SaasPalette.brand600,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    notificacion.mensaje,
                    style: const TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (notificacion.esGeneral)
                        _SmallBadge(
                          label: 'General',
                          color: SaasPalette.textTertiary,
                        ),
                      if (notificacion.esGeneral) const SizedBox(width: 6),
                      Text(
                        _formatTime(notificacion.createdAt),
                        style: const TextStyle(
                          color: SaasPalette.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                color: SaasPalette.textTertiary,
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays < 7) return 'Hace ${diff.inDays}d';
    return DateFormat('dd MMM', 'es_CO').format(dt);
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
      'reserva' => (Icons.airplane_ticket_rounded, SaasPalette.brand600),
      'sistema' => (Icons.settings_rounded, SaasPalette.textSecondary),
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
