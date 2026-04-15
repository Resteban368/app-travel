import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/reserva.dart';
import '../bloc/reserva_bloc.dart';
import '../bloc/reserva_event.dart';
import '../bloc/reserva_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ReservaListScreen extends StatefulWidget {
  const ReservaListScreen({super.key});

  @override
  State<ReservaListScreen> createState() => _ReservaListScreenState();
}

class _ReservaListScreenState extends State<ReservaListScreen>
    with TickerProviderStateMixin {
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _contentOpacity;

  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeOutCubic),
      ),
    );
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    context.read<ReservaBloc>().add(const LoadReservas());
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    context.read<ReservaBloc>().add(LoadReservas(
      page: page,
      startDate: _startDate,
      endDate: _endDate,
      status: _selectedStatus,
    ));
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
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: D.royalBlue,
              onPrimary: Colors.white,
              surface: D.surface,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: D.bg,
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
      context.read<ReservaBloc>().add(LoadReservas(
        page: 1,
        startDate: _startDate,
        endDate: _endDate,
        status: _selectedStatus,
      ));
    }
  }

  void _clearDates() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    context.read<ReservaBloc>().add(LoadReservas(page: 1, status: _selectedStatus));
  }

  void _onStatusChanged(String? status) {
    setState(() => _selectedStatus = status);
    context.read<ReservaBloc>().add(LoadReservas(
      page: 1,
      startDate: _startDate,
      endDate: _endDate,
      status: _selectedStatus,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AdminShell(
      currentIndex: 11, // Se actualizará AdminShell para incluir Reservas
      child: Scaffold(
        backgroundColor: D.bg,
        body: Stack(
          children: [
            // Background Orbs
            AnimatedBuilder(
              animation: _bgCtrl,
              builder: (context, _) => Stack(
                children: [
                  Positioned(
                    top: -100 + math.sin(_bgCtrl.value * math.pi * 2) * 50,
                    right: -50 + math.cos(_bgCtrl.value * math.pi * 2) * 40,
                    child: _Orb(color: D.royalBlue.withOpacity(0.1), size: 450),
                  ),
                  Positioned(
                    bottom: -50 + math.cos(_bgCtrl.value * math.pi * 2) * 30,
                    left: -100 + math.sin(_bgCtrl.value * math.pi * 2) * 50,
                    child: _Orb(color: D.indigo.withOpacity(0.08), size: 350),
                  ),
                ],
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

            BlocConsumer<ReservaBloc, ReservaState>(
              listener: (context, state) {
                if (state is ReservaError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: D.rose,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final authState = context.watch<AuthBloc>().state;
                final canWrite = authState is AuthAuthenticated && authState.user.canWrite('reservas');
                List<Reserva>? reservas;
                if (state is ReservaLoaded) {
                  reservas = state.reservas;
                } else if (state is ReservaSaving && state.reservas != null) {
                  reservas = state.reservas;
                } else if (state is ReservaActionSuccess) {
                  reservas = state.reservas;
                }

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      sliver: SliverToBoxAdapter(
                        child: FadeTransition(
                          opacity: _headerOpacity,
                          child: SlideTransition(
                            position: _headerSlide,
                            child: _buildHeader(context, canWrite),
                          ),
                        ),
                      ),
                    ),
                    _buildFilters(),
                    SliverFadeTransition(
                      opacity: _contentOpacity,
                      sliver: _buildContent(context, state, reservas, canWrite),
                    ),
                    if (state is ReservaLoaded && state.totalPages > 1)
                      SliverToBoxAdapter(
                        child: _PaginationBar(
                          page: state.page,
                          totalPages: state.totalPages,
                          total: state.total,
                          onPageChanged: _goToPage,
                        ),
                      ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool canWrite) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [D.royalBlue, D.cyan]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.airplane_ticket_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'FLUJO DE RESERVAS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Gestión de Reservas',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Control y administración de compras.',
              style: TextStyle(color: D.slate400, fontSize: 13),
            ),
          ],
        ),
        if (canWrite)
          _AddBtn(
            onPressed: () =>
                Navigator.pushNamed(context, AppRouter.reservaCreate),
          ),
      ],
    );
  }

  Widget _buildFilters() {
    final hasDates = _startDate != null && _endDate != null;
    final dateStr = hasDates
        ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
        : 'Filtrar por Fechas';

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: D.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: D.border.withOpacity(0.5)),
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Buscar (correo, responsable, id)...',
                        hintStyle: TextStyle(color: D.slate600, fontSize: 14),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: D.slate600,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => _pickDateRange(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: hasDates
                          ? D.royalBlue.withOpacity(0.2)
                          : D.surface.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasDates
                            ? D.royalBlue
                            : D.border.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.date_range_rounded,
                          color: hasDates ? D.skyBlue : D.slate400,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: hasDates ? Colors.white : D.slate400,
                            fontWeight: hasDates
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (hasDates) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _clearDates,
                            child: const Icon(
                              Icons.close_rounded,
                              color: D.slate400,
                              size: 18,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _StatusChip(
                    label: 'Todas',
                    isSelected: _selectedStatus == null,
                    onSelected: () => _onStatusChanged(null),
                  ),
                  _StatusChip(
                    label: 'Al Día',
                    isSelected: _selectedStatus == 'al dia',
                    color: D.emerald,
                    onSelected: () => _onStatusChanged('al dia'),
                  ),
                  _StatusChip(
                    label: 'Pendiente',
                    isSelected: _selectedStatus == 'pendiente',
                    color: Colors.amber,
                    onSelected: () => _onStatusChanged('pendiente'),
                  ),
                  _StatusChip(
                    label: 'Cancelado',
                    isSelected: _selectedStatus == 'cancelado',
                    color: D.rose,
                    onSelected: () => _onStatusChanged('cancelado'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ReservaState state, List<Reserva>? reservas, bool canWrite) {
    if (state is ReservaLoading && reservas == null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _SkelCard(),
          childCount: 4,
        ),
      );
    }

    if (reservas == null || reservas.isEmpty) {
      return const SliverFillRemaining(child: _EmptyState());
    }

    final filtered = reservas.where((r) {
      // Filter by Search Query
      final queryLower = _searchQuery.toLowerCase();
      final correoMatches = r.correo.toLowerCase().contains(queryLower);
      final idMatches = (r.id ?? '').toLowerCase().contains(queryLower);

      // Buscar nombre del responsable de r.responsable o de integrantes
      final responsableNombre = r.responsable?.nombre ??
          (r.integrantes.isNotEmpty
              ? r.integrantes
                  .firstWhere((i) => i.esResponsable,
                      orElse: () => r.integrantes.first)
                  .nombre
              : '');
      final nameMatches = responsableNombre.toLowerCase().contains(queryLower);

      final matchesSearch = correoMatches || idMatches || nameMatches;

      // Filter by Status
      final matchesStatus =
          _selectedStatus == null ||
          r.estado.toLowerCase() == _selectedStatus!.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    if (filtered.isEmpty) {
      return const SliverFillRemaining(child: _EmptyState(isSearch: true));
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final reserva = filtered[index];
          return _ReservaCard(reserva: reserva, state: state, canWrite: canWrite);
        }, childCount: filtered.length),
      ),
    );
  }
}

class _ReservaCard extends StatefulWidget {
  final Reserva reserva;
  final ReservaState state;
  final bool canWrite;
  const _ReservaCard({required this.reserva, required this.state, required this.canWrite});

  @override
  State<_ReservaCard> createState() => _ReservaCardState();
}

class _ReservaCardState extends State<_ReservaCard> {
  bool _hovered = false;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'al dia':
        return D.emerald;
      case 'pendiente':
        return Colors.amber;
      case 'cancelado':
        return D.rose;
      default:
        return D.slate400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.reserva;

    // Priorizar responsable como objeto Cliente (viene del backend),
    // con fallback al primer integrante marcado como responsable.
    final nombreResponsable = r.responsable?.nombre ??
        (r.integrantes.isNotEmpty
            ? r.integrantes
                .firstWhere((i) => i.esResponsable,
                    orElse: () => r.integrantes.first)
                .nombre
            : null);
    final telefonoResponsable = r.responsable?.telefono ??
        (r.integrantes.isNotEmpty
            ? r.integrantes
                .firstWhere((i) => i.esResponsable,
                    orElse: () => r.integrantes.first)
                .telefono
            : null);

    final statusColor = _getStatusColor(r.estado);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: D.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _hovered ? D.royalBlue.withOpacity(0.5) : D.border,
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRouter.reservaEdit, arguments: r),
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.airplane_ticket_rounded,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              nombreResponsable ?? 'Sin responsable',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _Tag(
                            label: r.estado.toUpperCase(),
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Tour Info with Price
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.tour?.name ?? 'Tour ID: ${r.idTour}',
                              style: TextStyle(
                                color: D.slate200,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (r.tour != null)
                        Text(
                          NumberFormat.currency(
                            symbol: '\$',
                            decimalDigits: 0,
                          ).format(r.tour!.price),
                          style: const TextStyle(
                            color: D.emerald,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      if (r.tour != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.date_range_rounded,
                              color: D.slate400,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat('dd MMM').format(r.tour!.startDate)} - ${DateFormat('dd MMM yyyy').format(r.tour!.endDate)}',
                              style: TextStyle(color: D.slate400, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.email_outlined, color: D.slate600, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            r.correo,
                            style: TextStyle(color: D.slate600, fontSize: 12),
                          ),
                        ],
                      ),
                      if (telefonoResponsable != null && telefonoResponsable.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, color: D.slate600, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              telefonoResponsable,
                              style: TextStyle(color: D.slate600, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            color: D.skyBlue,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Creado el ${DateFormat("dd 'de' MMMM yyyy", 'es_CO').format(r.fechaCreacion)}',
                              style: TextStyle(
                                color: D.slate400,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          //cino de personas
                          Icon(
                            Icons.person_outline,
                            color: D.slate600,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${r.integrantes.length} integrante(s)',
                            style: TextStyle(
                              color: D.royalBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: D.skyBlue, size: 20),
          onPressed: () => Navigator.pushNamed(
            context,
            AppRouter.reservaEdit,
            arguments: widget.reserva,
          ),
        ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  final int page;
  final int totalPages;
  final int total;
  final void Function(int) onPageChanged;

  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.total,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: D.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: D.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PageBtn(
              icon: Icons.chevron_left_rounded,
              enabled: page > 1,
              onTap: () => onPageChanged(page - 1),
            ),
            const SizedBox(width: 20),
            Column(
              children: [
                Text(
                  'Página $page de $totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total resultados',
                  style: const TextStyle(color: D.slate400, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: 20),
            _PageBtn(
              icon: Icons.chevron_right_rounded,
              enabled: page < totalPages,
              onTap: () => onPageChanged(page + 1),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PageBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? D.royalBlue.withValues(alpha: 0.15) : D.surfaceHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? D.royalBlue.withValues(alpha: 0.4) : D.border,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? D.skyBlue : D.slate600,
          size: 22,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.5)),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );
}

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

class _DotGridPainter extends CustomPainter {
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

class _AddBtn extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddBtn({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [D.royalBlue, D.indigo]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: D.royalBlue.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
      ),
    );
  }
}

class _SkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 120,
    margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
    decoration: BoxDecoration(
      color: D.surface.withOpacity(0.5),
      borderRadius: BorderRadius.circular(22),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({this.isSearch = false});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSearch ? Icons.search_off_rounded : Icons.airplane_ticket_outlined,
          size: 64,
          color: D.slate800,
        ),
        const SizedBox(height: 16),
        Text(
          isSearch
              ? 'No se encontraron reservas con esos filtros'
              : 'Sin reservas registradas',
          style: TextStyle(
            color: D.slate600,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color? color;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? D.royalBlue;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: D.surfaceHigh.withOpacity(0.8),
        selectedColor: activeColor.withOpacity(0.2),
        checkmarkColor: activeColor,
        labelStyle: TextStyle(
          color: isSelected ? activeColor : D.slate200.withOpacity(0.9),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? activeColor.withOpacity(0.7)
                : D.slate400.withOpacity(0.3),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ),
    );
  }
}
