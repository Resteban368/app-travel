import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/premium_palette.dart';
import '../../domain/entities/cotizacion.dart';
import '../bloc/cotizacion_bloc.dart';
import '../bloc/cotizacion_event.dart';

class CotizacionDetailScreen extends StatefulWidget {
  final Cotizacion cotizacion;
  const CotizacionDetailScreen({super.key, required this.cotizacion});

  @override
  State<CotizacionDetailScreen> createState() => _CotizacionDetailScreenState();
}

class _CotizacionDetailScreenState extends State<CotizacionDetailScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _headerOpacity;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _bodyOpacity;
  late final Animation<double> _floatY;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);
    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 5000))
      ..repeat(reverse: true);

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic)),
    );
    _bodyOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );
    _floatY = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
    _shimmer = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cotizacion;
    final phone = c.chatId.contains('@') ? c.chatId.split('@')[0] : c.chatId;

    return Scaffold(
      backgroundColor: D.bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Cotización #${c.id}',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (!c.isRead)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: () {
                  context.read<CotizacionBloc>().add(MarkCotizacionAsRead(c.id));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
                label: const Text('Marcar leída',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Fondo animado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([_floatCtrl, _shimmerCtrl]),
              builder: (_, __) => _Background(shimmer: _shimmer.value, floatY: _floatY.value),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              slivers: [
                // Hero header con nombre
                SliverToBoxAdapter(
                  child: FadeTransition(
                    opacity: _headerOpacity,
                    child: SlideTransition(
                      position: _headerSlide,
                      child: _HeroHeader(cotizacion: c),
                    ),
                  ),
                ),

                // Cuerpo con todos los datos
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _bodyOpacity,
                      child: _DetailBody(cotizacion: c, phone: phone),
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
}

// ─── BACKGROUND ──────────────────────────────────────────────────────────────
class _Background extends StatelessWidget {
  final double shimmer;
  final double floatY;
  const _Background({required this.shimmer, required this.floatY});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [D.bg, Color(0xFF081223), Color(0xFF050A14)],
            ),
          ),
        ),
        Positioned(
          top: 80 + floatY * 0.5,
          right: -60,
          child: _orb(320, D.indigo.withValues(alpha: 0.10 + shimmer * 0.04)),
        ),
        Positioned(
          bottom: 60 - floatY,
          left: -80,
          child: _orb(260, D.royalBlue.withValues(alpha: 0.07)),
        ),
        Positioned.fill(child: CustomPaint(painter: _DotPainter())),
      ],
    );
  }

  Widget _orb(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      );
}

