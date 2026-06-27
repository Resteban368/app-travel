import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/widgets/premium_form_widgets.dart';
import '../../domain/entities/sesion_usuario.dart';
import '../bloc/sesiones_bloc.dart';
import '../bloc/sesiones_event.dart';
import '../bloc/sesiones_state.dart';
import '../bloc/auditoria_general_bloc.dart';
import '../bloc/auditoria_general_event.dart';
import '../bloc/auditoria_general_state.dart';
import '../../domain/entities/auditoria_general.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<SesionesBloc>().add(const LoadSesiones());
    context.read<AuditoriaGeneralBloc>().add(const LoadAuditoriaGeneral());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.saas.bgApp,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          PremiumSliverAppBar(
            title: 'Auditoría',
            actions: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: context.saas.brand600,
                indicatorWeight: 2.5,
                labelColor: context.saas.brand600,
                unselectedLabelColor: context.saas.textSecondary,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.login_rounded, size: 18),
                    text: 'Sesiones',
                  ),
                  Tab(
                    icon: Icon(Icons.history_rounded, size: 18),
                    text: 'Auditoría General',
                  ),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: const [
            _SesionesTab(),
            _AuditoriaGeneralTab(),
          ],
        ),
      ),
    );
  }
}

// ─── TabBar delegate ────────────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: context.saas.bgCanvas,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}

// ─── Sesiones Tab ────────────────────────────────────────────────────────────

class _SesionesTab extends StatefulWidget {
  const _SesionesTab();

  @override
  State<_SesionesTab> createState() => _SesionesTabState();
}

