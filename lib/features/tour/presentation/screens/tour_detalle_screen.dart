import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/tour.dart' hide ItineraryDay;
import '../../domain/entities/tour_detalle.dart';
import '../../domain/repositories/tour_repository.dart';
import '../../../../core/widgets/premium_form_widgets.dart';

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
    _load();
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
    try {
      final d = await sl<TourRepository>().getTourDetalle(widget.tour.id);
      if (mounted)
        setState(() {
          _detalle = d;
          _loading = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _loadError = e;
          _loading = false;
        });
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
      backgroundColor: SaasPalette.bgApp,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverToBoxAdapter(child: _buildCuposHeader()),
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
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? SaasPalette.brand600 : SaasPalette.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: SaasPalette.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o cédula del responsable...',
          hintStyle: const TextStyle(
            color: SaasPalette.textTertiary,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: active ? SaasPalette.brand600 : SaasPalette.textTertiary,
            size: 20,
          ),
          suffixIcon: active
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: SaasPalette.textTertiary,
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

  Widget _buildAppBar() {
    return PremiumSliverAppBar(
      title: widget.tour.name,
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
        ? SaasPalette.danger
        : porcentajeUsado >= 0.8
        ? SaasPalette.warning
        : SaasPalette.success;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatChip(
                label: 'Cupos totales',
                value: '$cupos',
                color: SaasPalette.brand600,
                icon: Icons.event_seat_rounded,
              ),
              const SizedBox(width: 12),
              _StatChip(
                label: 'Ocupados',
                value: '$usados',
                color: SaasPalette.warning,
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
              backgroundColor: SaasPalette.bgSubtle,
              color: barColor,
              minHeight: 8,
            ),
          ),
        ],
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
              style: const TextStyle(
                color: SaasPalette.textTertiary,
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

  Color get _estadoColor {
    switch (widget.reserva.estado.toLowerCase()) {
      case 'al dia':
        return SaasPalette.success;
      case 'pendiente':
        return SaasPalette.warning;
      case 'cancelado':
        return SaasPalette.danger;
      default:
        return SaasPalette.textTertiary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserva = widget.reserva;
    final dateLabel = DateFormat('dd/MM/yyyy').format(reserva.fechaCreacion);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reserva.ocupaCupo
              ? SaasPalette.border
              : SaasPalette.danger.withValues(alpha: 0.4),
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
                                style: const TextStyle(
                                  color: SaasPalette.textPrimary,
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
                                color: SaasPalette.danger,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Creada $dateLabel · ${reserva.totalPersonas} persona${reserva.totalPersonas != 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: SaasPalette.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Reserva: #${reserva.idReserva}',
                          style: const TextStyle(
                            color: SaasPalette.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: SaasPalette.textTertiary,
                  ),
                ],
              ),
            ),
          ),

          if (_expanded) ...[
            const Divider(color: SaasPalette.border, height: 1),
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

                  if (reserva.notas != null && reserva.notas!.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.sticky_note_2_rounded,
                          color: SaasPalette.textTertiary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reserva.notas!,
                            style: const TextStyle(
                              color: SaasPalette.textSecondary,
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
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                color: SaasPalette.textTertiary,
                size: 14,
              ),
              const SizedBox(width: 6),
              const Text(
                'DESGLOSE DE COSTOS',
                style: TextStyle(
                  color: SaasPalette.textTertiary,
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
            valueColor: SaasPalette.textPrimary,
            icon: Icons.confirmation_number_rounded,
          ),

          if (hasServicios) ...[
            const SizedBox(height: 4),
            const Divider(color: SaasPalette.border, height: 12),
            if (reserva.servicios.isNotEmpty)
              ...reserva.servicios.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: _DesgloseRow(
                    label: s.nombre,
                    value: s.costo != null ? currency.format(s.costo) : '—',
                    valueColor: SaasPalette.brand600,
                    icon: Icons.add_circle_outline_rounded,
                  ),
                ),
              )
            else
              _DesgloseRow(
                label: 'Servicios adicionales',
                value: currency.format(reserva.costoServicios),
                valueColor: SaasPalette.brand600,
                icon: Icons.add_circle_outline_rounded,
              ),
          ],

          const Divider(color: SaasPalette.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total contratado',
                style: TextStyle(
                  color: SaasPalette.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                currency.format(reserva.valorTotal),
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
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
        Icon(icon, color: SaasPalette.textTertiary, size: 13),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: SaasPalette.textSecondary,
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
        color: SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Row(
        children: [
          _Money(
            label: 'Total',
            value: currency.format(total),
            color: SaasPalette.textPrimary,
          ),
          _Divider(),
          _Money(
            label: 'Cancelado',
            value: currency.format(cancelado),
            color: SaasPalette.success,
          ),
          _Divider(),
          _Money(
            label: 'Saldo',
            value: currency.format(saldo),
            color: saldo > 0 ? SaasPalette.warning : SaasPalette.textTertiary,
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
          style: const TextStyle(color: SaasPalette.textTertiary, fontSize: 10),
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
    color: SaasPalette.border,
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
        color: isResponsable ? SaasPalette.brand50 : SaasPalette.bgSubtle,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isResponsable
              ? SaasPalette.brand600.withValues(alpha: 0.2)
              : SaasPalette.border,
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
                  ? SaasPalette.brand600.withValues(alpha: 0.15)
                  : SaasPalette.border,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isResponsable
                  ? Icons.manage_accounts_rounded
                  : Icons.person_rounded,
              color: isResponsable
                  ? SaasPalette.brand600
                  : SaasPalette.textTertiary,
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
                  style: const TextStyle(
                    color: SaasPalette.textPrimary,
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
      Icon(icon, color: SaasPalette.textTertiary, size: 12),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(color: SaasPalette.textSecondary, fontSize: 11),
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
    style: const TextStyle(
      color: SaasPalette.textTertiary,
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
      color: SaasPalette.bgSubtle,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: SaasPalette.border),
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
        const Icon(
          Icons.search_off_rounded,
          size: 64,
          color: SaasPalette.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          'Sin resultados para "$query"',
          style: const TextStyle(
            color: SaasPalette.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Intenta con otro nombre o cédula',
          style: TextStyle(color: SaasPalette.textSecondary, fontSize: 12),
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
        const Icon(
          Icons.people_outline_rounded,
          size: 72,
          color: SaasPalette.textTertiary,
        ),
        const SizedBox(height: 16),
        const Text(
          'No hay reservas para este tour',
          style: TextStyle(
            color: SaasPalette.textPrimary,
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
        const Icon(
          Icons.error_outline_rounded,
          size: 72,
          color: SaasPalette.danger,
        ),
        const SizedBox(height: 16),
        const Text(
          'Error al cargar los datos',
          style: TextStyle(
            color: SaasPalette.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: const TextStyle(
            color: SaasPalette.textSecondary,
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
            backgroundColor: SaasPalette.brand600,
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
