import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:agente_viajes/features/tour/presentation/bloc/tour_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as webLib;
import '../../../../core/theme/saas_palette.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../../../core/widgets/saas_snackbar.dart';
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
  final _scrollController = ScrollController();
  String _searchQuery = '';
  Timer? _debounce;
  int _currentPage = 1;
  bool _isProcessingDelete = false;
  bool _isProcessingCancel = false;

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !(_debounce?.isActive ?? false)) {
      final state = context.read<ReservaBloc>().state;
      if (state is ReservaLoaded && !state.hasReachedMax) {
        _loadNextPage();
      }
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _loadFirstPage() {
    _currentPage = 1;
    context.read<ReservaBloc>().add(
          LoadReservas(
            page: _currentPage,
            startDate: _startDate,
            endDate: _endDate,
            status: _selectedStatus,
            search: _searchQuery.isEmpty ? null : _searchQuery,
          ),
        );
  }

  void _loadNextPage() {
    _currentPage++;
    context.read<ReservaBloc>().add(
          LoadReservas(
            page: _currentPage,
            startDate: _startDate,
            endDate: _endDate,
            status: _selectedStatus,
            search: _searchQuery.isEmpty ? null : _searchQuery,
          ),
        );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _loadFirstPage();
    });
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
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
          search: _searchQuery.isEmpty ? null : _searchQuery,
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
      LoadReservas(
        page: 1,
        status: _selectedStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      ),
    );
  }

  void _onStatusChanged(String? status) {
    setState(() => _selectedStatus = status);
    context.read<ReservaBloc>().add(
      LoadReservas(
        page: 1,
        startDate: _startDate,
        endDate: _endDate,
        status: status,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocConsumer<ReservaBloc, ReservaState>(
        listener: (context, state) {
          if (state is ReservaSaving &&
              (_isProcessingDelete || _isProcessingCancel)) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => DialogLoadingNetwork(
                titel: _isProcessingCancel
                    ? 'Cancelando reserva...'
                    : 'Eliminando reserva...',
              ),
            );
          } else if (state is ReservaActionSuccess && _isProcessingDelete) {
            _isProcessingDelete = false;
            Navigator.of(context, rootNavigator: true).pop();
            SaasSnackBar.showSuccess(context, 'Reserva eliminada correctamente');
          } else if (state is ReservaActionSuccess && _isProcessingCancel) {
            _isProcessingCancel = false;
            Navigator.of(context, rootNavigator: true).pop();
            SaasSnackBar.showSuccess(context, 'Reserva cancelada correctamente');
          } else if (state is ReservaError) {
            if (_isProcessingDelete || _isProcessingCancel) {
              _isProcessingDelete = false;
              _isProcessingCancel = false;
              Navigator.of(context, rootNavigator: true).pop();
            }
            SaasSnackBar.showError(context, state.message);
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
            controller: _scrollController,
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
                    onSearchChanged: _onSearchChanged,
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
              ..._buildContent(context, state, reservas, canWrite),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildContent(
    BuildContext context,
    ReservaState state,
    List<Reserva>? reservas,
    bool canWrite,
  ) {
    final isLoadingFirst = state is ReservaLoading && (reservas == null || reservas.isEmpty);

    if (isLoadingFirst) {
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, _) => const SaasListSkeleton(),
              childCount: 4,
            ),
          ),
        )
      ];
    }

    if (reservas == null || reservas.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: SaasEmptyState(
            icon: (_searchQuery.isNotEmpty || _selectedStatus != null || _startDate != null)
                ? Icons.search_off_rounded
                : Icons.airplane_ticket_outlined,
            title: (_searchQuery.isNotEmpty || _selectedStatus != null || _startDate != null)
                ? 'Sin coincidencias'
                : 'Sin reservas',
            subtitle: (_searchQuery.isNotEmpty || _selectedStatus != null || _startDate != null)
                ? 'No se encontraron reservas con los filtros aplicados.'
                : 'Aún no se han registrado reservas en el sistema.',
          ),
        )
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final reserva = reservas[index];
              return _ReservaCard(
                reserva: reserva,
                canWrite: canWrite,
                onDelete: () => _confirmDelete(reserva),
                onCancel: () => _confirmCancel(reserva),
              );
            },
            childCount: reservas.length,
          ),
        ),
      ),
      if (state is ReservaLoaded && !state.hasReachedMax)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: SaasPalette.brand600,
              ),
            ),
          ),
        ),
    ];
  }

  void _confirmDelete(Reserva reserva) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: '¿Eliminar Reserva?',
        body: 'Esta acción borrará la reserva #${reserva.idReserva ?? reserva.id} permanentemente del sistema.',
        onConfirm: () {
          Navigator.pop(ctx);
          if (reserva.id != null) {
            _isProcessingDelete = true;
            context.read<ReservaBloc>().add(DeleteReserva(int.parse(reserva.id!)));
          }
        },
      ),
    );
  }

  void _confirmCancel(Reserva reserva) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: 'Cancelar Reserva',
        body:
            'La reserva #${reserva.idReserva ?? reserva.id} será marcada como cancelada '
            'y los asientos asignados quedarán liberados. '
            'Esta acción no se puede deshacer.',
        confirmLabel: 'Cancelar reserva',
        onConfirm: () {
          Navigator.pop(ctx);
          if (reserva.id != null) {
            _isProcessingCancel = true;
            context.read<ReservaBloc>().add(CancelReserva(reserva.id!));
          }
        },
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
                onPressed: () {
                  context.read<TourBloc>().add(LoadTours());
                  Navigator.pushNamed(context, AppRouter.reservaCreate);
                },
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 48,
                decoration: BoxDecoration(
                  color: hasDates ? SaasPalette.brand50 : SaasPalette.bgCanvas,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasDates ? SaasPalette.brand600 : SaasPalette.border,
                    width: hasDates ? 1.5 : 1,
                  ),
                  boxShadow: hasDates
                      ? [
                          BoxShadow(
                            color: SaasPalette.brand600.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: onPickDates,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: hasDates
                                    ? SaasPalette.brand600
                                    : SaasPalette.textTertiary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (hasDates)
                                      Text(
                                        'Rango seleccionado',
                                        style: TextStyle(
                                          color: SaasPalette.brand600
                                              .withValues(alpha: 0.7),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    Text(
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (hasDates)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: onClearDates,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: SaasPalette.brand600.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: SaasPalette.brand600,
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
                label: 'Cancelada',
                icon: Icons.cancel_rounded,
                isSelected: selectedStatus == 'cancelada',
                color: SaasPalette.danger,
                onSelected: () => onStatusChanged('cancelada'),
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
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  const _ReservaCard({
    required this.reserva,
    required this.canWrite,
    required this.onDelete,
    required this.onCancel,
  });

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
      builder: (_) =>
          const DialogLoadingNetwork(titel: 'Generando PDF de Reserva'),
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
      // Cerrar el diálogo de carga usando el rootNavigator para asegurar que cerramos el diálogo
      Navigator.of(context, rootNavigator: true).pop();

      await _showPdfPreviewDialog(bytes);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
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

    final isCancelled = r.estado == 'cancelada' || r.estado == 'cancelado';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isCancelled
                ? SaasPalette.danger.withValues(alpha: 0.04)
                : SaasPalette.bgCanvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCancelled
                  ? SaasPalette.danger.withValues(alpha: 0.25)
                  : _hovered
                      ? SaasPalette.brand600
                      : SaasPalette.border,
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
            onTap: () {
              Navigator.pushNamed(context, AppRouter.reservaEdit, arguments: r);
            },
            borderRadius: BorderRadius.circular(16),
            child: Opacity(
              opacity: isCancelled ? 0.6 : 1.0,
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
                            if (widget.canWrite) ...[
                              const SizedBox(width: 16),
                              _ReservaActionMenu(
                                reserva: r,
                                onEdit: () => Navigator.pushNamed(
                                  context,
                                  AppRouter.reservaEdit,
                                  arguments: r,
                                ),
                                onDelete: widget.onDelete,
                                onCancel: widget.onCancel,
                              ),
                            ],
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
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Agent
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                              ],
                            ),
                            // Update Date
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
            ), // Opacity
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
      case 'cancelada':
        color = SaasPalette.danger;
        label = 'CANCELADA';
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

class _ReservaActionMenu extends StatelessWidget {
  final Reserva reserva;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCancel;

  const _ReservaActionMenu({
    required this.reserva,
    required this.onEdit,
    required this.onDelete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isCancelled = reserva.estado == 'cancelada';
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert_rounded,
        color: SaasPalette.textTertiary,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: SaasPalette.bgCanvas,
      elevation: 4,
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'cancel') onCancel();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: const [
              Icon(
                Icons.edit_outlined,
                size: 18,
                color: SaasPalette.textPrimary,
              ),
              SizedBox(width: 12),
              Text('Editar reserva', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        if (!isCancelled) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: const [
                Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: SaasPalette.warning,
                ),
                SizedBox(width: 12),
                Text(
                  'Cancelar reserva',
                  style: TextStyle(color: SaasPalette.warning, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: const [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: SaasPalette.danger,
              ),
              SizedBox(width: 12),
              Text(
                'Eliminar',
                style: TextStyle(color: SaasPalette.danger, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
