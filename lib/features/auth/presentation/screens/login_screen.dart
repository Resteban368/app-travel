import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../config/app_router.dart';
import '../bloc/auth_bloc.dart';

// ─── Paleta del producto ──────────────────────────────────────────────────────
class _C {
  static const bg = Color(0xFF070F1C);
  static const surface = Color(0xFF0D1828);
  static const panel = Color(0xFF0B1520);
  static const border = Color(0xFF1A2E45);
  static const royalBlue = Color(0xFF1447E6);
  static const skyBlue = Color(0xFF38BDF8);
  static const cyan = Color(0xFF06B6D4);
  static const indigo = Color(0xFF6366F1);
  static const gold = Color(0xFFF59E0B);
  static const white = Colors.white;
  static const offWhite = Color(0xFFF1F5F9);
  static const slate400 = Color(0xFF94A3B8);
  static const slate600 = Color(0xFF475569);
  static const inputBg = Color(0xFFF8FAFC);
  static const inputBorder = Color(0xFFE2E8F0);
  static const textDark = Color(0xFF0F172A);
  static const error = Color(0xFFEF4444);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _entryCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _shimmerCtrl;

  late final Animation<double> _leftOpacity;
  late final Animation<Offset> _leftSlide;
  late final Animation<double> _rightOpacity;
  late final Animation<Offset> _rightSlide;
  late final Animation<double> _logoScale;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _featuresOpacity;
  late final Animation<Offset> _featuresSlide;
  late final Animation<double> _formOpacity;
  late final Animation<Offset> _formSlide;
  late final Animation<double> _btnOpacity;

