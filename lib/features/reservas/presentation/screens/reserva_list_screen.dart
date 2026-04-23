import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as webLib;
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/reserva.dart';
import '../../domain/repositories/reserva_repository.dart';
import '../bloc/reserva_bloc.dart';
import '../bloc/reserva_event.dart';
import '../bloc/reserva_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../service/domain/repositories/service_repository.dart';
import '../pdf/reserva_pdf_generator.dart';
import '../../../../core/widgets/dialog_loading_widget.dart';

class ReservaListScreen extends StatefulWidget {
  const ReservaListScreen({super.key});

  @override
  State<ReservaListScreen> createState() => _ReservaListScreenState();
}

class _ReservaListScreenState extends State<ReservaListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    context.read<ReservaBloc>().add(const LoadReservas());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    context.read<ReservaBloc>().add(
      LoadReservas(
        page: page,
        startDate: _startDate,
        endDate: _endDate,
        status: _selectedStatus,
      ),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: SaasPalette.brand600,
              onPrimary: Colors.white,
              surface: SaasPalette.bgCanvas,
              onSurface: SaasPalette.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      context.read<ReservaBloc>().add(
        LoadReservas(
          page: 1,
          startDate: _startDate,
          endDate: _endDate,
          status: _selectedStatus,
        ),
      );
    }
  }

  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    context.read<ReservaBloc>().add(
      LoadReservas(page: 1, status: _selectedStatus),
    );
  }

  void _onStatusChanged(String? status) {
    setState(() => _selectedStatus = status);
    context.read<ReservaBloc>().add(
      LoadReservas(
        page: 1,
        startDate: _startDate,
        endDate: _endDate,
        status: _selectedStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentIndex: 11, // Reservas
      child: Scaffold(
        backgroundColor: SaasPalette.bgApp,
        body: BlocConsumer<ReservaBloc, ReservaState>(
          listener: (context, state) {
            if (state is ReservaError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: SaasPalette.danger,
                ),
              );
            }
          },
          builder: (context, state) {
            final authState = context.watch<AuthBloc>().state;
            final canWrite =
                authState is AuthAuthenticated &&
                authState.user.canWrite('reservas');

            List<Reserva>? reservas;
            if (state is ReservaLoaded) {
              reservas = state.reservas;
            } else if (state is ReservaSaving && state.reservas != null) {
              reservas = state.reservas;
            } else if (state is ReservaActionSuccess) {
              reservas = state.reservas;
            }

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ReservaHeader(canWrite: canWrite),
                  ),
                ),

                // ── Filters & Search ───────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _ReservaFilters(
                      searchCtrl: _searchCtrl,
                      onSearchChanged: (v) => setState(() => _searchQuery = v),
                      onPickDates: () => _pickDateRange(context),
                      onClearDates: _clearDates,
                      startDate: _startDate,
                      endDate: _endDate,
                      selectedStatus: _selectedStatus,
                      onStatusChanged: _onStatusChanged,
                    ),
                  ),
                ),

                // ── Content ────────────────────────────────────────────────
                _buildContent(context, state, reservas, canWrite),

                // ── Pagination ─────────────────────────────────────────────
                if (state is ReservaLoaded && state.totalPages > 1)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    sliver: SliverToBoxAdapter(
                      child: _SaasPaginationBar(
                        page: state.page,
                        totalPages: state.totalPages,
                        total: state.total,
                        onPageChanged: _goToPage,
                      ),
                    ),
                  )
                else
                  const SliverPadding(padding: EdgeInsets.only(bottom: 60)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ReservaState state,
    List<Reserva>? reservas,
    bool canWrite,
  ) {
    if (state is ReservaLoading && reservas == null) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (_, __) => const SaasListSkeleton(),
            childCount: 4,
          ),
        ),
      );
    }

    if (reservas == null || reservas.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: const SaasEmptyState(
          icon: Icons.airplane_ticket_outlined,
          title: 'Sin reservas',
          subtitle: 'Aún no se han registrado reservas en el sistema.',
        ),
      );
    }

    final filtered = reservas.where((r) {
      // Status filter (local, complements server-side filter)
      if (_selectedStatus != null) {
        final estadoNorm = r.estado.toLowerCase().trim();
        final filter = _selectedStatus!.toLowerCase();
        if (filter == 'al dia' &&
            !estadoNorm.contains('al dia') &&
            !estadoNorm.contains('al día')) {
          return false;
        } else if (filter != 'al dia' && !estadoNorm.contains(filter)) {
          return false;
        }
      }

      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        
        // 1. Tour Name
        final tourName = (r.tour?.name ?? '').toLowerCase();
        // 2. Reservation ID
        final idReserva = (r.idReserva ?? '').toLowerCase();
        // 3. Responsible Info
        final responsable = r.responsable;
        final respNombre = (responsable?.nombre ?? '').toLowerCase();
        final respDoc = (responsable?.documento?.toString() ?? '').toLowerCase();
        final respTel = (responsable?.telefono ?? '').toLowerCase();
        // 4. Agent Info
        final agenteNombre = (r.agente?.nombre ?? '').toLowerCase();
        // 5. Correo
        final correo = r.correo.toLowerCase();

        final matches = tourName.contains(query) ||
            idReserva.contains(query) ||
            respNombre.contains(query) ||
            respDoc.contains(query) ||
            respTel.contains(query) ||
            agenteNombre.contains(query) ||
            correo.contains(query);

        if (!matches) return false;
      }

      return true;
    }).toList();

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: const SaasEmptyState(
          icon: Icons.search_off_rounded,
          title: 'Sin coincidencias',
          subtitle: 'No se encontraron reservas con los filtros aplicados.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final reserva = filtered[index];
          return _ReservaCard(reserva: reserva, canWrite: canWrite);
        }, childCount: filtered.length),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _ReservaHeader extends StatelessWidget {
  final bool canWrite;
  const _ReservaHeader({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Reservas']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Gestión de Reservas',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Control y administración de reservas y flujos de pago.',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (canWrite)
              SaasButton(
                label: 'Nueva Reserva',
                icon: Icons.add_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.reservaCreate),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FILTERS
// ─────────────────────────────────────────────────────────────────────────────
class _ReservaFilters extends StatelessWidget {
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPickDates;
  final VoidCallback onClearDates;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedStatus;
  final ValueChanged<String?> onStatusChanged;

  const _ReservaFilters({
    required this.searchCtrl,
    required this.onSearchChanged,
    required this.onPickDates,
    required this.onClearDates,
    required this.startDate,
    required this.endDate,
    required this.selectedStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasDates = startDate != null && endDate != null;
    final dateStr = hasDates
        ? '${DateFormat('dd/MM/yy').format(startDate!)} - ${DateFormat('dd/MM/yy').format(endDate!)}'
        : 'Rango de Fechas';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: SaasSearchField(
                controller: searchCtrl,
                hintText: 'Buscar por ID, nombre o correo...',
                onChanged: onSearchChanged,
                onClear: () {
                  searchCtrl.clear();
                  onSearchChanged('');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: hasDates ? SaasPalette.brand50 : SaasPalette.bgCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasDates ? SaasPalette.brand600 : SaasPalette.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onPickDates,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(12),
                          right: Radius.circular(0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 18,
                                color: hasDates
                                    ? SaasPalette.brand600
                                    : SaasPalette.textTertiary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  dateStr,
                                  style: TextStyle(
                                    color: hasDates
                                        ? SaasPalette.brand600
                                        : SaasPalette.textSecondary,
                                    fontSize: 13,
                                    fontWeight: hasDates
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (hasDates)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Tooltip(
                          message: 'Limpiar fechas',
                          child: GestureDetector(
                            onTap: onClearDates,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: SaasPalette.bgSubtle,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: SaasPalette.textTertiary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _StatusChip(
                label: 'Todas',
                icon: Icons.list_rounded,
                isSelected: selectedStatus == null,
                onSelected: () => onStatusChanged(null),
              ),
              _StatusChip(
                label: 'Al Día',
                icon: Icons.check_circle_rounded,
                isSelected: selectedStatus == 'al dia',
                color: SaasPalette.success,
                onSelected: () => onStatusChanged('al dia'),
              ),
              _StatusChip(
                label: 'Pendiente',
                icon: Icons.schedule_rounded,
                isSelected: selectedStatus == 'pendiente',
                color: SaasPalette.warning,
                onSelected: () => onStatusChanged('pendiente'),
              ),
              _StatusChip(
                label: 'Cancelado',
                icon: Icons.cancel_rounded,
                isSelected: selectedStatus == 'cancelado',
                color: SaasPalette.danger,
                onSelected: () => onStatusChanged('cancelado'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? SaasPalette.brand600;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: 0.1)
                : SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.5)
                  : SaasPalette.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : SaasPalette.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : SaasPalette.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  RESERVA CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ReservaCard extends StatefulWidget {
  final Reserva reserva;
  final bool canWrite;
  const _ReservaCard({required this.reserva, required this.canWrite});

  @override
  State<_ReservaCard> createState() => _ReservaCardState();
}

class _ReservaCardState extends State<_ReservaCard> {
  bool _hovered = false;
  bool _generatingPdf = false;

  Future<void> _generateAndShowPdf() async {
    setState(() => _generatingPdf = true);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DialogLoadingNetwork(titel: 'Generando PDF de Reserva'),
    );

    try {
      final fullReserva = widget.reserva.id != null
          ? await sl<ReservaRepository>().getReservaById(widget.reserva.id!)
          : widget.reserva;
      final allServices = await sl<ServiceRepository>().getServices();
      final bytes = await ReservaPdfGenerator.generate(
        fullReserva,
        servicios: allServices,
      );
      if (!mounted) return;
      Navigator.pop(context); // Close dialog
      await _showPdfPreviewDialog(bytes);
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close dialog
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
                decoration: BoxDecoration(
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
    final r = widget.reserva;
    final nombreResponsable =
        r.responsable?.nombre ??
        (r.integrantes.isNotEmpty
            ? r.integrantes
                  .firstWhere(
                    (i) => i.esResponsable,
                    orElse: () => r.integrantes.first,
                  )
                  .nombre
            : 'Sin responsable');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? SaasPalette.brand600 : SaasPalette.border,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.06 : 0.02),
                blurRadius: _hovered ? 12 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              AppRouter.reservaEdit,
              arguments: r,
            ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: SaasPalette.brand50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      r.tipoReserva == 'vuelos'
                          ? Icons.flight_takeoff_rounded
                          : Icons.terrain_rounded,
                      color: SaasPalette.brand600,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                nombreResponsable,
                                style: const TextStyle(
                                  color: SaasPalette.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _StatusBadge(status: r.estado),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID #${r.idReserva}',
                          style: const TextStyle(
        color: SaasPalette.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Agent
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: SaasPalette.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Agente: ${r.agente?.nombre ?? "N/A"}',
                              style: const TextStyle(
                                color: SaasPalette.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Update Date
                            const Icon(
                              Icons.history_rounded,
                              size: 14,
                              color: SaasPalette.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Actualizado: ${DateFormat('dd/MM/yyyy HH:mm').format(r.fechaActualizacion)}',
                              style: const TextStyle(
                                color: SaasPalette.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.tour_outlined,
                          text: r.tipoReserva == 'vuelos'
                              ? '${r.vuelos.length} Vuelo(s)'
                              : (r.tour?.name ?? 'Tour ID: ${r.idTour}'),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoRow(
                                icon: Icons.payments_outlined,
                                text:
                                    'Total: ${NumberFormat.simpleCurrency(decimalDigits: 0).format(r.valorTotal)}',
                                textColor: SaasPalette.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Expanded(
                              child: _InfoRow(
                                icon: Icons.pending_actions_rounded,
                                text:
                                    'Saldo: ${NumberFormat.simpleCurrency(decimalDigits: 0).format(r.saldoPendiente)}',
                                textColor: SaasPalette.warning,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        //telefono
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          text: r.responsable?.telefono ?? 'No disponible',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 14,
                              color: SaasPalette.textTertiary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat(
                                "dd MMM yyyy",
                                'es',
                              ).format(r.fechaCreacion),
                              style: const TextStyle(
                                color: SaasPalette.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.people_outline_rounded,
                              size: 14,
                              color: SaasPalette.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${r.integrantes.length} pax',
                              style: const TextStyle(
                                color: SaasPalette.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // PDF button
                            Tooltip(
                              message: 'Generar PDF de la reserva',
                              child: _generatingPdf
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: SaasPalette.brand600,
                                      ),
                                    )
                                  : InkWell(
                                      onTap: _generateAndShowPdf,
                                      borderRadius: BorderRadius.circular(6),
                                      child: const Padding(
                                        padding: EdgeInsets.all(3),
                                        child: Icon(
                                          Icons.picture_as_pdf_rounded,
                                          size: 18,
                                          color: SaasPalette.brand600,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'al dia':
        color = SaasPalette.success;
        label = 'AL DÍA';
        break;
      case 'pendiente':
        color = SaasPalette.warning;
        break;
      case 'cancelado':
        color = SaasPalette.danger;
        break;
      default:
        color = SaasPalette.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? textColor;
  final FontWeight? fontWeight;

  const _InfoRow({
    required this.icon,
    required this.text,
    this.textColor,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: SaasPalette.textTertiary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              color: textColor ?? SaasPalette.textSecondary,
              fontSize: 13,
              fontWeight: fontWeight ?? FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PAGINATION
// ─────────────────────────────────────────────────────────────────────────────
class _SaasPaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int total;
  final void Function(int) onPageChanged;

  const _SaasPaginationBar({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SaasPalette.bgCanvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SaasPalette.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _PageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: page > 1,
            onTap: () => onPageChanged(page - 1),
          ),
          Column(
            children: [
              Text(
                'Página $page de $totalPages',
                style: const TextStyle(
                  color: SaasPalette.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$total resultados encontrados',
                style: const TextStyle(
                  color: SaasPalette.textTertiary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          _PageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: page < totalPages,
            onTap: () => onPageChanged(page + 1),
          ),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled
              ? SaasPalette.bgApp
              : SaasPalette.bgApp.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? SaasPalette.border
                : SaasPalette.border.withValues(alpha: 0.5),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? SaasPalette.brand600 : SaasPalette.textTertiary,
          size: 24,
        ),
      ),
    );
  }
}
