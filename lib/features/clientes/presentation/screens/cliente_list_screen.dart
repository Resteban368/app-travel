import 'dart:async';
import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/saas_ui_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/cliente.dart';
import '../bloc/cliente_bloc.dart';
import '../bloc/cliente_event.dart';
import '../bloc/cliente_state.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ClienteListScreen extends StatefulWidget {
  const ClienteListScreen({super.key});

  @override
  State<ClienteListScreen> createState() => _ClienteListScreenState();
}

class _ClienteListScreenState extends State<ClienteListScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;

  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _contentOpacity;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _searchQuery = '';
  Timer? _debounce;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
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
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(
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

    _scrollCtrl.addListener(_onScroll);
    _loadFirstPage();
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom && !(_debounce?.isActive ?? false)) {
      final state = context.read<ClienteBloc>().state;
      // state.page == _currentPage garantiza que la página anterior ya cargó
      // antes de pedir la siguiente, evitando dispatches duplicados.
      if (state is ClienteLoaded && !state.hasReachedMax && state.page == _currentPage) {
        _loadNextPage();
      }
    }
  }

  bool get _isBottom {
    if (!_scrollCtrl.hasClients) return false;
    final maxScroll = _scrollCtrl.position.maxScrollExtent;
    final currentScroll = _scrollCtrl.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  void _loadFirstPage() {
    _currentPage = 1;
    context.read<ClienteBloc>().add(
      LoadClientes(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        page: _currentPage,
      ),
    );
  }

  void _loadNextPage() {
    _currentPage++;
    context.read<ClienteBloc>().add(
      LoadClientes(
        search: _searchQuery.isEmpty ? null : _searchQuery,
        page: _currentPage,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          BlocConsumer<ClienteBloc, ClienteState>(
            listener: (context, state) {
              if (state is ClienteError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: D.rose,
                  ),
                );
              } else if (state is ClienteActionSuccess) {
                context.read<ClienteBloc>().add(
                  LoadClientes(search: _searchQuery.isEmpty ? null : _searchQuery),
                );
              }
            },
            builder: (context, state) {
              final authState = context.watch<AuthBloc>().state;
              final canWrite =
                  authState is AuthAuthenticated &&
                  authState.user.canWrite('clientes');

              List<Cliente>? clientes;
              if (state is ClienteLoaded) {
                clientes = state.clientes;
              } else if (state is ClienteSaving && state.clientes != null) {
                clientes = state.clientes;
              } else if (state is ClienteActionSuccess) {
                clientes = state.clientes;
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                    child: FadeTransition(
                      opacity: _headerOpacity,
                      child: SlideTransition(
                        position: _headerSlide,
                        child: _buildHeader(context, canWrite),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 10),
                    child: SaasSearchField(
                      controller: _searchCtrl,
                      hintText: 'Buscar clientes',
                      onChanged: _onSearchChanged,
                      onClear: () {
                        _searchCtrl.clear();
                        _onSearchChanged('');
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: CustomScrollView(
                      controller: _scrollCtrl,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        if (state is ClienteLoading && (clientes == null || clientes.isEmpty))
                          const SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(
                                color: SaasPalette.brand600,
                              ),
                            ),
                          )
                        else ...[
                          SliverFadeTransition(
                            opacity: _contentOpacity,
                            sliver: _buildContent(
                              context,
                              state,
                              clientes,
                              canWrite,
                            ),
                          ),
                          if (state is ClienteLoaded && !state.hasReachedMax)
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
                          const SliverPadding(
                            padding: EdgeInsets.only(bottom: 100),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool canWrite) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Operaciones', 'Clientes']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Gestión de Clientes',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Administra la información y el historial de tus clientes.',
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
                label: 'Nuevo Cliente',
                icon: Icons.add_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.clienteCreate),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    ClienteState state,
    List<Cliente>? clientes,
    bool canWrite,
  ) {
    if (clientes == null || clientes.isEmpty) {
      if (state is ClienteLoading) return const SliverToBoxAdapter(child: SizedBox.shrink());
      return SliverFillRemaining(
        child: _EmptyState(isSearch: _searchQuery.isNotEmpty),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final cliente = clientes[index];
          return _ClienteCard(
            cliente: cliente,
            state: state,
            canWrite: canWrite,
          );
        }, childCount: clientes.length),
      ),
    );
  }
}

class _ClienteCard extends StatefulWidget {
  final Cliente cliente;
  final ClienteState state;
  final bool canWrite;
  const _ClienteCard({
    required this.cliente,
    required this.state,
    required this.canWrite,
  });

  @override
  State<_ClienteCard> createState() => _ClienteCardState();
}

class _ClienteCardState extends State<_ClienteCard> {
  bool _hovered = false;

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => _PremiumConfirmDialog(
        title: '¿Eliminar Cliente?',
        content:
            'Esta acción borrará a "${widget.cliente.nombre}" permanentemente.',
        onConfirm: () {
          context.read<ClienteBloc>().add(DeleteCliente(widget.cliente.id!));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: SaasPalette.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? SaasPalette.brand600 : SaasPalette.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.08 : 0.03),
              blurRadius: _hovered ? 16 : 8,
              offset: Offset(0, _hovered ? 4 : 2),
            ),
          ],
        ),
        child: InkWell(
          onTap: widget.canWrite
              ? () => Navigator.pushNamed(
                  context,
                  AppRouter.clienteEdit,
                  arguments: widget.cliente,
                )
              : null,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: D.royalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: D.royalBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nombre,
                        style: const TextStyle(
                          color: D.surface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c.correo,
                        style: TextStyle(color: D.slate400, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 12, color: D.bg),
                          const SizedBox(width: 4),
                          Text(
                            c.telefono,
                            style: TextStyle(color: D.surface, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Icon(Icons.badge_outlined, size: 12, color: D.bg),
                          const SizedBox(width: 4),
                          Text(
                            '${c.tipoDocumento}: ${c.documento}',
                            style: TextStyle(color: D.surface, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.canWrite) _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    final isSaving = widget.state is ClienteSaving;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.history_rounded, color: SaasPalette.brand600, size: 20),
          onPressed: () => Navigator.pushNamed(
            context,
            AppRouter.clienteHistorial,
            arguments: widget.cliente,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: D.skyBlue, size: 20),
          onPressed: () => Navigator.pushNamed(
            context,
            AppRouter.clienteEdit,
            arguments: widget.cliente,
          ),
        ),
        IconButton(
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: D.rose,
            size: 20,
          ),
          onPressed: isSaving ? null : _confirmDelete,
        ),
      ],
    );
  }
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
          isSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
          size: 64,
          color: D.slate800,
        ),
        const SizedBox(height: 16),
        Text(
          isSearch ? 'No se encontraron clientes' : 'Sin clientes registrados',
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

class _PremiumConfirmDialog extends StatelessWidget {
  final String title, content;
  final VoidCallback onConfirm;
  const _PremiumConfirmDialog({
    required this.title,
    required this.content,
    required this.onConfirm,
  });
  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: D.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, color: D.rose, size: 48),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            textAlign: TextAlign.center,
            style: TextStyle(color: D.slate400, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: D.slate400),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: D.rose,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