class _DotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF1A2E45).withValues(alpha: 0.45)
      ..strokeCap = StrokeCap.round;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 0.8, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── HERO HEADER ─────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final Cotizacion cotizacion;
  const _HeroHeader({required this.cotizacion});

  @override
  Widget build(BuildContext context) {
    final c = cotizacion;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [D.indigo, D.royalBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: D.indigo.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.request_quote_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.nombreCompleto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _StatusBadge(estado: c.estado),
                    if (!c.isRead) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'NUEVA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String estado;
  const _StatusBadge({required this.estado});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        estado.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── DETAIL BODY ─────────────────────────────────────────────────────────────
class _DetailBody extends StatelessWidget {
  final Cotizacion cotizacion;
  final String phone;
  const _DetailBody({required this.cotizacion, required this.phone});

  @override
  Widget build(BuildContext context) {
    final c = cotizacion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección: Datos del cliente
        _SectionLabel(label: 'DATOS DEL CLIENTE'),
        const SizedBox(height: 12),
        _InfoCard(
          children: [
            _DetailRow(icon: Icons.person_rounded, label: 'Nombre', value: c.nombreCompleto),
            _DetailRow(icon: Icons.phone_android_rounded, label: 'Celular / WhatsApp', value: phone),
            _DetailRow(
              icon: Icons.alternate_email_rounded,
              label: 'Correo electrónico',
              value: (c.correoElectronico != null && c.correoElectronico!.isNotEmpty)
                  ? c.correoElectronico!
                  : 'No especificado',
              muted: c.correoElectronico == null || c.correoElectronico!.isEmpty,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Sección: Detalles del viaje
        _SectionLabel(label: 'DETALLES DEL VIAJE'),
        const SizedBox(height: 12),
        _InfoCard(
          children: [
            _DetailRow(
              icon: Icons.flight_rounded,
              label: 'Origen → Destino',
              value: (c.origenDestino != null && c.origenDestino!.isNotEmpty)
                  ? c.origenDestino!
                  : 'No especificado',
              muted: c.origenDestino == null || c.origenDestino!.isEmpty,
            ),
            _DetailRow(
              icon: Icons.flight_takeoff_rounded,
              label: 'Fecha de salida',
              value: (c.fechaSalida != null && c.fechaSalida!.isNotEmpty)
                  ? c.fechaSalida!
                  : 'No especificada',
              muted: c.fechaSalida == null || c.fechaSalida!.isEmpty,
            ),
            _DetailRow(
              icon: Icons.flight_land_rounded,
              label: 'Fecha de regreso',
              value: (c.fechaRegreso != null && c.fechaRegreso!.isNotEmpty)
                  ? c.fechaRegreso!
                  : 'No especificada',
              muted: c.fechaRegreso == null || c.fechaRegreso!.isEmpty,
            ),
            _DetailRow(
              icon: Icons.people_alt_rounded,
              label: 'Nº pasajeros',
              value: '${c.numeroPasajeros} personas',
            ),
            _DetailRow(
              icon: Icons.child_care_rounded,
              label: 'Edades menores',
              value: (c.edadesMenuores != null && c.edadesMenuores!.isNotEmpty)
                  ? c.edadesMenuores!
                  : 'Sin menores',
              muted: c.edadesMenuores == null || c.edadesMenuores!.isEmpty,
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Sección: Plan solicitado
        _SectionLabel(label: 'PLAN SOLICITADO'),
        const SizedBox(height: 12),
        _TextBlock(text: c.detallesPlan),

        const SizedBox(height: 24),

        // Sección: Especificaciones
        _SectionLabel(label: 'ESPECIFICACIONES'),
        const SizedBox(height: 12),
        _TextBlock(
          text: (c.especificaciones != null && c.especificaciones!.isNotEmpty)
              ? c.especificaciones!
              : 'Sin especificaciones adicionales',
          muted: c.especificaciones == null || c.especificaciones!.isEmpty,
        ),

        const SizedBox(height: 24),

        // Sección: Info de la solicitud
        _SectionLabel(label: 'INFORMACIÓN DE LA SOLICITUD'),
        const SizedBox(height: 12),
        _InfoCard(
          children: [
            _DetailRow(
              icon: Icons.calendar_month_rounded,
              label: 'Fecha de solicitud',
              value: DateFormat('dd MMMM yyyy, hh:mm a', 'es_CO').format(c.createdAt.toLocal()),
            ),
            _DetailRow(
              icon: Icons.info_outline_rounded,
              label: 'Estado',
              value: c.estado,
            ),
            _DetailRow(
              icon: Icons.mark_email_read_rounded,
              label: 'Leída',
              value: c.isRead ? 'Sí' : 'No',
            ),
          ],
        ),
      ],
    );
  }
}

// ─── WIDGETS AUXILIARES ───────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [D.indigo, D.royalBlue],
          ),
          borderRadius: BorderRadius.circular(2),
        )),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: D.slate600,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: D.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, color: D.border, indent: 56),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool muted;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: D.surfaceHigh,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: muted ? D.slate600 : D.skyBlue, size: 17),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: D.slate600, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                      color: muted ? D.slate600 : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontStyle: muted ? FontStyle.italic : FontStyle.normal,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String text;
  final bool muted;
  const _TextBlock({required this.text, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: D.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: D.border),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: muted ? D.slate600 : D.slate400,
          fontSize: 15,
          height: 1.6,
          fontStyle: muted ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}
