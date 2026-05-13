import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/features/saldos_pendientes/presentation/bloc/saldo_pendiente_detail_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/saldo_pendiente.dart';

class SaldoPendienteDetailScreen extends StatefulWidget {
  final TourConSaldo tour;
  const SaldoPendienteDetailScreen({super.key, required this.tour});

  @override
  State<SaldoPendienteDetailScreen> createState() => _SaldoPendienteDetailScreenState();
}

class _SaldoPendienteDetailScreenState extends State<SaldoPendienteDetailScreen> {
  final _currFmt = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    context.read<SaldoPendienteDetailBloc>().add(LoadReservasPorTour(widget.tour.tourId));
  }

  String _formatFecha(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd/MM/yyyy', 'es_CO').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tour.tourNombre,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (widget.tour.fechaTour != null)
              Text(
                _formatFecha(widget.tour.fechaTour),
                style: const TextStyle(fontSize: 12, color: SaasPalette.textSecondary),
              ),
          ],
        ),
        backgroundColor: SaasPalette.bgCanvas,
        foregroundColor: SaasPalette.textPrimary,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: SaasPalette.border)),
      ),
      body: BlocConsumer<SaldoPendienteDetailBloc, SaldoPendienteDetailState>(
        listener: (context, state) {
          if (state is RecordatorioEnviadoDetail) {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Recordatorio enviado a ${state.result.responsable}'),
                backgroundColor: SaasPalette.success,
              ),
            );
          } else if (state is RecordatorioFallidoDetail) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: SaasPalette.danger,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is SaldoPendienteDetailLoading) {
            return const Center(child: CircularProgressIndicator(color: SaasPalette.brand600));
          }
          if (state is SaldoPendienteDetailError) {
            return Center(child: Text(state.message));
          }
          if (state is SaldoPendienteDetailLoaded || 
              state is RecordatorioEnviandoDetail || 
              state is RecordatorioEnviadoDetail || 
              state is RecordatorioFallidoDetail) {
            
            final List<SaldoPendiente> reservas = (state is SaldoPendienteDetailLoaded) 
                ? state.reservas 
                : (state as dynamic).previousReservas;

            if (reservas.isEmpty) {
              return const Center(child: Text('No hay reservas con saldo pendiente.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reservas.length,
              itemBuilder: (context, index) {
                return _ReservaCard(
                  reserva: reservas[index],
                  currFmt: _currFmt,
                  formatFecha: _formatFecha,
                );
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _ReservaCard extends StatefulWidget {
  final SaldoPendiente reserva;
  final NumberFormat currFmt;
  final String Function(String?) formatFecha;

  const _ReservaCard({
    required this.reserva, 
    required this.currFmt,
    required this.formatFecha,
  });

  @override
  State<_ReservaCard> createState() => _ReservaCardState();
}

class _ReservaCardState extends State<_ReservaCard> {
  bool _pagosExpanded = false;

  @override
  Widget build(BuildContext context) {
    final reserva = widget.reserva;
    final currFmt = widget.currFmt;
    final pct = reserva.valorTotal > 0
        ? (reserva.totalPagado / reserva.valorTotal).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SaasPalette.border),
      ),
      elevation: 0,
      color: SaasPalette.bgCanvas,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── ID y Estado ──
            Row(
              children: [
                Text(
                  reserva.idReserva,
                  style: const TextStyle(
                    color: SaasPalette.brand600,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                _EstadoBadge(estado: reserva.estado),
                const Spacer(),
                _WhatsAppReminderButton(reserva: reserva),
              ],
            ),
            const SizedBox(height: 12),

            // ── Responsable Info ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_rounded, size: 16, color: SaasPalette.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reserva.responsable.nombre,
                        style: const TextStyle(
                          color: SaasPalette.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '${reserva.responsable.tipoDocumento} ${reserva.responsable.documento}',
                            style: const TextStyle(fontSize: 12, color: SaasPalette.textSecondary),
                          ),
                          if (reserva.responsable.telefono.isNotEmpty) ...[
                            const SizedBox(width: 12),
                            const Icon(Icons.phone_rounded, size: 12, color: SaasPalette.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              reserva.responsable.telefono,
                              style: const TextStyle(fontSize: 12, color: SaasPalette.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Montos y Último Pago ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MontoLabel(label: 'Total', value: currFmt.format(reserva.valorTotal)),
                _MontoLabel(label: 'Pagado', value: currFmt.format(reserva.totalPagado), color: SaasPalette.success),
                _MontoLabel(label: 'Saldo', value: currFmt.format(reserva.saldoPendiente), color: SaasPalette.danger),
              ],
            ),
            if (reserva.ultimaFechaPago != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 12, color: SaasPalette.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    'Último pago: ${widget.formatFecha(reserva.ultimaFechaPago)}',
                    style: const TextStyle(fontSize: 11, color: SaasPalette.textTertiary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),

            // ── Progreso ──
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: SaasPalette.bgSubtle,
                      color: pct >= 1.0 ? SaasPalette.success : (pct >= 0.5 ? SaasPalette.warning : SaasPalette.danger),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: SaasPalette.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Recordatorios ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SaasPalette.bgSubtle,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, size: 14, color: SaasPalette.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reserva.totalRecordatorios == 0 
                            ? 'Sin recordatorios enviados' 
                            : '${reserva.totalRecordatorios} recordatorio${reserva.totalRecordatorios != 1 ? 's' : ''} enviado${reserva.totalRecordatorios != 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SaasPalette.textPrimary),
                        ),
                        if (reserva.ultimoRecordatorio != null)
                          Text(
                            'Último: ${widget.formatFecha(reserva.ultimoRecordatorio)}',
                            style: const TextStyle(fontSize: 11, color: SaasPalette.textSecondary),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Pagos Expandibles ──
            if (reserva.pagos.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => setState(() => _pagosExpanded = !_pagosExpanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        _pagosExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 20,
                        color: SaasPalette.brand600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ver ${reserva.pagos.length} pago${reserva.pagos.length != 1 ? 's' : ''} registrado${reserva.pagos.length != 1 ? 's' : ''}',
                        style: const TextStyle(color: SaasPalette.brand600, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              if (_pagosExpanded)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: reserva.pagos.map((p) => _PagoItem(pago: p, currFmt: currFmt)).toList(),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MontoLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MontoLabel({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: SaasPalette.textTertiary)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _PagoItem extends StatelessWidget {
  final PagoSaldo pago;
  final NumberFormat currFmt;

  const _PagoItem({required this.pago, required this.currFmt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: SaasPalette.bgApp,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SaasPalette.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                pago.isValidated ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                size: 14,
                color: pago.isValidated ? SaasPalette.success : SaasPalette.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${pago.metodoPago} - ${pago.referencia}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SaasPalette.textPrimary,
                  ),
                ),
              ),
              Text(
                currFmt.format(pago.monto),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: SaasPalette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _PagoDetailLabel(
                icon: Icons.store_rounded,
                label: pago.proveedorComercio.isEmpty ? 'Sin proveedor' : pago.proveedorComercio,
              ),
              if (pago.fechaDocumento != null)
                _PagoDetailLabel(
                  icon: Icons.calendar_today_rounded,
                  label: _formatDate(pago.fechaDocumento!),
                ),
              _PagoDetailLabel(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'ID: ${pago.chatId}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd/MM/yyyy', 'es_CO').format(dt);
    } catch (_) {
      return raw;
    }
  }
}

class _PagoDetailLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PagoDetailLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: SaasPalette.textTertiary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: SaasPalette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final String estado;
  const _EstadoBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color color = SaasPalette.textTertiary;
    if (estado == 'confirmada') color = SaasPalette.success;
    if (estado == 'pendiente') color = SaasPalette.warning;
    if (estado == 'cancelada') color = SaasPalette.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ── Botón WhatsApp Recordatorio ───────────────────────────────────────────────

const _kWhatsApp = SaasPalette.success;

class _WhatsAppReminderButton extends StatelessWidget {
  final SaldoPendiente reserva;
  const _WhatsAppReminderButton({required this.reserva});

  void _confirm(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _RecordatorioDialog(
        reserva: reserva,
        bloc: context.read<SaldoPendienteDetailBloc>(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _confirm(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: _kWhatsApp,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        minimumSize: const Size(100, 30),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/whatsapp.png', width: 14, height: 14),
          const SizedBox(width: 6),
          const Text(
            'Recordatorio',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ── Diálogo de confirmación de recordatorio ───────────────────────────────────

class _RecordatorioDialog extends StatefulWidget {
  final SaldoPendiente reserva;
  final SaldoPendienteDetailBloc bloc;

  const _RecordatorioDialog({required this.reserva, required this.bloc});

  @override
  State<_RecordatorioDialog> createState() => _RecordatorioDialogState();
}

class _RecordatorioDialogState extends State<_RecordatorioDialog> {
  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    widget.bloc.add(EnviarRecordatorioDetail(reservaId: widget.reserva.reservaId));
    
    // Espera el resultado escuchando el bloc
    await for (final state in widget.bloc.stream) {
      if (state is RecordatorioEnviadoDetail || state is RecordatorioFallidoDetail) {
        if (mounted) Navigator.of(context).pop();
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserva = widget.reserva;
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kWhatsApp.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: _kWhatsApp.withValues(alpha: 0.08),
              blurRadius: 32,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kWhatsApp.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/images/whatsapp.png',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enviar recordatorio',
              style: TextStyle(
                color: SaasPalette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '¿Deseas enviar un recordatorio de pago por WhatsApp a '
              '${reserva.responsable.nombre}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: SaasPalette.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (reserva.responsable.telefono.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.phone_rounded,
                    size: 13,
                    color: SaasPalette.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    reserva.responsable.telefono,
                    style: const TextStyle(
                      color: SaasPalette.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _sending
                        ? null
                        : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SaasPalette.textSecondary,
                      side: const BorderSide(color: SaasPalette.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sending ? null : _send,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kWhatsApp,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/whatsapp.png',
                                width: 16,
                                height: 16,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Enviar',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
