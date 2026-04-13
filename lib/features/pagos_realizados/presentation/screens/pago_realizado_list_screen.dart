import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/pago_realizado.dart';
import '../bloc/pago_realizado_bloc.dart';

class PagoRealizadoListScreen extends StatelessWidget {
  const PagoRealizadoListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 9, child: _PagoRealizadoListBody());
  }
}

class _PagoRealizadoListBody extends StatefulWidget {
  const _PagoRealizadoListBody();

  @override
  State<_PagoRealizadoListBody> createState() => _PagoRealizadoListBodyState();
}

class _PagoRealizadoListBodyState extends State<_PagoRealizadoListBody> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  DateTimeRange? _selectedDateRange;
  late final AnimationController _bgCtrl;
  late final AnimationController _entryCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _contentOpacity;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

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

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bgCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _onFilterDates() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: D.royalBlue,
              onPrimary: Colors.white,
              surface: D.surfaceHigh,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: D.bg,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (!mounted) return;
      setState(() => _selectedDateRange = picked);
      context.read<PagoRealizadoBloc>().add(
        LoadPagos(startDate: picked.start, endDate: picked.end),
      );
    }
  }

  void _clearFilter() {
    setState(() => _selectedDateRange = null);
    context.read<PagoRealizadoBloc>().add(const LoadPagos());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.bg,
      body: Stack(
        children: [
          // Background Animations
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned(
                    top: -150 + math.sin(_bgCtrl.value * math.pi * 2) * 60,
                    right: -100 + math.cos(_bgCtrl.value * math.pi * 2) * 40,
                    child: _Orb(color: D.royalBlue.withOpacity(0.1), size: 400),
                  ),
                  Positioned(
                    bottom: -100 + math.cos(_bgCtrl.value * math.pi * 2) * 50,
                    left: -120 + math.sin(_bgCtrl.value * math.pi * 2) * 80,
                    child: _Orb(color: D.indigo.withOpacity(0.08), size: 350),
                  ),
                ],
              );
            },
          ),
          Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

          // Content
          BlocBuilder<PagoRealizadoBloc, PagoRealizadoState>(
            builder: (context, state) {
              List<PagoRealizado>? pagos;
              if (state is PagosRealizadosLoaded) pagos = state.pagos;
              else if (state is PagoRealizadoSaving && state.pagos != null) pagos = state.pagos;

              if (pagos != null && _searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                pagos = pagos.where((p) => 
                  p.chatId.toLowerCase().contains(query) || 
                  p.referencia.toLowerCase().contains(query) ||
                  p.proveedorComercio.toLowerCase().contains(query)
                ).toList();
              }

              return CustomScrollView(
                slivers: [
                  // Header
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    sliver: SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _headerOpacity,
                        child: SlideTransition(
                          position: _headerSlide,
                          child: _buildHeader(context),
                        ),
                      ),
                    ),
                  ),
                  _buildFiltersRow(context),
                  SliverFadeTransition(
                    opacity: _contentOpacity,
                    sliver: SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      sliver: _buildSliverContent(state, pagos),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Progress overlay for saving
          BlocBuilder<PagoRealizadoBloc, PagoRealizadoState>(
            builder: (context, state) {
              if (state is PagoRealizadoSaving) {
                return Positioned(
                  top: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(D.skyBlue),
                    minHeight: 3,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                    Icons.payments_rounded,
                    color: Colors.white,
                    size: 10,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'REPORTES DE PAGO',
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
              'Pagos Realizados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Seguimiento de comprobantes y transferencias.',
              style: TextStyle(color: D.slate400, fontSize: 13),
            ),
          ],
        ),
        _AddBtn(
          onPressed: () =>
              Navigator.pushNamed(context, AppRouter.pagoRealizadoCreate),
        ),
      ],
    );
  }

  Widget _buildFiltersRow(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: D.surface.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: D.border.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Número de chat, referencia o comercio...',
                  hintStyle: TextStyle(color: D.slate600),
                  prefixIcon: Icon(Icons.search_rounded, color: D.slate400, size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _onFilterDates,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: D.surfaceHigh.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _selectedDateRange != null ? D.skyBlue.withOpacity(0.3) : D.border),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: _selectedDateRange != null ? D.skyBlue : D.slate400, size: 18),
                          const SizedBox(width: 12),
                          Text(
                            _selectedDateRange == null 
                              ? 'Filtrar por rango de fechas' 
                              : '${dateFormat.format(_selectedDateRange!.start)} - ${dateFormat.format(_selectedDateRange!.end)}',
                            style: TextStyle(
                              color: _selectedDateRange != null ? Colors.white : D.slate400,
                              fontSize: 13,
                              fontWeight: _selectedDateRange != null ? FontWeight.bold : FontWeight.normal
                            ),
                          ),
                          if (_selectedDateRange != null) ...[
                            const Spacer(),
                            GestureDetector(
                              onTap: _clearFilter,
                              child: Icon(Icons.close_rounded, color: D.rose, size: 18),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSliverContent(PagoRealizadoState state, List<PagoRealizado>? pagos) {
    if (state is PagoRealizadoLoading && pagos == null) {
      return SliverList(
        delegate: SliverChildBuilderDelegate((_, i) => _SkelCard(), childCount: 3),
      );
    }

    if (pagos == null || pagos.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _EmptyDisplay(isSearch: _searchQuery.isNotEmpty || _selectedDateRange != null),
      );
    }

    // Group by chat_id
    final Map<String, List<PagoRealizado>> grouped = {};
    for (var p in pagos) {
      grouped.putIfAbsent(p.chatId, () => []).add(p);
    }
    final chatIds = grouped.keys.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final chatId = chatIds[index];
          final chatPagos = grouped[chatId]!;
          return _ChatGroupCard(chatId: chatId, pagos: chatPagos, index: index);
        },
        childCount: chatIds.length,
      ),
    );
  }
}