  late final Animation<double> _floatY;
  late final Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    )..repeat(reverse: true);

    _leftOpacity = _fade(0.00, 0.38);
    _leftSlide = _slide(0.00, 0.38, const Offset(-0.05, 0));
    _rightOpacity = _fade(0.12, 0.52);
    _rightSlide = _slide(0.12, 0.52, const Offset(0.05, 0));
    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.22, 0.52, curve: Curves.elasticOut),
      ),
    );
    _subtitleOpacity = _fade(0.30, 0.55);
    _featuresOpacity = _fade(0.42, 0.68);
    _featuresSlide = _slide(0.42, 0.68, const Offset(0, 0.08));
    _formOpacity = _fade(0.38, 0.65);
    _formSlide = _slide(0.38, 0.65, const Offset(0, 0.08));
    _btnOpacity = _fade(0.62, 0.88);

    _floatY = Tween<double>(
      begin: -7,
      end: 7,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _shimmer = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _entryCtrl.forward();
  }

  Animation<double> _fade(double s, double e) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOut),
        ),
      );

  Animation<Offset> _slide(double s, double e, Offset begin) =>
      Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(s, e, curve: Curves.easeOutCubic),
        ),
      );

  @override
  void dispose() {
    _entryCtrl.dispose();
    _floatCtrl.dispose();
    _shimmerCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, AppRouter.dashboard);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: _C.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      builder: (context, state) => Scaffold(
        body: LayoutBuilder(
          builder: (_, c) => c.maxWidth >= 860
              ? _desktop(context, state)
              : _mobile(context, state),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DESKTOP
  // ══════════════════════════════════════════════════════════════════════════
  Widget _desktop(BuildContext context, AuthState state) {
    return Row(
      children: [
        Expanded(
          flex: 58,
          child: AnimatedBuilder(
            animation: Listenable.merge([_entryCtrl, _floatCtrl, _shimmerCtrl]),
            builder: (_, __) => FadeTransition(
              opacity: _leftOpacity,
              child: SlideTransition(position: _leftSlide, child: _leftPanel()),
            ),
          ),
        ),
        Expanded(
          flex: 42,
          child: AnimatedBuilder(
            animation: _entryCtrl,
            builder: (_, __) => FadeTransition(
              opacity: _rightOpacity,
              child: SlideTransition(
                position: _rightSlide,
                child: _rightPanel(context, state),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  MOBILE
  // ══════════════════════════════════════════════════════════════════════════
  Widget _mobile(BuildContext context, AuthState state) {
    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _shimmerCtrl,
            builder: (_, __) =>
                CustomPaint(painter: _MobileBgPainter(_shimmer.value)),
          ),
        ),
        // Ícono decorativo
        Positioned(
          top: 52,
          right: 20,
          child: LayoutBuilder(
            builder: (_, c) {
              final iconSize = c.maxWidth >= 600 ? 120.0 : 80.0;
              return AnimatedBuilder(
                animation: _floatCtrl,
                builder: (_, _) => Transform.translate(
                  offset: Offset(0, _floatY.value * 0.4),
                  child: Transform.rotate(
                    angle: -math.pi / 8,
                    child: Icon(
                      Icons.flight,
                      size: iconSize,
                      color: _C.skyBlue.withOpacity(0.6),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
            child: AnimatedBuilder(
              animation: _entryCtrl,
              builder: (_, __) => FadeTransition(
                opacity: _rightOpacity,
                child: SlideTransition(
                  position: _rightSlide,
                  child: _mobileCard(context, state),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PANEL IZQUIERDO — Identidad de producto
  // ══════════════════════════════════════════════════════════════════════════
  Widget _leftPanel() {
    return Stack(
      children: [
        // Fondo base
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_C.bg, _C.surface, _C.panel],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Banda distorsionada – esquina superior derecha (azul eléctrico)
        Positioned.fill(
          child: ClipPath(
            clipper: const _SkewClipper(
              p1: Offset(0.48, 0),
              p2: Offset(1, 0),
              p3: Offset(1, 0.68),
              p4: Offset(0.62, 0.52),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [
                    _C.royalBlue.withOpacity(0.40),
                    _C.indigo.withOpacity(0.10),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Banda distorsionada – esquina inferior izquierda (cyan/gold)
        Positioned.fill(
          child: ClipPath(
            clipper: const _SkewClipper(
              p1: Offset(0, 0.68),
              p2: Offset(0.58, 0.82),
              p3: Offset(1, 1),
              p4: Offset(0, 1),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [
                    _C.cyan.withOpacity(0.18),
                    _C.gold.withOpacity(0.06),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Orbe animado — arriba izquierda
        Positioned(
          top: -80,
          left: -80,
          child: _pulsatingOrb(
            300,
            Color.lerp(
              _C.royalBlue.withOpacity(0.18),
              _C.indigo.withOpacity(0.30),
              _shimmer.value,
            )!,
          ),
        ),

        // Orbe animado — abajo derecha
        Positioned(
          bottom: -100,
          right: -100,
          child: _pulsatingOrb(
            380,
            Color.lerp(
              _C.cyan.withOpacity(0.08),
              _C.gold.withOpacity(0.14),
              _shimmer.value,
            )!,
          ),
        ),

        // Patrón de puntos
        Positioned.fill(child: CustomPaint(painter: _DotGridPainter())),

        // Líneas de ruta animadas
        Positioned.fill(
          child: CustomPaint(painter: _RoutePainter(_floatY.value)),
        ),

        // ── Contenido ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(52, 0, 44, 52),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo del producto
              AnimatedBuilder(
                animation: _floatCtrl,
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, _floatY.value * 0.6),
                  child: _productLogo(size: 72),
                ),
              ),
              const SizedBox(height: 28),

              // Nombre + badge
              FadeTransition(
                opacity: _subtitleOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'AgenteViajes',
                          style: TextStyle(
                            color: _C.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_C.royalBlue, _C.indigo],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PLATFORM',
                            style: TextStyle(
                              color: _C.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'La plataforma todo-en-uno para\nagencias de viaje modernas.',
                      style: TextStyle(
                        color: _C.slate400.withOpacity(0.9),
                        fontSize: 15,
                        height: 1.60,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Features
              SlideTransition(
                position: _featuresSlide,
                child: FadeTransition(
                  opacity: _featuresOpacity,
                  child: Column(
                    children: [
                      _featureRow(
                        Icons.confirmation_number_outlined,
                        'Gestión de tours y reservaciones',
                        'Crea, edita y da seguimiento en tiempo real.',
                      ),
                      const SizedBox(height: 14),
                      _featureRow(
                        Icons.receipt_long_outlined,
                        'Pagos y cotizaciones integradas',
                        'Controla cada transacción desde un panel.',
                      ),
                      const SizedBox(height: 14),
                      _featureRow(
                        Icons.store_outlined,
                        'Multi-sucursal y configuración',
                        'Gestiona sedes, medios de pago y más.',
                      ),
                      const SizedBox(height: 14),
                      _featureRow(
                        Icons.analytics_outlined,
                        'Catálogo digital y marketing',
                        'Publica paquetes con precios y promociones.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Social proof
              FadeTransition(opacity: _btnOpacity, child: _socialProof()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pulsatingOrb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );

  Widget _productLogo({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.skyBlue, _C.royalBlue],
        ),
        borderRadius: BorderRadius.circular(size * 0.27),
        boxShadow: [
          BoxShadow(
            color: _C.skyBlue.withOpacity(0.38),
            blurRadius: 28,
            spreadRadius: 3,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: _C.royalBlue.withOpacity(0.25),
            blurRadius: 50,
            spreadRadius: -4,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.15),
        child: AnimatedBuilder(
          animation: _floatCtrl,
          builder: (_, _) => Transform.translate(
            offset: Offset(0, _floatY.value * 0.3),
            child: Icon(
              Icons.flight,
              size: size * 0.7,
              color: _C.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _C.royalBlue.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _C.skyBlue.withOpacity(0.22)),
          ),
          child: Icon(icon, color: _C.skyBlue, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _C.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: _C.slate400.withOpacity(0.75),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _socialProof() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _C.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.border.withOpacity(0.8)),
      ),
      child: Row(
        children: [
          // Avatars apilados
          SizedBox(
            width: 68,
            height: 28,
            child: Stack(
              children: List.generate(3, (i) {
                final colors = [
                  [_C.skyBlue, _C.royalBlue],
                  [_C.cyan, _C.indigo],
                  [_C.gold, _C.royalBlue],
                ];
                return Positioned(
                  left: i * 20.0,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors[i]),
                      shape: BoxShape.circle,
                      border: Border.all(color: _C.surface, width: 2),
                    ),
                    child: Icon(
                      Icons.business_center_rounded,
                      color: _C.white.withOpacity(0.85),
                      size: 12,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agencias activas en la plataforma',
                  style: TextStyle(
                    color: _C.white,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gestión centralizada · Actualización continua',
                  style: TextStyle(
                    color: _C.slate400.withOpacity(0.7),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PANEL DERECHO — Formulario (desktop)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _rightPanel(BuildContext context, AuthState state) {
    return Container(
      color: _C.offWhite,
      child: Stack(
        children: [
          // Splash top-right sutil
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [_C.skyBlue.withOpacity(0.10), Colors.transparent],
                ),
              ),
            ),
          ),
          // Franja diagonal decorativa sup
          Positioned.fill(
            child: ClipPath(
              clipper: const _SkewClipper(
                p1: Offset(0, 0),
                p2: Offset(1, 0),
                p3: Offset(1, 0.055),
                p4: Offset(0, 0.11),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.royalBlue.withOpacity(0.09),
                      _C.skyBlue.withOpacity(0.04),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Formulario centrado
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 52, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: LayoutBuilder(
                  builder: (_, c) => _formContent(context, state, c.maxWidth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CARD MÓVIL
  // ══════════════════════════════════════════════════════════════════════════
  Widget _mobileCard(BuildContext context, AuthState state) {
    return Container(
      decoration: BoxDecoration(
        color: _C.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 48,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(30),
      child: LayoutBuilder(
        builder: (_, c) => _formContent(context, state, c.maxWidth),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CONTENIDO FORMULARIO (compartido desktop / mobile)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _formContent(BuildContext context, AuthState state, double maxWidth) {
    final logoSize = maxWidth >= 400 ? 56.0 : 52.0;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo pequeño
          ScaleTransition(
            scale: _logoScale,
            child: _productLogo(size: logoSize),
          ),
          const SizedBox(height: 20),

          // Título
          FadeTransition(
            opacity: _subtitleOpacity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: _C.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Accede al panel de tu agencia',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: _C.slate600.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Campos
          SlideTransition(
            position: _formSlide,
            child: FadeTransition(
              opacity: _formOpacity,
              child: Column(
                children: [
                  _inputField(
                    ctrl: _usernameCtrl,
                    label: 'Correo o usuario',
                    hint: 'tucorreo@agencia.com',
                    icon: Icons.alternate_email_rounded,
                  ),
                  const SizedBox(height: 14),
                  _passwordInputField(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Botón
          FadeTransition(
            opacity: _btnOpacity,
            child: _loginBtn(context, state),
          ),
          const SizedBox(height: 20),

          // Divisor
          FadeTransition(
            opacity: _btnOpacity,
            child: Row(
              children: [
                Expanded(child: Divider(color: _C.inputBorder, height: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'AgenteViajes Platform',
                    style: TextStyle(
                      fontSize: 11,
                      color: _C.slate600.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: _C.inputBorder, height: 1)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Pie
          FadeTransition(
            opacity: _btnOpacity,
            child: Center(
              child: Text(
                '© ${DateTime.now().year} AgenteViajes · Todos los derechos reservados',
                style: TextStyle(
                  fontSize: 10.5,
                  color: _C.slate600.withOpacity(0.45),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Campos ─────────────────────────────────────────────────────────────────
  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) => InputDecoration(
    labelText: label,
    hintText: hint,
    hintStyle: TextStyle(color: _C.slate600.withOpacity(0.4), fontSize: 13),
    labelStyle: TextStyle(
      fontSize: 13,
      color: _C.slate600.withOpacity(0.85),
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: _C.royalBlue,
    ),
    prefixIcon: Icon(icon, size: 17, color: _C.slate600),
    suffixIcon: suffix,
    filled: true,
    fillColor: _C.inputBg,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _C.inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: _C.inputBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.royalBlue, width: 1.8),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _C.error, width: 1.8),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
  );

  Widget _inputField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
  }) => TextFormField(
    controller: ctrl,
    style: const TextStyle(fontSize: 14, color: _C.textDark),
    decoration: _decoration(label: label, hint: hint, icon: icon),
    validator: (v) =>
        (v == null || v.isEmpty) ? 'Este campo es requerido' : null,
  );

  Widget _passwordInputField() => TextFormField(
    controller: _passwordCtrl,
    obscureText: _obscurePassword,
    style: const TextStyle(fontSize: 14, color: _C.textDark),
    decoration: _decoration(
      label: 'Contraseña',
      hint: '••••••••',
      icon: Icons.lock_outline_rounded,
      suffix: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          size: 17,
          color: _C.slate600,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
    ),
    validator: (v) =>
        (v == null || v.isEmpty) ? 'Este campo es requerido' : null,
  );

  // ── Botón ──────────────────────────────────────────────────────────────────
  Widget _loginBtn(BuildContext context, AuthState state) {
    final loading = state is AuthLoading;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: loading
              ? null
              : const LinearGradient(
                  colors: [_C.royalBlue, Color(0xFF2563EB), _C.skyBlue],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: loading
              ? []
              : [
                  BoxShadow(
                    color: _C.royalBlue.withOpacity(0.38),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: loading
              ? null
              : () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(
                      LoginRequested(
                        username: _usernameCtrl.text.trim(),
                        password: _passwordCtrl.text,
                      ),
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: _C.slate600.withOpacity(0.2),
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: _C.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Iniciar sesión',
                      style: TextStyle(
                        color: _C.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: _C.white,
                      size: 17,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  CLIPPER DISTORSIONADO — cuadrilátero con coordenadas relativas (0–1)
// ══════════════════════════════════════════════════════════════════════════════
class _SkewClipper extends CustomClipper<Path> {
  final Offset p1, p2, p3, p4;
  const _SkewClipper({
    required this.p1,
    required this.p2,
    required this.p3,
    required this.p4,
  });

  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * p1.dx, s.height * p1.dy)
    ..lineTo(s.width * p2.dx, s.height * p2.dy)
    ..lineTo(s.width * p3.dx, s.height * p3.dy)
    ..lineTo(s.width * p4.dx, s.height * p4.dy)
    ..close();

  @override
  bool shouldReclip(_SkewClipper o) => false;
}

// ══════════════════════════════════════════════════════════════════════════════
//  PAINTERS
// ══════════════════════════════════════════════════════════════════════════════
class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeCap = StrokeCap.round;
    const sp = 28.0;
    for (double x = sp / 2; x < size.width; x += sp) {
      for (double y = sp / 2; y < size.height; y += sp) {
        canvas.drawCircle(Offset(x, y), 1.3, p);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter p) => false;
}

class _RoutePainter extends CustomPainter {
  final double offset;
  const _RoutePainter(this.offset);

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Ruta principal (arco curvo)
    final arc = Path()
      ..moveTo(s.width * 0.05, s.height * 0.82 + offset * 0.25)
      ..cubicTo(
        s.width * 0.25,
        s.height * 0.30,
        s.width * 0.70,
        s.height * 0.55,
        s.width * 0.95,
        s.height * 0.18 + offset * 0.25,
      );

    _drawDashed(canvas, arc, stroke, 9, 5);

    // Ruta secundaria (más sutil)
    final arc2 = Path()
      ..moveTo(s.width * 0.02, s.height * 0.45 + offset * 0.15)
      ..cubicTo(
        s.width * 0.20,
        s.height * 0.20,
        s.width * 0.55,
        s.height * 0.38,
        s.width * 0.80,
        s.height * 0.10 + offset * 0.15,
      );

    stroke.color = Colors.white.withOpacity(0.035);
    _drawDashed(canvas, arc2, stroke, 6, 6);

    // Nodo final ruta principal
    canvas.drawCircle(
      Offset(s.width * 0.95, s.height * 0.18 + offset * 0.25),
      4.0,
      Paint()..color = _C.skyBlue.withOpacity(0.30),
    );
    canvas.drawCircle(
      Offset(s.width * 0.95, s.height * 0.18 + offset * 0.25),
      2.0,
      Paint()..color = _C.skyBlue.withOpacity(0.60),
    );
  }

  void _drawDashed(Canvas c, Path path, Paint p, double dash, double gap) {
    for (final m in path.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        c.drawPath(m.extractPath(d, math.min(d + dash, m.length)), p);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_RoutePainter o) => o.offset != offset;
}

class _MobileBgPainter extends CustomPainter {
  final double pulse;
  const _MobileBgPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Fondo base
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_C.bg, _C.surface, Color(0xFF0F1E35)],
          stops: [0.0, 0.5, 1.0],
        ).createShader(rect),
    );

    // Banda distorsionada azul
    final band = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.40)
      ..lineTo(0, size.height * 0.58)
      ..close();

    canvas.drawPath(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color.lerp(
              _C.royalBlue.withOpacity(0.30),
              _C.indigo.withOpacity(0.20),
              pulse,
            )!,
            Colors.transparent,
          ],
        ).createShader(rect),
    );

    // Grilla de puntos
    final dot = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeCap = StrokeCap.round;
    const sp = 24.0;
    for (double x = sp / 2; x < size.width; x += sp) {
      for (double y = sp / 2; y < size.height; y += sp) {
        canvas.drawCircle(Offset(x, y), 1.1, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_MobileBgPainter o) => o.pulse != pulse;
}
