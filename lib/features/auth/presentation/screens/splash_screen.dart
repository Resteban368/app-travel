import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _textController;

  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineOpacity;
  late final Animation<double> _dividerWidth;

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );
    _taglineOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _dividerWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _textController.forward();
    context.read<AuthBloc>().add(const AppStarted());
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.pushReplacementNamed(context, AppRouter.dashboard);
        } else if (state is AuthInitial) {
          Navigator.pushReplacementNamed(context, AppRouter.login);
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.navy,
                Color(0xFF12283D),
                AppColors.cobalt,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -80,
                right: -60,
                child: _DecorativeCircle(size: 260, opacity: 0.06),
              ),
              Positioned(
                bottom: -100,
                left: -80,
                child: _DecorativeCircle(size: 340, opacity: 0.05),
              ),
              Positioned(
                top: 160,
                left: -40,
                child: _DecorativeCircle(size: 140, opacity: 0.04),
              ),

              // Main content
              Center(
                child: SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Travel Tours',
                          style: GoogleFonts.inter(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: AppColors.white,
                            letterSpacing: -1.0,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'FLORENCIA',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentLight,
                            letterSpacing: 7,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedBuilder(
                          animation: _dividerWidth,
                          builder: (context, _) => Container(
                            width: 60 * _dividerWidth.value,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0),
                                  AppColors.accent,
                                  AppColors.accent.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FadeTransition(
                          opacity: _taglineOpacity,
                          child: Text(
                            'Panel Administrativo',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: AppColors.grey,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom loader
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _taglineOpacity,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          color: AppColors.accent.withValues(alpha: 0.7),
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Iniciando sesión...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grey,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorativeCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.white.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}
