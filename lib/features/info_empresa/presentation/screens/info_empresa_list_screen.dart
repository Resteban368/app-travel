import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/info_empresa.dart';
import '../bloc/info_empresa_bloc.dart';
import '../bloc/info_empresa_state.dart';

class InfoEmpresaListScreen extends StatefulWidget {
  const InfoEmpresaListScreen({super.key});

  @override
  State<InfoEmpresaListScreen> createState() => _InfoEmpresaListScreenState();
}

class _InfoEmpresaListScreenState extends State<InfoEmpresaListScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final canWrite =
        authState is AuthAuthenticated &&
        authState.user.canWrite('infoEmpresa');

    return AdminShell(
      currentIndex: 8,
      child: Scaffold(
        backgroundColor: SaasPalette.bgApp,
        body: BlocConsumer<InfoEmpresaBloc, InfoEmpresaState>(
          listener: (context, state) {
            if (state is InfoSynced) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Vectores sincronizados correctamente'),
                  backgroundColor: SaasPalette.success,
                ),
              );
            }
            if (state is InfoError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: SaasPalette.danger,
                ),
              );
            }
          },
          builder: (context, state) {
            List<InfoEmpresa> infoList = [];
            if (state is InfoLoaded)
              infoList = state.infoList;
            else if (state is InfoSaved)
              infoList = state.infoList;
            else if (state is InfoSynced)
              infoList = state.infoList;
            else if (state is InfoSyncing)
              infoList = state.infoList;
            else if (state is InfoSaving && state.infoList != null) {
              infoList = state.infoList!;
            }

            final filtered = infoList.where((i) {
              return i.nombre.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
            }).toList();

            final isLoading = state is InfoLoading && infoList.isEmpty;

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _InfoHeader(
                      infoList: infoList,
                      canWrite: canWrite,
                      isLoading: state is InfoLoading,
                    ),
                  ),
                ),

                // ── Content ────────────────────────────────────────────────
                if (isLoading)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const SaasListSkeleton(),
                        childCount: 1,
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: SaasEmptyState(
                      icon: _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.business_rounded,
                      title: _searchQuery.isNotEmpty
                          ? 'Sin coincidencias'
                          : 'Sin información',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'No encontramos información que coincida con "$_searchQuery".'
                          : 'Aún no has registrado la información corporativa de tu agencia.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final info = filtered[index];
                        return _InfoCard(
                          info: info,
                          state: state,
                          canWrite: canWrite,
                        );
                      }, childCount: filtered.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _InfoHeader extends StatelessWidget {
  final List<InfoEmpresa> infoList;
  final bool canWrite;
  final bool isLoading;

  const _InfoHeader({
    required this.infoList,
    required this.canWrite,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final showBtn = canWrite && infoList.isEmpty && !isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Configuración', 'Empresa']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Información de Empresa',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Administra la identidad corporativa y base documental de la agencia.',
                    style: TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (showBtn)
              SaasButton(
                label: 'Configurar Empresa',
                icon: Icons.settings_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.infoEmpresaCreate),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  INFO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatefulWidget {
  final InfoEmpresa info;
  final InfoEmpresaState state;
  final bool canWrite;

  const _InfoCard({
    required this.info,
    required this.state,
    required this.canWrite,
  });

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final i = widget.info;
    final isBusy = widget.state is InfoSaving || widget.state is InfoSyncing;

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
            onTap: isBusy || !widget.canWrite
                ? null
                : () => Navigator.pushNamed(
                    context,
                    AppRouter.infoEmpresaEdit,
                    arguments: i,
                  ),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: SaasPalette.brand50,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.business_rounded,
                          color: SaasPalette.brand600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.nombre,
                              style: const TextStyle(
                                color: SaasPalette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Gerente: ${i.nombreGerente}',
                              style: const TextStyle(
                                color: SaasPalette.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.canWrite && !isBusy)
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: SaasPalette.textTertiary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    i.detalles,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: SaasPalette.textSecondary,
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 24,
                    runSpacing: 12,
                    children: [
                      _ContactInfo(
                        icon: Icons.alternate_email_rounded,
                        label: i.correo,
                      ),
                      _ContactInfo(
                        icon: Icons.phone_android_rounded,
                        label: i.telefono,
                      ),
                    ],
                  ),
                  if (isBusy) ...[
                    const SizedBox(height: 20),
                    const LinearProgressIndicator(
                      backgroundColor: SaasPalette.bgApp,
                      valueColor: AlwaysStoppedAnimation(SaasPalette.brand600),
                      minHeight: 2,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ContactInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: SaasPalette.textTertiary, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: SaasPalette.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
