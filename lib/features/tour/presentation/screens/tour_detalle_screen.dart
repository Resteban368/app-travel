import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:web/web.dart' as webLib;
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/dialog_loading_widget.dart';
import '../../domain/entities/tour.dart' hide ItineraryDay;
import '../../domain/entities/tour_detalle.dart';
import '../../domain/entities/tour_salida.dart';
import '../../domain/repositories/tour_repository.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../../reservas/domain/repositories/reserva_repository.dart';
import '../../../reservas/presentation/pdf/reserva_pdf_generator.dart';
import '../../../service/domain/repositories/service_repository.dart';
import '../../../../config/app_router.dart';

class TourDetalleScreen extends StatefulWidget {
  final Tour tour;
  const TourDetalleScreen({super.key, required this.tour});

  @override
  State<TourDetalleScreen> createState() => _TourDetalleScreenState();
}

class _TourDetalleScreenState extends State<TourDetalleScreen> {
  TourDetalle? _detalle;
  Object? _loadError;
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  List<TourSalida> _salidas = [];

  final _currency = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(
      () => setState(() => _searchQuery = _searchCtrl.text),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    // Mostrar diálogo de carga premium
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const DialogLoadingNetwork(titel: 'Cargando detalle del tour...'),
    );

    try {
      final futures = <Future>[
        sl<TourRepository>().getTourDetalle(widget.tour.id),
        if (widget.tour.disponibilidadTipo == 'multiples_fechas')
          sl<TourRepository>().getTourSalidas(widget.tour.id),
      ];
      final results = await Future.wait(futures);
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cerrar diálogo
        setState(() {
          _detalle = results[0] as TourDetalle;
          if (widget.tour.disponibilidadTipo == 'multiples_fechas') {
            _salidas = (results[1] as List<TourSalida>).where((s) => s.isActive).toList();
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Cerrar diálogo
        setState(() {
          _loadError = e;
          _loading = false;
        });
      }
    }
  }

  List<ReservaDetalle> get _filteredReservas {
    var list = List<ReservaDetalle>.from(_detalle?.reservas ?? []);
    list.sort((a, b) => a.fechaCreacion.compareTo(b.fechaCreacion));
    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (r) =>
                r.responsable.nombre.toLowerCase().contains(q) ||
                r.responsable.documento.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final reservas = _filteredReservas;

    return Scaffold(
      backgroundColor: context.saas.bgApp,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverToBoxAdapter(child: _buildCuposHeader()),
          ),
          if (widget.tour.precios != null && widget.tour.precios!.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(child: _buildTablaPreciosTour()),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            sliver: SliverToBoxAdapter(child: _buildSearchBar()),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: _buildReservasList(reservas),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final active = _searchQuery.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? context.saas.brand600 : context.saas.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(color: context.saas.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o cédula del responsable...',
          hintStyle: TextStyle(
            color: context.saas.textTertiary,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: active ? context.saas.brand600 : context.saas.textTertiary,
            size: 20,
          ),
          suffixIcon: active
              ? IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: context.saas.textTertiary,
                    size: 18,
                  ),
                  onPressed: () => _searchCtrl.clear(),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildReservasList(List<ReservaDetalle> reservas) {
    if (_loading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, _) => _SkelCard(),
          childCount: 3,
        ),
      );
    }
    if (_loadError != null) {
      return SliverFillRemaining(
        child: _ErrorState(message: _loadError.toString(), onRetry: _load),
      );
    }
    if (reservas.isEmpty) {
      return SliverFillRemaining(
        child: _searchQuery.isNotEmpty
            ? _EmptySearch(query: _searchQuery)
            : const _EmptyState(),
      );
    }

    if (widget.tour.disponibilidadTipo == 'multiples_fechas') {
      return _buildReservasAgrupadas(reservas);
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => _ReservaCard(
          reserva: reservas[i],
          currency: _currency,
          tour: widget.tour,
        ),
        childCount: reservas.length,
      ),
    );
  }

  Widget _buildReservasAgrupadas(List<ReservaDetalle> reservas) {
    // Agrupar por idTourSalida
    final Map<int?, List<ReservaDetalle>> grupos = {};
    for (final r in reservas) {
      grupos.putIfAbsent(r.idTourSalida, () => []).add(r);
    }

    // Ordenar grupos: salidas conocidas por fecha, sin salida al final
    final salidaIds = grupos.keys
        .where((id) => id != null)
        .cast<int>()
        .toList()
      ..sort((a, b) {
        final sa = _salidas.firstWhere((s) => s.id == a, orElse: () => _salidas.first);
        final sb = _salidas.firstWhere((s) => s.id == b, orElse: () => _salidas.first);
        return sa.fechaInicio.compareTo(sb.fechaInicio);
      });
    if (grupos.containsKey(null)) salidaIds.add(-1); // sentinel para sin salida

    // Construir lista plana de widgets
    final items = <Widget>[];
    for (final idKey in salidaIds) {
      final salidaId = idKey == -1 ? null : idKey;
      final group = grupos[salidaId] ?? [];
      final salida = salidaId != null
          ? _salidas.where((s) => s.id == salidaId).firstOrNull
          : null;

      items.add(_SalidaGroupHeader(
        salida: salida,
        salidaId: salidaId,
        count: group.length,
        tourId: int.tryParse(widget.tour.id),
      ));
      for (final r in group) {
        items.add(_ReservaCard(reserva: r, currency: _currency, tour: widget.tour));
      }
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) => items[i],
        childCount: items.length,
      ),
    );
  }

  Widget _buildTablaPreciosTour() {
    final fmt = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sell_rounded, color: context.saas.brand600, size: 18),
              SizedBox(width: 8),
              Text(
                'TABLA DE PRECIOS',
                style: TextStyle(
                  color: context.saas.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...widget.tour.precios!.map((p) {
            final edadStr = (p.edadMin != null || p.edadMax != null)
                ? '${p.edadMin ?? 0}-${p.edadMax ?? '∞'} años'
                : null;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.descripcion,
                          style: TextStyle(
                            color: context.saas.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (edadStr != null || p.puntoPartida != null)
                          Text(
                            [
                              if (edadStr != null) edadStr,
                              if (p.puntoPartida != null)
                                'desde ${p.puntoPartida}',
                            ].join(' · '),
                            style: TextStyle(
                              color: context.saas.textTertiary,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    fmt.format(p.precio),
                    style: TextStyle(
                      color: context.saas.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return PremiumSliverAppBar(
      title: widget.tour.name ?? "",
      actions: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildCuposHeader() {
    final cupos = widget.tour.cupos;
    final disponibles = widget.tour.cuposDisponibles;

    if (cupos == null) return const SizedBox.shrink();

    final usados = cupos - (disponibles ?? cupos);
    final porcentajeUsado = cupos > 0 ? usados / cupos : 0.0;
    final Color barColor = porcentajeUsado >= 1.0
        ? context.saas.danger
        : porcentajeUsado >= 0.8
        ? context.saas.warning
        : context.saas.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.saas.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatChip(
                label: 'Cupos totales',
                value: '$cupos',
                color: context.saas.brand600,
                icon: Icons.event_seat_rounded,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Ocupados',
                value: '$usados',
                color: context.saas.warning,
                icon: Icons.people_rounded,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Disponibles',
                value: '${disponibles ?? (cupos - usados)}',
                color: barColor,
                icon: Icons.chair_alt_rounded,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: porcentajeUsado.clamp(0.0, 1.0),
              backgroundColor: context.saas.bgSubtle,
              color: barColor,
              minHeight: 8,
            ),
          ),
          // Manifiesto: tour fecha_fija con buses asignados al tour
          if (widget.tour.disponibilidadTipo != 'multiples_fechas' &&
              widget.tour.busLayoutIds!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _ManifiestoButton(
              label: 'Ver manifiesto de bus',
              onTap: () => Navigator.pushNamed(
                context,
                AppRouter.busManifiesto,
                arguments: {'tourId': int.parse(widget.tour.id)},
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SalidaGroupHeader extends StatelessWidget {
  final TourSalida? salida;
  final int? salidaId;
  final int count;
  final int? tourId;

  const _SalidaGroupHeader({
    required this.salida,
    required this.salidaId,
    required this.count,
    required this.tourId,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'es_CO');

    String title;
    String? subtitle;
    if (salida != null) {
      final fechaIni = DateTime.tryParse(salida!.fechaInicio);
      final fechaFin = DateTime.tryParse(salida!.fechaFin);
      final rango = fechaIni != null && fechaFin != null
          ? '${fmt.format(fechaIni)} → ${fmt.format(fechaFin)}'
          : '${salida!.fechaInicio} → ${salida!.fechaFin}';
      if (salida!.label?.isNotEmpty == true) {
        title = salida!.label!;
        subtitle = rango;
      } else {
        title = rango;
      }
    } else {
      title = 'Sin salida asignada';
    }

    final hasBuses = salida?.buses.isNotEmpty == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: context.saas.brand600.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_month_rounded,
                  size: 15,
                  color: context.saas.brand600,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.saas.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: context.saas.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.saas.bgSubtle,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.saas.border),
                ),
                child: Text(
                  '$count reserva${count == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: context.saas.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (hasBuses && tourId != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: salida!.buses.map((bus) {
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    AppRouter.busManifiesto,
                    arguments: {'tourId': tourId, 'salidaId': salida!.id},
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.saas.brand600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.directions_bus_rounded, size: 13, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          bus.nombre,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${bus.asientosDisponibles}/${bus.totalAsientosCliente}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Divider(color: context.saas.border, height: 1),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ManifiestoButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ManifiestoButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.saas.brand600, context.saas.brand900],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: context.saas.brand600.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bus_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: context.saas.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservaCard extends StatefulWidget {
  final ReservaDetalle reserva;
  final NumberFormat currency;
  final Tour tour;
  const _ReservaCard({
    required this.reserva,
    required this.currency,
    required this.tour,
  });

  @override
  State<_ReservaCard> createState() => _ReservaCardState();
}

class _ReservaCardState extends State<_ReservaCard> {
  bool _expanded = false;
  bool _generatingPdf = false;

  bool _showBusSection(ReservaDetalle reserva) {
    final tipo = widget.tour.disponibilidadTipo;
    if (tipo == 'fecha_fija') return widget.tour.busLayoutIds.isNotEmpty;
    if (tipo == 'multiples_fechas') {
      return reserva.seleccionLink?.isNotEmpty == true;
    }
    return false;
  }

  String? _getFechasReserva(ReservaDetalle reserva, String disponibilidadTipo) {
    if (disponibilidadTipo == 'permanente') {
      final ini = reserva.fechaInicioPersonalizada;
      final fin = reserva.fechaFinPersonalizada;
      if (ini != null && fin != null) return '$ini → $fin';
      return null;
    }
    if (disponibilidadTipo == 'multiples_fechas') {
      final salida = reserva.tourSalida;
      if (salida != null) {
        final label = salida.label != null ? ' (${salida.label})' : '';
        return '${salida.fechaInicio} → ${salida.fechaFin}$label';
      }
      return null;
    }
    return null;
  }

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
        widget.reserva.id.toString(),
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
          backgroundColor: context.saas.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _generatingPdf = false);
    }
  }

  Future<void> _showPdfPreviewDialog(List<int> bytes) async {
    final dateStr = DateFormat('dd-MM-yyyy').format(DateTime.now());
    final filename = 'Reserva_${widget.reserva.idReserva}_$dateStr.pdf';
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
        backgroundColor: context.saas.bgCanvas,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.saas.brand50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: context.saas.brand600,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PDF Listo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.saas.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                filename,
                style: TextStyle(
                  fontSize: 13,
                  color: context.saas.textTertiary,
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
                        foregroundColor: context.saas.brand600,
                        side: BorderSide(color: context.saas.brand600),
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
                        backgroundColor: context.saas.brand600,
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
                child: Text(
                  'Cerrar',
                  style: TextStyle(color: context.saas.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color get _estadoColor {
    switch (widget.reserva.estado.toLowerCase()) {
      case 'al dia':
        return context.saas.success;
      case 'pendiente':
        return context.saas.warning;
      case 'cancelado':
        return context.saas.danger;
      default:
        return context.saas.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserva = widget.reserva;
    final dateLabel = DateFormat('dd/MM/yyyy').format(reserva.fechaCreacion);
    final fechasReserva = _getFechasReserva(reserva, widget.tour.disponibilidadTipo);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reserva.ocupaCupo
              ? context.saas.border
              : context.saas.danger.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                reserva.responsable.nombre,
                                style: TextStyle(
                                  color: context.saas.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            _EstadoBadge(
                              label: reserva.estado.toUpperCase(),
                              color: _estadoColor,
                            ),
                            if (!reserva.ocupaCupo) ...[
                              const SizedBox(width: 6),
                              _EstadoBadge(
                                label: 'SIN CUPO',
                                color: context.saas.danger,
                              ),
                            ],
                            const SizedBox(width: 6),
                            if (_showBusSection(reserva) && reserva.asientosBus.isEmpty)
                              _EstadoBadge(
                                label: 'SIN ASIENTOS',
                                color: context.saas.warning,
                              ),
                          ],
                        ),
                        //cedula del responsable
                        Row(
                          children: [
                            Text(
                              "${reserva.responsable.tipoDocumento} ",
                              style: TextStyle(
                                color: context.saas.brand600,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              reserva.responsable.documento,
                              style: TextStyle(
                                color: context.saas.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                        Text(
                          'Creada $dateLabel · ${reserva.totalPersonas} persona${reserva.totalPersonas != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: context.saas.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Reserva: #${reserva.idReserva}',
                          style: TextStyle(
                            color: context.saas.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        if (fechasReserva != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                size: 12,
                                color: context.saas.brand600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                fechasReserva,
                                style: TextStyle(
                                  color: context.saas.brand600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _generatingPdf ? null : _generateAndShowPdf,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: _generatingPdf
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.saas.brand600,
                              ),
                            )
                          : Icon(
                              Icons.picture_as_pdf_rounded,
                              color: context.saas.brand600,
                              size: 20,
                            ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: context.saas.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            Divider(color: context.saas.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FinancieroRow(
                    total: reserva.valorTotal,
                    cancelado: reserva.valorCancelado,
                    saldo: reserva.saldoPendiente,
                    currency: widget.currency,
                  ),
                  const SizedBox(height: 16),
                  _DesgloseCard(reserva: reserva, currency: widget.currency),
                  const SizedBox(height: 16),

                  // Sección de Asientos
                  if (_showBusSection(reserva)) ...[
                  const _SectionLabel(label: 'ASIENTOS'),
                  const SizedBox(height: 8),
                  if (reserva.asientosBus.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: reserva.asientosBus
                          .map(
                            (asiento) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: context.saas.brand600.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: context.saas.brand600.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.event_seat_rounded,
                                    color: context.saas.brand600,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    asiento,
                                    style: TextStyle(
                                      color: context.saas.brand600,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: context.saas.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.saas.warning.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: context.saas.warning,
                            size: 16,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Falta por asignar asientos',
                            style: TextStyle(
                              color: context.saas.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ], // end busLayoutIds.isNotEmpty
                  if (reserva.seleccionLink != null &&
                      reserva.seleccionLink!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.saas.brand50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: context.saas.brand600.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.link_rounded,
                            color: context.saas.brand600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              reserva.seleccionLink!,
                              style: TextStyle(
                                color: context.saas.brand600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                ClipboardData(text: reserva.seleccionLink!),
                              );
                              SaasSnackBar.showSuccess(
                                context,
                                'Link copiado al portapapeles',
                              );
                            },
                            child: Icon(
                              Icons.copy_rounded,
                              color: context.saas.brand600,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  if (reserva.notas != null && reserva.notas!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.sticky_note_2_rounded,
                          color: context.saas.textTertiary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reserva.notas!,
                            style: TextStyle(
                              color: context.saas.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  const _SectionLabel(label: 'RESPONSABLE'),
                  const SizedBox(height: 8),
                  _PersonaRow(
                    nombre: reserva.responsable.nombre,
                    telefono: reserva.responsable.telefono,
                    tipoDoc: reserva.responsable.tipoDocumento,
                    documento: reserva.responsable.documento,
                    correo: reserva.responsable.correo,
                    isResponsable: true,
                  ),

                  if (reserva.integrantes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _SectionLabel(
                      label: 'INTEGRANTES (${reserva.integrantes.length})',
                    ),
                    const SizedBox(height: 8),
                    ...reserva.integrantes.map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _PersonaRow(
                          nombre: i.nombre,
                          telefono: i.telefono,
                          tipoDoc: i.tipoDocumento,
                          documento: i.documento,
                          fechaNacimiento: i.fechaNacimiento,
                          isResponsable: false,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DesgloseCard extends StatelessWidget {
  final ReservaDetalle reserva;
  final NumberFormat currency;

  const _DesgloseCard({required this.reserva, required this.currency});

  @override
  Widget build(BuildContext context) {
    final hasServicios =
        reserva.servicios.isNotEmpty || reserva.costoServicios > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                color: context.saas.textTertiary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                'DESGLOSE DE COSTOS',
                style: TextStyle(
                  color: context.saas.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _DesgloseRow(
            label: 'Valor del tour',
            value: currency.format(reserva.valorTourSnapshot),
            valueColor: context.saas.textPrimary,
            icon: Icons.confirmation_number_rounded,
          ),

          if (hasServicios) ...[
            const SizedBox(height: 4),
            Divider(color: context.saas.border, height: 12),
            if (reserva.servicios.isNotEmpty)
              ...reserva.servicios.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _DesgloseRow(
                    label: s.nombre,
                    value: s.costo != null ? currency.format(s.costo) : '—',
                    valueColor: context.saas.brand600,
                    icon: Icons.add_circle_outline_rounded,
                  ),
                ),
              )
            else
              _DesgloseRow(
                label: 'Servicios adicionales',
                value: currency.format(reserva.costoServicios),
                valueColor: context.saas.brand600,
                icon: Icons.add_circle_outline_rounded,
              ),
          ],

          Divider(color: context.saas.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total contratado',
                style: TextStyle(
                  color: context.saas.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                currency.format(reserva.valorTotal),
                style: TextStyle(
                  color: context.saas.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesgloseRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData icon;

  const _DesgloseRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.icon = Icons.confirmation_number_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: context.saas.textTertiary, size: 13),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.saas.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FinancieroRow extends StatelessWidget {
  final double total;
  final double cancelado;
  final double saldo;
  final NumberFormat currency;
  const _FinancieroRow({
    required this.total,
    required this.cancelado,
    required this.saldo,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: Row(
        children: [
          _Money(
            label: 'Total',
            value: currency.format(total),
            color: context.saas.textPrimary,
          ),
          _Divider(),
          _Money(
            label: 'Cancelado',
            value: currency.format(cancelado),
            color: context.saas.success,
          ),
          _Divider(),
          _Money(
            label: 'Saldo',
            value: currency.format(saldo),
            color: saldo > 0 ? context.saas.warning : context.saas.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _Money extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Money({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: context.saas.textTertiary, fontSize: 10),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 28,
    color: context.saas.border,
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

class _PersonaRow extends StatelessWidget {
  final String nombre;
  final String? telefono;
  final String tipoDoc;
  final String documento;
  final String? correo;
  final String? fechaNacimiento;
  final bool isResponsable;

  const _PersonaRow({
    required this.nombre,
    this.telefono,
    required this.tipoDoc,
    required this.documento,
    this.correo,
    this.fechaNacimiento,
    required this.isResponsable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isResponsable ? context.saas.brand50 : context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isResponsable
              ? context.saas.brand600.withValues(alpha: 0.2)
              : context.saas.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isResponsable
                  ? context.saas.brand600.withValues(alpha: 0.15)
                  : context.saas.border,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isResponsable
                  ? Icons.manage_accounts_rounded
                  : Icons.person_rounded,
              color: isResponsable
                  ? context.saas.brand600
                  : context.saas.textTertiary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _Detail(
                      icon: Icons.badge_rounded,
                      text: '$tipoDoc $documento',
                    ),
                    if (telefono != null)
                      _Detail(icon: Icons.phone_rounded, text: telefono!),
                    if (correo != null)
                      _Detail(icon: Icons.email_rounded, text: correo!),
                    if (fechaNacimiento != null)
                      _Detail(
                        icon: Icons.cake_rounded,
                        text: _formatDate(fechaNacimiento!),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }
}

class _Detail extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Detail({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: context.saas.textTertiary, size: 12),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(color: context.saas.textSecondary, fontSize: 11),
      ),
    ],
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(
      color: context.saas.textTertiary,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.8,
    ),
  );
}

class _EstadoBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _EstadoBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.35)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _SkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 120,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: context.saas.bgSubtle,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: context.saas.border),
    ),
  );
}

class _EmptySearch extends StatelessWidget {
  final String query;
  const _EmptySearch({required this.query});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 64,
          color: context.saas.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          'Sin resultados para "$query"',
          style: TextStyle(
            color: context.saas.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Intenta con otro nombre o cédula',
          style: TextStyle(color: context.saas.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.people_outline_rounded,
          size: 72,
          color: context.saas.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          'No hay reservas para este tour',
          style: TextStyle(
            color: context.saas.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 72,
          color: context.saas.danger,
        ),
        const SizedBox(height: 16),
        Text(
          'Error al cargar los datos',
          style: TextStyle(
            color: context.saas.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(
            color: context.saas.textSecondary,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.saas.brand600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );
}