class _SesionesTabState extends State<_SesionesTab> {
  DateTime _selectedDate = DateTime.now();

  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _timeFormat = DateFormat('HH:mm:ss');

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'CO'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: context.saas.brand600,
            onPrimary: Colors.white,
            surface: context.saas.bgCanvas,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
    context.read<SesionesBloc>().add(LoadSesiones(fecha: picked));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDateFilter(),
        Expanded(
          child: BlocBuilder<SesionesBloc, SesionesState>(
            builder: (context, state) {
              if (state is SesionesLoading) return _buildLoading();
              if (state is SesionesError) return _buildError(state.message);
              if (state is SesionesLoaded) {
                return state.sesiones.isEmpty
                    ? _buildEmpty()
                    : _buildList(state.sesiones);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilter() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        border: Border(bottom: BorderSide(color: context.saas.border)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: context.saas.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            isToday ? 'Hoy — ${_dateFormat.format(_selectedDate)}' : _dateFormat.format(_selectedDate),
            style: TextStyle(
              color: context.saas.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.edit_calendar_rounded, size: 15),
            label: const Text('Cambiar fecha'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.saas.brand600,
              side: BorderSide(color: context.saas.brand600),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Recargar',
            onPressed: () => context
                .read<SesionesBloc>()
                .add(LoadSesiones(fecha: _selectedDate)),
            icon: Icon(
              Icons.refresh_rounded,
              color: context.saas.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<SesionUsuario> sesiones) {
    final activas = sesiones.where((s) => s.isActive).length;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSummaryRow(sesiones.length, activas),
        const SizedBox(height: 16),
        ...sesiones.map((s) => _SesionCard(sesion: s, timeFormat: _timeFormat)),
      ],
    );
  }

  Widget _buildSummaryRow(int total, int activas) {
    return Row(
      children: [
        _SummaryChip(
          label: 'Total sesiones',
          value: '$total',
          icon: Icons.people_rounded,
          color: context.saas.brand600,
        ),
        const SizedBox(width: 12),
        _SummaryChip(
          label: 'Activas ahora',
          value: '$activas',
          icon: Icons.circle,
          color: context.saas.success,
        ),
        const SizedBox(width: 12),
        _SummaryChip(
          label: 'Cerradas',
          value: '${total - activas}',
          icon: Icons.logout_rounded,
          color: context.saas.textTertiary,
        ),
      ],
    );
  }

  Widget _buildLoading() => ListView.builder(
    padding: const EdgeInsets.all(20),
    itemCount: 5,
    itemBuilder: (_, __) => _SkelCard(),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.event_busy_rounded,
          size: 64,
          color: context.saas.textTertiary,
        ),
        const SizedBox(height: 16),
        Text(
          'Sin sesiones el ${_dateFormat.format(_selectedDate)}',
          style: TextStyle(
            color: context.saas.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'No se registró actividad en esta fecha.',
          style: TextStyle(color: context.saas.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildError(String message) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 64,
          color: context.saas.danger,
        ),
        const SizedBox(height: 16),
        Text(
          'Error al cargar sesiones',
          style: TextStyle(
            color: context.saas.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: TextStyle(
            color: context.saas.textSecondary,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => context
              .read<SesionesBloc>()
              .add(LoadSesiones(fecha: _selectedDate)),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.saas.brand600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    ),
  );

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Sesion Card ─────────────────────────────────────────────────────────────

class _SesionCard extends StatelessWidget {
  final SesionUsuario sesion;
  final DateFormat timeFormat;

  const _SesionCard({required this.sesion, required this.timeFormat});

  @override
  Widget build(BuildContext context) {
    final color = sesion.isActive ? context.saas.success : context.saas.textTertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: sesion.isActive
              ? context.saas.success.withValues(alpha: 0.3)
              : context.saas.border,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    sesion.isActive
                        ? Icons.person_rounded
                        : Icons.person_off_rounded,
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            sesion.usuarioNombre ?? 'Usuario #${sesion.usuarioId}',
                            style: TextStyle(
                              color: context.saas.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _StatusBadge(isActive: sesion.isActive),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sesion.usuarioEmail ?? 'Sesión #${sesion.id}',
                        style: TextStyle(
                          color: context.saas.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      sesion.duracionFormateada,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'duración',
                      style: TextStyle(
                        color: context.saas.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(color: context.saas.border, height: 1),
            const SizedBox(height: 14),
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.login_rounded,
                  label: 'Inicio',
                  value: timeFormat.format(sesion.fechaInicio.toLocal()),
                ),
                if (sesion.fechaFin != null)
                  _InfoChip(
                    icon: Icons.logout_rounded,
                    label: 'Cierre',
                    value: timeFormat.format(sesion.fechaFin!.toLocal()),
                  ),
                _InfoChip(
                  icon: Icons.router_rounded,
                  label: 'IP',
                  value: sesion.ip,
                ),
                _InfoChip(
                  icon: Icons.computer_rounded,
                  label: 'Agente',
                  value: _shortUserAgent(sesion.userAgent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _shortUserAgent(String ua) {
    if (ua.length <= 40) return ua;
    return '${ua.substring(0, 37)}…';
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  const _StatusBadge({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive ? context.saas.success : context.saas.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'ACTIVA' : 'CERRADA',
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 13, color: context.saas.textTertiary),
      const SizedBox(width: 5),
      Text(
        '$label: ',
        style: TextStyle(
          color: context.saas.textTertiary,
          fontSize: 12,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          color: context.saas.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
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

class _SkelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 130,
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: context.saas.bgSubtle,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.saas.border),
    ),
  );
}

// ─── Auditoria General Tab ───────────────────────────────────────────────────

class _AuditoriaGeneralTab extends StatelessWidget {
  const _AuditoriaGeneralTab();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: BlocBuilder<AuditoriaGeneralBloc, AuditoriaGeneralState>(
            builder: (context, state) {
              if (state is AuditoriaGeneralLoading) return _buildLoading();
              if (state is AuditoriaGeneralError) return _buildError(context, state.message);
              if (state is AuditoriaGeneralLoaded) {
                return state.auditoria.isEmpty
                    ? _buildEmpty(context)
                    : _buildList(state.auditoria);
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        border: Border(bottom: BorderSide(color: context.saas.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 16, color: context.saas.textTertiary),
          const SizedBox(width: 8),
          Text(
            'Registro de cambios globales',
            style: TextStyle(
              color: context.saas.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Recargar',
            onPressed: () => context.read<AuditoriaGeneralBloc>().add(const LoadAuditoriaGeneral()),
            icon: Icon(Icons.refresh_rounded, color: context.saas.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<AuditoriaGeneral> auditoria) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: auditoria.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _AuditoriaCard(item: auditoria[index]),
    );
  }

  Widget _buildLoading() => ListView.builder(
    padding: const EdgeInsets.all(20),
    itemCount: 8,
    itemBuilder: (_, __) => _SkelCard(),
  );

  Widget _buildEmpty(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.history_toggle_off_rounded, size: 64, color: context.saas.textTertiary),
        const SizedBox(height: 16),
        Text(
          'Sin registros',
          style: TextStyle(color: context.saas.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Text(
          'No se encontraron cambios en el sistema.',
          style: TextStyle(color: context.saas.textSecondary, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _buildError(BuildContext context, String message) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline_rounded, size: 64, color: context.saas.danger),
        const SizedBox(height: 16),
        Text('Error al cargar auditoría', style: TextStyle(color: context.saas.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(message, style: TextStyle(color: context.saas.textSecondary, fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => context.read<AuditoriaGeneralBloc>().add(const LoadAuditoriaGeneral()),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.saas.brand600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ],
    ),
  );
}

class _AuditoriaCard extends StatefulWidget {
  final AuditoriaGeneral item;
  const _AuditoriaCard({required this.item});

  @override
  State<_AuditoriaCard> createState() => _AuditoriaCardState();
}

class _AuditoriaCardState extends State<_AuditoriaCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final color = _getOperationColor(widget.item.operacion);
    final icon = _getOperationIcon(widget.item.operacion);
    final df = DateFormat('dd MMM, yyyy • HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.saas.border),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: color, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.item.operacion,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        df.format(widget.item.fecha.toLocal()),
                                        style: TextStyle(
                                          color: context.saas.textTertiary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Módulo: ${widget.item.modulo.toUpperCase()}',
                                    style: TextStyle(
                                      color: context.saas.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.saas.bgApp,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMetaRow(
                                Icons.person_outline_rounded,
                                'Usuario',
                                widget.item.usuarioNombre,
                              ),
                              const SizedBox(height: 6),
                              _buildMetaRow(
                                Icons.tag_rounded,
                                'Doc ID',
                                widget.item.documentoId,
                              ),
                            ],
                          ),
                        ),
                        if (widget.item.detalle.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.data_object_rounded,
                                size: 14,
                                color: context.saas.textTertiary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'DETALLE DEL CAMBIO',
                                style: TextStyle(
                                  color: context.saas.textTertiary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  _isExpanded ? 'Ver menos' : 'Ver detalle',
                                  style: TextStyle(
                                    color: context.saas.brand600,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isExpanded) _buildExpandedDetalle(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedDetalle() {
    final detalle = widget.item.detalle;
    final bool hasDiff = detalle.containsKey('antes') && detalle.containsKey('despues');

    if (hasDiff) {
      return _buildDiffView(detalle['antes'], detalle['despues']);
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.saas.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...detalle.entries.map((e) => _buildSimpleLine(e.key, e.value)),
          const SizedBox(height: 8),
          _buildRawJsonBtn(),
        ],
      ),
    );
  }

  Widget _buildDiffView(dynamic antes, dynamic despues) {
    final Map<String, dynamic> oldMap = (antes is Map) ? Map.from(antes) : {};
    final Map<String, dynamic> newMap = (despues is Map) ? Map.from(despues) : {};
    final allKeys = {...oldMap.keys, ...newMap.keys}.toList()..sort();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.saas.bgSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: context.saas.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...allKeys.map((key) {
            final oldVal = oldMap[key];
            final newVal = newMap[key];
            if (oldVal == newVal) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${key.replaceAll('_', ' ')}: ',
                    style: TextStyle(
                      color: context.saas.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '$oldVal',
                          style: TextStyle(
                            color: context.saas.danger,
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_right_alt_rounded,
                            size: 14,
                            color: context.saas.textTertiary,
                          ),
                        ),
                        Text(
                          '$newVal',
                          style: TextStyle(
                            color: context.saas.success,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          _buildRawJsonBtn(),
        ],
      ),
    );
  }

  Widget _buildSimpleLine(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: context.saas.textSecondary, fontSize: 12),
          children: [
            TextSpan(
              text: '${key.replaceAll('_', ' ')}: ',
              style: TextStyle(color: context.saas.textTertiary, fontWeight: FontWeight.w600),
            ),
            TextSpan(text: '$value'),
          ],
        ),
      ),
    );
  }

  Widget _buildRawJsonBtn() {
    return InkWell(
      onTap: _showRawJsonDialog,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.code_rounded, size: 12, color: context.saas.brand600),
            const SizedBox(width: 4),
            Text(
              'Ver JSON completo',
              style: TextStyle(
                color: context.saas.brand600,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRawJsonDialog() {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(widget.item.detalle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E), // Estilo VS Code Dark
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF252526),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
          child: Row(
            children: [
              const Icon(Icons.code_rounded, color: Color(0xFF4EC9B0)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Inspector de Datos JSON',
                  style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText.rich(
                    _highlightJson(jsonStr),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('JSON copiado al portapapeles')),
              );
            },
            child: const Text('Copiar JSON', style: TextStyle(color: Color(0xFF4EC9B0))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  TextSpan _highlightJson(String json) {
    final List<TextSpan> spans = [];
    final RegExp regExp = RegExp(
      r'("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(\.\d+)?([eE][+-]?\d+)?)',
      multiLine: true,
    );

    int lastMatchEnd = 0;
    for (final Match match in regExp.allMatches(json)) {
      // Add text before match (delimiters like { } [ ] ,)
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: json.substring(lastMatchEnd, match.start),
          style: const TextStyle(color: Color(0xFFD4D4D4)), // Color por defecto (blanco/gris)
        ));
      }

      final String matchText = match.group(0)!;
      Color color;

      if (matchText.startsWith('"')) {
        if (matchText.endsWith(':')) {
          color = const Color(0xFF9CDCFE); // Keys (azul claro)
          spans.add(TextSpan(text: matchText.substring(0, matchText.length - 1), style: TextStyle(color: color)));
          spans.add(const TextSpan(text: ':', style: TextStyle(color: Color(0xFFD4D4D4))));
        } else {
          color = const Color(0xFFCE9178); // Strings (naranja/marron)
          spans.add(TextSpan(text: matchText, style: TextStyle(color: color)));
        }
      } else if (RegExp(r'\b(true|false|null)\b').hasMatch(matchText)) {
        color = const Color(0xFF569CD6); // Booleans/Null (azul oscuro)
        spans.add(TextSpan(text: matchText, style: TextStyle(color: color)));
      } else {
        color = const Color(0xFFB5CEA8); // Numbers (verde claro)
        spans.add(TextSpan(text: matchText, style: TextStyle(color: color)));
      }

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < json.length) {
      spans.add(TextSpan(
        text: json.substring(lastMatchEnd),
        style: const TextStyle(color: Color(0xFFD4D4D4)),
      ));
    }

    return TextSpan(children: spans);
  }

  Widget _buildMetaRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.saas.textTertiary),
        const SizedBox(width: 8),
        Text('$label: ', style: TextStyle(color: context.saas.textTertiary, fontSize: 12)),
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

  Color _getOperationColor(String op) {
    switch (op.toUpperCase()) {
      case 'CREAR': return context.saas.success;
      case 'ACTUALIZAR': return context.saas.brand600;
      case 'ELIMINAR': return context.saas.danger;
      default: return context.saas.textTertiary;
    }
  }

  IconData _getOperationIcon(String op) {
    switch (op.toUpperCase()) {
      case 'CREAR': return Icons.add_circle_outline_rounded;
      case 'ACTUALIZAR': return Icons.edit_note_rounded;
      case 'ELIMINAR': return Icons.delete_outline_rounded;
      default: return Icons.info_outline_rounded;
    }
  }
}
