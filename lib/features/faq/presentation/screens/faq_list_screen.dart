import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/saas_palette.dart';
import '../../../../core/layout/admin_shell.dart';
import '../../../../config/app_router.dart';
import '../../../../core/widgets/saas_ui_components.dart';
import '../../domain/entities/faq.dart';
import '../bloc/faq_bloc.dart';
import '../bloc/faq_event.dart';
import '../bloc/faq_state.dart';

class FaqListScreen extends StatelessWidget {
  const FaqListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell(currentIndex: 5, child: _FaqListBody());
  }
}

class _FaqListBody extends StatefulWidget {
  const _FaqListBody();

  @override
  State<_FaqListBody> createState() => _FaqListBodyState();
}

class _FaqListBodyState extends State<_FaqListBody> {
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
        authState is AuthAuthenticated && authState.user.canWrite('faqs');

    return Scaffold(
      backgroundColor: SaasPalette.bgApp,
      body: BlocBuilder<FaqBloc, FaqState>(
        builder: (context, state) {
          List<Faq> list = [];
          if (state is FaqsLoaded) {
            list = state.faqs;
          } else if (state is FaqSaving && state.faqs != null) {
            list = state.faqs!;
          } else if (state is FaqSaved && state.faqs != null) {
            list = state.faqs!;
          }

          final filtered = list.where((f) {
            final query = _searchQuery.toLowerCase();
            return f.question.toLowerCase().contains(query) ||
                f.answer.toLowerCase().contains(query);
          }).toList();

          final isLoading = state is FaqLoading && list.isEmpty;

          return RefreshIndicator(
            onRefresh: () async => context.read<FaqBloc>().add(LoadFaqs()),
            color: SaasPalette.brand600,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: _FaqHeader(canWrite: canWrite),
                  ),
                ),

                // ── Search Field ──────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
                  sliver: SliverToBoxAdapter(
                    child: SaasSearchField(
                      controller: _searchCtrl,
                      hintText: 'Buscar dudas o palabras clave...',
                      onChanged: (v) => setState(() => _searchQuery = v),
                      onClear: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
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
                        childCount: 5,
                      ),
                    ),
                  )
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: SaasEmptyState(
                      icon: _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.help_center_outlined,
                      title: _searchQuery.isNotEmpty
                          ? 'Sin coincidencias'
                          : 'Centro de ayuda vacío',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'No encontramos dudas que coincidan con "$_searchQuery".'
                          : 'Aún no se han registrado dudas frecuentes para los clientes.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final faq = filtered[index];
                        return _FaqCard(
                          faq: faq,
                          canWrite: canWrite,
                          onDelete: () => _confirmDelete(faq),
                        );
                      }, childCount: filtered.length),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(Faq faq) {
    showDialog(
      context: context,
      builder: (ctx) => SaasConfirmDialog(
        title: '¿Eliminar FAQ?',
        body:
            'Esta acción no se puede deshacer. La pregunta "${faq.question}" se eliminará permanentemente.',
        onConfirm: () {
          context.read<FaqBloc>().add(DeleteFaq(faq.id));
          Navigator.pop(ctx);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _FaqHeader extends StatelessWidget {
  final bool canWrite;
  const _FaqHeader({required this.canWrite});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SaasBreadcrumbs(items: ['Inicio', 'Centro de Ayuda', 'FAQs']),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Preguntas Frecuentes',
                    style: TextStyle(
                      color: SaasPalette.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Administra las respuestas a las dudas más comunes de tus clientes.',
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
                label: 'Nueva FAQ',
                icon: Icons.add_rounded,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.faqCreate),
              ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FAQ CARD
// ─────────────────────────────────────────────────────────────────────────────
class _FaqCard extends StatefulWidget {
  final Faq faq;
  final bool canWrite;
  final VoidCallback onDelete;

  const _FaqCard({
    required this.faq,
    required this.canWrite,
    required this.onDelete,
  });

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _isExpanded = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final f = widget.faq;

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
              color: (_isExpanded || _hovered)
                  ? SaasPalette.brand600
                  : SaasPalette.border,
              width: (_isExpanded || _hovered) ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  (_isExpanded || _hovered) ? 0.08 : 0.03,
                ),
                blurRadius: (_isExpanded || _hovered) ? 16 : 8,
                offset: Offset(0, (_isExpanded || _hovered) ? 4 : 2),
              ),
            ],
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: Radius.circular(_isExpanded ? 0 : 16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: f.isActive
                              ? SaasPalette.brand50
                              : SaasPalette.bgSubtle,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.help_center_outlined,
                          color: f.isActive
                              ? SaasPalette.brand600
                              : SaasPalette.textTertiary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          f.question,
                          style: TextStyle(
                            color: SaasPalette.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            decoration: f.isActive
                                ? null
                                : TextDecoration.lineThrough,
                            decorationColor: SaasPalette.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SaasStatusBadge(active: f.isActive),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.expand_more_rounded,
                          color: SaasPalette.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Column(
                  children: [
                    const Divider(height: 1, color: SaasPalette.border),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.answer,
                            style: const TextStyle(
                              color: SaasPalette.textSecondary,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          if (widget.canWrite) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SaasButton(
                                  label: 'Editar',
                                  icon: Icons.edit_outlined,
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    AppRouter.faqEdit,
                                    arguments: f,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SaasButton(
                                  label: 'Eliminar',
                                  icon: Icons.delete_outline_rounded,
                                  onPressed: widget.onDelete,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
