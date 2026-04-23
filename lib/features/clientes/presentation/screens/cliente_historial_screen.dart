import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as webLib;
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../../../core/widgets/dialog_loading_widget.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/cliente.dart';
import '../../domain/entities/cliente_historial.dart';
import '../../../reservas/domain/entities/reserva.dart';
import '../../../reservas/domain/repositories/reserva_repository.dart';
import '../../../reservas/presentation/pdf/reserva_pdf_generator.dart';
import '../../../service/domain/repositories/service_repository.dart';
import '../bloc/historial/cliente_historial_bloc.dart';
import '../bloc/historial/cliente_historial_event.dart';
import '../bloc/historial/cliente_historial_state.dart';

class ClienteHistorialScreen extends StatefulWidget {
  final Cliente cliente;
  const ClienteHistorialScreen({super.key, required this.cliente});

  @override
  State<ClienteHistorialScreen> createState() => _ClienteHistorialScreenState();
}

class _ClienteHistorialScreenState extends State<ClienteHistorialScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ClienteHistorialBloc>().add(LoadClienteHistorial(widget.cliente.id!));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocBuilder<ClienteHistorialBloc, ClienteHistorialState>(
        builder: (context, state) {
          return CustomScrollView(
            slivers: [
              PremiumSliverAppBar(
                title: 'Historial - ${widget.cliente.nombre}',
                actions: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              if (state is ClienteHistorialLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: SaasPalette.brand600)),
                )
              else if (state is ClienteHistorialError)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: SaasPalette.danger, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar historial',
                          style: TextStyle(color: SaasPalette.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Text(state.message, style: const TextStyle(color: SaasPalette.textSecondary)),
                        const SizedBox(height: 24),
                        SaasButton(
                          label: 'Reintentar',
                          onPressed: () => context.read<ClienteHistorialBloc>().add(LoadClienteHistorial(widget.cliente.id!)),
                        ),
                      ],
                    ),
                  ),
                )
              else if (state is ClienteHistorialLoaded)
                ...[
                  _buildStats(state.historial),
                  _buildReservas(state.historial.reservas),
                ]
              else
                const SliverToBoxAdapter(child: SizedBox()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStats(ClienteHistorial historial) {
    final totalInversion = historial.reservas.fold<double>(0, (sum, r) => sum + (r.valorTotal ?? 0));
    
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            _StatCard(
              label: 'Total Viajes',
              value: historial.totalViajes.toString(),
              icon: Icons.flight_takeoff_rounded,
              color: SaasPalette.brand600,
            ),
            const SizedBox(width: 16),
            _StatCard(
              label: 'Inversión Total',
              value: NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(totalInversion),
              icon: Icons.payments_outlined,
              color: SaasPalette.success,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservas(List<Reserva> reservas) {
    if (reservas.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: SaasEmptyState(
          icon: Icons.airplanemode_inactive_rounded,
          title: 'Sin viajes aún',
          subtitle: 'Este cliente no tiene reservas registradas.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _HistorialCard(reserva: reservas[index]),
          childCount: reservas.length,
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SaasPalette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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

class _HistorialCard extends StatefulWidget {
  final Reserva reserva;
  const _HistorialCard({required this.reserva});

  @override
  State<_HistorialCard> createState() => _HistorialCardState();
}

class _HistorialCardState extends State<_HistorialCard> {
  bool _generatingPdf = false;

  Future<void> _generateAndShowPdf() async {
    setState(() => _generatingPdf = true);
    final rootNav = Navigator.of(context, rootNavigator: true);
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) =>
          const DialogLoadingNetwork(titel: 'Generando PDF de Reserva'),
    );
    try {
      final fullReserva = await sl<ReservaRepository>().getReservaById(
        widget.reserva.id!,
      );
      final allServices = await sl<ServiceRepository>().getServices();
      final bytes = await ReservaPdfGenerator.generate(
        fullReserva,
        servicios: allServices,
      );
      if (!mounted) return;
      rootNav.pop();
      await _showPdfPreviewDialog(bytes);
    } catch (e) {
      if (mounted) rootNav.pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generando PDF: $e'),
          backgroundColor: SaasPalette.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _showPdfPreviewDialog(List<int> bytes) async {
    final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final filename =
        'Reserva_${widget.reserva.idReserva ?? widget.reserva.id}_$dateStr.pdf';
    final uint8Bytes = Uint8List.fromList(bytes);

    void openInNewTab() {
      final blob = webLib.Blob(
        <JSAny>[uint8Bytes.buffer.toJS].toJS,
        webLib.BlobPropertyBag(type: 'application/pdf'),
      );
      final url = webLib.URL.createObjectURL(blob);
      webLib.window.open(url, '_blank', '');
    }

    void download() {
      final blob = webLib.Blob(
        <JSAny>[uint8Bytes.buffer.toJS].toJS,
        webLib.BlobPropertyBag(type: 'application/pdf'),
      );
      final url = webLib.URL.createObjectURL(blob);
      final anchor =
          webLib.document.createElement('a') as webLib.HTMLAnchorElement;
      anchor.href = url;
      anchor.download = filename;
      anchor.click();
      webLib.URL.revokeObjectURL(url);
    }

    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => Dialog(
        backgroundColor: SaasPalette.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  color: SaasPalette.brand50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: SaasPalette.brand600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'PDF Listo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SaasPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                filename,
                style: const TextStyle(
                  fontSize: 13,
                  color: SaasPalette.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Ver PDF'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: SaasPalette.brand600,
                        side: const BorderSide(color: SaasPalette.brand600),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: openInNewTab,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Descargar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SaasPalette.brand600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: download,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: SaasPalette.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final date = DateFormat('dd MMM yyyy').format(widget.reserva.fechaCreacion);

    Color statusColor;
    switch (widget.reserva.estado.toLowerCase()) {
      case 'al dia':
      case 'al día':
        statusColor = SaasPalette.success;
        break;
      case 'pendiente':
        statusColor = SaasPalette.warning;
        break;
      case 'cancelado':
        statusColor = SaasPalette.danger;
        break;
      default:
        statusColor = SaasPalette.textTertiary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: SaasPalette.bgSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.reserva.tipoReserva == 'tour'
                  ? Icons.map_outlined
                  : Icons.flight_outlined,
              color: SaasPalette.brand600,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.reserva.idReserva ?? 'ID: ${widget.reserva.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: SaasPalette.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.reserva.estado.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.reserva.tour?.name ??
                      (widget.reserva.tipoReserva == 'tour'
                          ? 'Tour'
                          : 'Reserva de Vuelos'),
                  style: const TextStyle(
                    color: SaasPalette.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Creado el $date',
                  style: const TextStyle(
                    color: SaasPalette.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currency.format(widget.reserva.valorTotal ?? 0),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: SaasPalette.textPrimary,
                ),
              ),
              if ((widget.reserva.saldoPendiente ?? 0) > 0)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Saldo: ${currency.format(widget.reserva.saldoPendiente)}',
                    style: const TextStyle(
                      color: SaasPalette.danger,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _generatingPdf ? null : _generateAndShowPdf,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: _generatingPdf
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SaasPalette.brand600,
                          ),
                        )
                      : const Icon(
                          Icons.picture_as_pdf_rounded,
                          color: SaasPalette.brand600,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