class _ChatGroupCard extends StatefulWidget {
  final String chatId;
  final List<PagoRealizado> pagos;
  final int index;
  const _ChatGroupCard({required this.chatId, required this.pagos, required this.index});

  @override
  State<_ChatGroupCard> createState() => _ChatGroupCardState();
}

class _ChatGroupCardState extends State<_ChatGroupCard> {
  @override
  Widget build(BuildContext context) {
    final total = widget.pagos.fold<double>(0, (sum, p) => sum + p.monto);
    final hasUnconfirmed = widget.pagos.any((p) => !p.isValidated);
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return AnimatedPadding(
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.only(bottom: 20),
      child: Container(
        decoration: BoxDecoration(
          color: D.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: hasUnconfirmed ? D.gold.withOpacity(0.3) : D.border),
          boxShadow: [
            if (hasUnconfirmed) BoxShadow(color: D.gold.withOpacity(0.05), blurRadius: 20, spreadRadius: -5)
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            onExpansionChanged: (v) {},
            title: _buildHeader(total, currencyFormat, hasUnconfirmed),
            children: [
              const Divider(color: D.border, height: 1),
              ...widget.pagos.map((p) => _PagoItem(pago: p)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(double total, NumberFormat fmt, bool hasUnconfirmed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: D.royalBlue.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.person_rounded, color: D.skyBlue, size: 22),
              ),
              if (hasUnconfirmed)
                Positioned(
                  right: 0, top: 0,
                  child: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(color: D.gold, shape: BoxShape.circle, border: Border.all(color: D.surface, width: 2)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Chat: ${widget.chatId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text('${widget.pagos.length} pagos registrados', style: TextStyle(color: D.slate400, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('TOTAL', style: TextStyle(color: D.slate600, fontSize: 10, fontWeight: FontWeight.w900)),
              Text(fmt.format(total), style: TextStyle(color: D.emerald, fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PagoItem extends StatelessWidget {
  final PagoRealizado pago;
  const _PagoItem({required this.pago});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
    return InkWell(
      onTap: () => Navigator.pushNamed(context, AppRouter.pagoRealizadoEdit, arguments: pago),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: D.border, width: 0.5))),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: (pago.isValidated ? D.emerald : D.gold).withOpacity(0.1),
                shape: BoxShape.circle
              ),
              child: Icon(
                pago.isValidated ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                color: pago.isValidated ? D.emerald : D.gold,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pago.proveedorComercio, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text('${pago.tipoDocumento} • ${pago.metodoPago}', style: TextStyle(color: D.slate400, fontSize: 11)),
                  Text('Ref: ${pago.referencia}', style: TextStyle(color: D.slate600, fontSize: 10, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currencyFormat.format(pago.monto), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(pago.fechaDocumento, style: TextStyle(color: D.slate600, fontSize: 11)),
              ],
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: D.slate600, size: 18),
          ],
        ),
      ),
    );
  }
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

class _Orb extends StatelessWidget {
  final Color color;
  final double size;
  const _Orb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [color, Colors.transparent])),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = D.border.withOpacity(0.3);
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

class _SkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100, margin: const EdgeInsets.only(bottom: 16, left: 24, right: 24),
      decoration: BoxDecoration(color: D.surface.withOpacity(0.5), borderRadius: BorderRadius.circular(24)),
    );
  }
}

class _EmptyDisplay extends StatelessWidget {
  final bool isSearch;
  const _EmptyDisplay({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSearch ? Icons.search_off_rounded : Icons.payments_rounded, size: 80, color: D.slate600),
          const SizedBox(height: 24),
          Text(isSearch ? 'No se encontraron pagos' : 'Historial de pagos vacío', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(isSearch ? 'Intenta con otros criterios de búsqueda' : 'Los reportes de pagos aparecerán aquí', style: TextStyle(color: D.slate400, fontSize: 14)),
        ],
      ),
    );
  }
}
