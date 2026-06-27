import 'package:agente_viajes/core/theme/saas_palette.dart';
import 'package:agente_viajes/core/widgets/saas_ui_components.dart';
import 'package:agente_viajes/core/widgets/dialog_loading_widget.dart';
import 'package:agente_viajes/core/widgets/saas_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../config/app_router.dart';
import '../../domain/entities/cotizacion.dart';
import '../../domain/entities/respuesta_cotizacion.dart';
import '../bloc/cotizacion_bloc.dart';
import '../bloc/cotizacion_event.dart';
import '../bloc/cotizacion_state.dart';

class CotizacionesListScreen extends StatelessWidget {
  const CotizacionesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: _CotizacionesBody());
  }
}

class _CotizacionesBody extends StatefulWidget {
  const _CotizacionesBody();
  @override
  State<_CotizacionesBody> createState() => _CotizacionesBodyState();
}

class _CotizacionesBodyState extends State<_CotizacionesBody>
    with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _showingLoadingDialog = false;

  late final AnimationController _entryCtrl;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _listOpacity;

  final _misRespuestasScrollCtrl = ScrollController();
  final _plantillasScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CotizacionBloc>().add(const LoadAllData());

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.05), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
          ),
        );
    _listOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _entryCtrl.forward();

    _misRespuestasScrollCtrl.addListener(_onMisRespuestasScroll);
    _plantillasScrollCtrl.addListener(_onPlantillasScroll);
  }

  void _onMisRespuestasScroll() {
    if (_misRespuestasScrollCtrl.position.pixels >=
        _misRespuestasScrollCtrl.position.maxScrollExtent - 200) {
      context.read<CotizacionBloc>().add(const LoadMoreMisRespuestas());
    }
  }

  void _onPlantillasScroll() {
    if (_plantillasScrollCtrl.position.pixels >=
        _plantillasScrollCtrl.position.maxScrollExtent - 200) {
      context.read<CotizacionBloc>().add(const LoadMorePlantillas());
    }
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _searchCtrl.dispose();
    _misRespuestasScrollCtrl.dispose();
    _plantillasScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _onCotizacionTap(Cotizacion cot) async {
    await Navigator.pushNamed(
      context,
      AppRouter.cotizacionCreate,
      arguments: cot,
    );
    if (mounted) {
      context.read<CotizacionBloc>().add(const LoadAllData());
    }
  }

  Widget _buildRespuestaCard(
    RespuestaCotizacion r,
    BuildContext context, {
    Map<int, Cotizacion>? cotizacionesMap,
  }) {
    final linkedCot = (r.cotizacionId != null && cotizacionesMap != null)
        ? cotizacionesMap[r.cotizacionId]
        : null;
    return _RespuestaCard(
      respuesta: r,
      clientName: linkedCot?.nombreCompleto,
      clientPhone: linkedCot?.chatId,
      linkedCotId: linkedCot?.id,
      onTap: () => _onRespuestaTap(r),
      onDuplicate: () => _onDuplicarRespuesta(r),
      onDelete: () {
        if (r.id != null) {
          context.read<CotizacionBloc>().add(DeleteRespuestaCotizacion(r.id!));
        }
      },
      onToggleAnclada: () {
        if (r.id != null) {
          context.read<CotizacionBloc>().add(
            ToggleAncladaRespuesta(r.id!, anclada: !r.anclada),
          );
        }
      },
    );
  }

  Future<void> _onDuplicarRespuesta(RespuestaCotizacion r) async {
    // Duplicar sin ID (para que sea nueva) y sin cotizacionId (requerimiento user)
    final duplicated = r.copyWith(id: null, clearCotizacionId: true);

    await Navigator.pushNamed(
      context,
      AppRouter.cotizacionResponder,
      arguments: duplicated,
    );
    if (mounted) {
      context.read<CotizacionBloc>().add(const LoadAllData());
    }
  }

  Future<void> _onRespuestaTap(RespuestaCotizacion resp) async {
    await Navigator.pushNamed(
      context,
      AppRouter.respuestaDetalle,
      arguments: resp,
    );
    if (mounted) {
      context.read<CotizacionBloc>().add(const LoadAllData());
    }
  }

  void _goToPendingPage(int page) {
    context.read<CotizacionBloc>().add(LoadPendingCotizaciones(page: page));
  }

  void _showLoadingDialog(String message) {
    if (_showingLoadingDialog) return;
    _showingLoadingDialog = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => DialogLoadingNetwork(titel: message),
    ).then((_) {
      if (mounted) {
        setState(() {
          _showingLoadingDialog = false;
        });
      }
    });
  }

  void _closeLoadingDialog() {
    if (_showingLoadingDialog && mounted) {
      _showingLoadingDialog = false;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: BlocListener<CotizacionBloc, CotizacionState>(
        listener: (context, state) {
          if (state is CotizacionDeleting) {
            _showLoadingDialog('Eliminando...');
          } else if (state is CotizacionDeleteSuccess) {
            _closeLoadingDialog();
            SaasSnackBar.showSuccess(context, state.message);
          } else if (state is CotizacionError) {
            _closeLoadingDialog();
            SaasSnackBar.showError(context, state.message);
          }
        },
        child: PopScope(
          canPop: !_showingLoadingDialog,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _showingLoadingDialog) {
              SaasSnackBar.showWarning(
                context,
                'Espera a que termine el proceso',
              );
            }
          },
          child: BlocBuilder<CotizacionBloc, CotizacionState>(
        builder: (context, state) {
          // ... (same logic for pendingList, etc.)
          List<Cotizacion> pendingList = [];
          int pendingPage = 1;
          int pendingTotalPages = 1;
          int pendingTotal = 0;

          List<RespuestaCotizacion> misRespuestas = [];
          bool misRespuestasLoading = false;
          List<RespuestaCotizacion> plantillas = [];
          bool plantillasLoading = false;
          Map<int, Cotizacion> cotizacionesMap = {};

          if (state is CotizacionLoaded) {
            pendingList = state.pendingCotizaciones;
            pendingPage = state.pendingPage;
            pendingTotalPages = state.pendingTotalPages;
            pendingTotal = state.pendingTotal;

            cotizacionesMap = {
              for (var c in state.attendedCotizaciones) c.id: c,
              for (var c in state.pendingCotizaciones) c.id: c,
            };

            misRespuestas = state.misRespuestas;
            misRespuestasLoading = state.misRespuestasLoading;
            plantillas = state.plantillas;
            plantillasLoading = state.plantillasLoading;

            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              pendingList = pendingList.where((c) {
                return c.nombreCompleto.toLowerCase().contains(q) ||
                    c.detallesPlan.toLowerCase().contains(q) ||
                    c.chatId.toLowerCase().contains(q);
              }).toList();

              bool matchRespuesta(RespuestaCotizacion resp) {
                if (resp.tituloViaje.toLowerCase().contains(q)) return true;
                if (resp.condicionesGenerales.toLowerCase().contains(q)) return true;
                if (resp.cotizacionId != null) {
                  final cot = cotizacionesMap[resp.cotizacionId];
                  if (cot != null) {
                    return cot.nombreCompleto.toLowerCase().contains(q) ||
                        cot.chatId.toLowerCase().contains(q);
                  }
                }
                return false;
              }

              misRespuestas = misRespuestas.where(matchRespuesta).toList();
              plantillas = plantillas.where(matchRespuesta).toList();
            }
          }

          return Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: FadeTransition(
                  opacity: _headerOpacity,
                  child: SlideTransition(
                    position: _headerSlide,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 600;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SaasBreadcrumbs(
                              items: ['Inicio', 'Operaciones', 'Cotizaciones'],
                            ),
                            const SizedBox(height: 16),
                            if (isMobile)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gestión de Cotizaciones',
                                    style: TextStyle(
                                      color: context.saas.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [_buildHeaderActions(context)],
                                  ),
                                ],
                              )
                            else
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Gestión de Cotizaciones',
                                      style: TextStyle(
                                        color: context.saas.textPrimary,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                  _buildHeaderActions(context),
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Search & Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 500;
                    if (isMobile) {
                      return Column(
                        children: [
                          SaasSearchField(
                            controller: _searchCtrl,
                            hintText: 'Buscar...',
                            onChanged: (v) => setState(() => _searchQuery = v),
                            onClear: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                          const SizedBox(height: 12),
                          _buildTabBar(),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: SaasSearchField(
                            controller: _searchCtrl,
                            hintText: 'Buscar por nombre o detalle...',
                            onChanged: (v) => setState(() => _searchQuery = v),
                            onClear: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildTabBar(),
                      ],
                    );
                  },
                ),
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  children: [
                    _buildListTab(
                      state: state,
                      list: pendingList,
                      currentPage: pendingPage,
                      totalPages: pendingTotalPages,
                      totalResults: pendingTotal,
                      onPageChanged: _goToPendingPage,
                      emptyText: 'No hay cotizaciones pendientes.',
                    ),
                    _buildListTab(
                      state: state,
                      list: misRespuestas,
                      emptyText: 'Aún no tienes respuestas creadas.',
                      cotizacionesMap: cotizacionesMap,
                      scrollController: _misRespuestasScrollCtrl,
                      isLoadingMore: misRespuestasLoading,
                    ),
                    _buildListTab(
                      state: state,
                      list: plantillas,
                      emptyText: 'No hay plantillas públicas disponibles.',
                      cotizacionesMap: cotizacionesMap,
                      scrollController: _plantillasScrollCtrl,
                      isLoadingMore: plantillasLoading,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  ),
);
}

  Widget _buildHeaderActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SaasButton(
          label: 'Nueva Propuesta',
          icon: Icons.send_rounded,
          isPrimary: false,
          onPressed: () async {
            await Navigator.pushNamed(context, AppRouter.cotizacionResponder);
            if (context.mounted) {
              context.read<CotizacionBloc>().add(const LoadAllData());
            }
          },
        ),
        const SizedBox(width: 10),
        SaasButton(
          label: 'Nueva Cotización',
          icon: Icons.add_rounded,
          onPressed: () async {
            await Navigator.pushNamed(context, AppRouter.cotizacionCreate);
            if (context.mounted) {
              context.read<CotizacionBloc>().add(const LoadAllData());
            }
          },
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: context.saas.bgCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.saas.border),
      ),
      child: TabBar(
        isScrollable: true,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: context.saas.brand600.withOpacity(0.1),
        ),
        indicatorPadding: const EdgeInsets.all(4),
        labelColor: context.saas.brand600,
        unselectedLabelColor: context.saas.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Sin Respuesta'),
          Tab(text: 'Mis Respuestas'),
          Tab(text: 'Plantillas'),
        ],
      ),
    );
  }

  Widget _buildListTab({
    required CotizacionState state,
    required List<dynamic> list,
    required String emptyText,
    int currentPage = 1,
    int totalPages = 1,
    int totalResults = 0,
    Function(int)? onPageChanged,
    Map<int, Cotizacion>? cotizacionesMap,
    ScrollController? scrollController,
    bool isLoadingMore = false,
  }) {
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<CotizacionBloc>().add(const LoadAllData()),
      color: context.saas.brand600,
      child: CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (state is CotizacionLoading)
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              sliver: SliverToBoxAdapter(child: SaasListSkeleton(height: 100)),
            )
          else if (state is CotizacionError)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: context.saas.danger,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar cotizaciones',
                      style: TextStyle(
                        color: context.saas.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        state.message,
                        style: TextStyle(
                          color: context.saas.textSecondary,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SaasButton(
                      label: 'Reintentar',
                      isPrimary: true,
                      onPressed: () => context.read<CotizacionBloc>().add(
                        const LoadAllData(),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (list.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: SaasEmptyState(
                icon: Icons.request_quote_outlined,
                title: 'Lista Vacía',
                subtitle: _searchQuery.isNotEmpty
                    ? 'No encontramos coincidencias para "$_searchQuery".'
                    : emptyText,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = list[index];
                  return FadeTransition(
                    opacity: _listOpacity,
                    child: item is Cotizacion
                        ? _CotizacionCard(
                            cotizacion: item,
                            onTap: () => _onCotizacionTap(item),
                          )
                        : _buildRespuestaCard(
                            item as RespuestaCotizacion,
                            context,
                            cotizacionesMap: cotizacionesMap,
                          ),
                  );
                }, childCount: list.length),
              ),
            ),
          if (onPageChanged != null && state is CotizacionLoaded && totalPages > 1)
            SliverToBoxAdapter(
              child: _PaginationBar(
                page: currentPage,
                totalPages: totalPages,
                total: totalResults,
                onPageChanged: onPageChanged,
              ),
            ),
          if (isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }
}

class _CotizacionCard extends StatefulWidget {
  final Cotizacion cotizacion;
  final VoidCallback onTap;
  const _CotizacionCard({required this.cotizacion, required this.onTap});

  @override
  State<_CotizacionCard> createState() => _CotizacionCardState();
}

class _CotizacionCardState extends State<_CotizacionCard> {
  bool _hover = false;

  void _confirmDelete(BuildContext context, Cotizacion c) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: '¿Eliminar cotización?',
        body:
            'Esta acción no se puede deshacer. ¿Deseas eliminar la cotización de ${c.nombreCompleto}?',
        onConfirm: () {
          context.read<CotizacionBloc>().add(DeleteCotizacion(c.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cotizacion;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: context.saas.bgCanvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hover ? context.saas.brand600 : context.saas.border,
              width: _hover ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hover ? 0.08 : 0.03),
                blurRadius: _hover ? 16 : 8,
                offset: Offset(0, _hover ? 4 : 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.saas.brand600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.mark_as_unread_rounded,
                      color: context.saas.brand600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                c.nombreCompleto,
                                style: TextStyle(
                                  color: context.saas.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (c.respuestaCotizacionId == null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: context.saas.warning.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: context.saas.warning.withValues(
                                      alpha: 0.4,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.hourglass_empty_rounded,
                                      size: 10,
                                      color: context.saas.warning,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Sin respuesta',
                                      style: TextStyle(
                                        color: context.saas.warning,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.phone_rounded,
                              size: 12,
                              color: context.saas.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              c.telefono ?? '',
                              style: TextStyle(
                                color: context.saas.textSecondary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Spacer(),
                            //eliminar
                            IconButton(
                              onPressed: () => _confirmDelete(context, c),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: context.saas.danger,
                              ),
                              tooltip: 'Eliminar',
                              style: IconButton.styleFrom(
                                backgroundColor: context.saas.danger.withValues(
                                  alpha: 0.08,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (c.asesorNombre != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.support_agent_rounded,
                                size: 12,
                                color: context.saas.brand600,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                c.asesorNombre!,
                                style: TextStyle(
                                  color: context.saas.brand600,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          c.detallesPlan,
                          style: TextStyle(
                            color: context.saas.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              color: context.saas.textTertiary,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat(
                                'dd MMM, hh:mm a',
                              ).format(c.createdAt.toLocal()),
                              style: TextStyle(
                                color: context.saas.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                            // if (isUnread) ...[
                            //   const SizedBox(width: 12),
                            //   Container(
                            //     padding: const EdgeInsets.symmetric(
                            //       horizontal: 6,
                            //       vertical: 2,
                            //     ),
                            //     decoration: BoxDecoration(
                            //       color: context.saas.brand600.withOpacity(0.1),
                            //       borderRadius: BorderRadius.circular(4),
                            //     ),
                            //     child: const Text(
                            //       'NUEVA',
                            //       style: TextStyle(
                            //         color: context.saas.brand600,
                            //         fontSize: 9,
                            //         fontWeight: FontWeight.w700,
                            //       ),
                            //     ),
                            //   ),
                            // ],
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

class _RespuestaCard extends StatefulWidget {
  final RespuestaCotizacion respuesta;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onToggleAnclada;
  final String? clientName;
  final String? clientPhone;
  final int? linkedCotId;

  const _RespuestaCard({
    required this.respuesta,
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
    required this.onToggleAnclada,
    this.clientName,
    this.clientPhone,
    this.linkedCotId,
  });

  @override
  State<_RespuestaCard> createState() => _RespuestaCardState();
}

class _RespuestaCardState extends State<_RespuestaCard> {
  bool _hover = false;

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: '¿Eliminar propuesta?',
        body:
            'Esta acción no se puede deshacer. ¿Deseas eliminar la propuesta "${widget.respuesta.tituloViaje}"?',
        onConfirm: () {
          widget.onDelete();
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.respuesta;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: context.saas.bgCanvas,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: r.anclada
                  ? context.saas.brand600
                  : _hover
                  ? context.saas.warning
                  : context.saas.border,
              width: r.anclada || _hover ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_hover ? 0.08 : 0.03),
                blurRadius: _hover ? 16 : 8,
                offset: Offset(0, _hover ? 4 : 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 450;

                  final content = Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.saas.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.forward_to_inbox_rounded,
                          color: context.saas.warning,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    r.tituloViaje,
                                    style: TextStyle(
                                      color: context.saas.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SaasStatusBadge(
                                  active: true,
                                  activeLabel: r.cotizacionId != null
                                      ? 'RESPUESTA'
                                      : 'DIRECTA',
                                  inactiveLabel: '',
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.clientName != null
                                  ? 'Cotización #${widget.linkedCotId} • ${widget.clientName} (${widget.clientPhone})'
                                  : r.cotizacionId != null
                                  ? 'Respuesta a Cotización #${r.cotizacionId}'
                                  : 'Propuesta Independiente',
                              style: TextStyle(
                                color: context.saas.textSecondary,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            if (r.creadoPorNombre != null) ...[
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    color: context.saas.brand900,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "${r.creadoPorNombre}",
                                      style: TextStyle(
                                        color: context.saas.textSecondary,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                            ],
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  color: context.saas.textTertiary,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM, hh:mm a',
                                  ).format(r.createdAt.toLocal()),
                                  style: TextStyle(
                                    color: context.saas.textTertiary,
                                    fontSize: 12,
                                  ),
                                ),
                                if (r.totalVistas != null && r.totalVistas! > 0) ...[
                                  const SizedBox(width: 10),
                                  Icon(
                                    Icons.visibility_rounded,
                                    color: context.saas.brand600,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${r.totalVistas} vista${r.totalVistas! != 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: context.saas.brand600,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (r.ultimaVista != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: context.saas.success,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Última vista: ${DateFormat('dd MMM, hh:mm a').format(r.ultimaVista!.toLocal())}',
                                    style: TextStyle(
                                      color: context.saas.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!isNarrow) ...[
                        const SizedBox(width: 12),
                        _buildActions(context, r),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.saas.textTertiary,
                        ),
                      ],
                    ],
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        content,
                        const SizedBox(height: 12),
                        Divider(height: 1, color: context.saas.border),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildActions(context, r),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: context.saas.textTertiary,
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return content;
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, RespuestaCotizacion r) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: widget.onToggleAnclada,
          icon: Icon(
            r.anclada ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            color: r.anclada ? context.saas.brand600 : context.saas.textTertiary,
          ),
          tooltip: r.anclada ? 'Desanclar' : 'Anclar',
          style: IconButton.styleFrom(
            backgroundColor: r.anclada
                ? context.saas.brand600.withValues(alpha: 0.1)
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SaasButton(
          label: 'Duplicar',
          icon: Icons.copy_rounded,
          onPressed: widget.onDuplicate,
          isPrimary: true,
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: () => _confirmDelete(context),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: context.saas.danger,
          ),
          tooltip: 'Eliminar',
          style: IconButton.styleFrom(
            backgroundColor: context.saas.danger.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: context.saas.bgCanvas,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.saas.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PageBtn(
              icon: Icons.chevron_left_rounded,
              enabled: page > 1,
              onTap: () => onPageChanged(page - 1),
            ),
            const SizedBox(width: 24),
            Column(
              children: [
                Text(
                  'Página $page de $totalPages',
                  style: TextStyle(
                    color: context.saas.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$total resultados',
                  style: TextStyle(
                    color: context.saas.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 24),
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

  const _PageBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled
              ? context.saas.brand600.withOpacity(0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? context.saas.brand600 : context.saas.border,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? context.saas.brand600 : context.saas.textTertiary,
          size: 24,
        ),
      ),
    );
  }
}
