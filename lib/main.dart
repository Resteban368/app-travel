import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:agente_viajes/features/settings/presentation/bloc/payment_method_bloc.dart';
import 'package:agente_viajes/features/settings/presentation/bloc/sede_bloc.dart';
import 'package:agente_viajes/features/catalogue/presentation/bloc/catalogue_bloc.dart';
import 'package:agente_viajes/features/faq/presentation/bloc/faq_bloc.dart';
import 'package:agente_viajes/features/service/presentation/bloc/service_bloc.dart';
import 'package:agente_viajes/features/politica_reserva/presentation/bloc/politica_reserva_bloc.dart';
import 'package:agente_viajes/features/info_empresa/presentation/bloc/info_empresa_bloc.dart';
import 'package:agente_viajes/features/pagos_realizados/presentation/bloc/pago_realizado_bloc.dart';
import 'package:agente_viajes/features/whatsapp/presentation/bloc/whatsapp_bloc.dart';
import 'package:agente_viajes/features/cotizaciones/presentation/bloc/cotizacion_bloc.dart';
import 'package:agente_viajes/features/agentes/presentation/bloc/agente_bloc.dart';
import 'package:agente_viajes/features/reservas/presentation/bloc/reserva_bloc.dart';
import 'package:agente_viajes/features/clientes/presentation/bloc/cliente_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection_container.dart';
import 'core/theme/app_theme.dart';
import 'config/app_router.dart';
import 'features/tour/presentation/bloc/tour_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initDependencies();
  initializeDateFormatting('es_CO', null);
  runApp(const TravelToursApp());
}

class TravelToursApp extends StatelessWidget {
  const TravelToursApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TourBloc>(create: (_) => sl<TourBloc>()..add(LoadTours())),
        BlocProvider<SedeBloc>(create: (_) => sl<SedeBloc>()),
        BlocProvider<CatalogueBloc>(create: (_) => sl<CatalogueBloc>()),
        BlocProvider<PaymentMethodBloc>(create: (_) => sl<PaymentMethodBloc>()),
        BlocProvider<FaqBloc>(create: (_) => sl<FaqBloc>()),
        BlocProvider<ServiceBloc>(create: (_) => sl<ServiceBloc>()),
        BlocProvider<PoliticaReservaBloc>(
          create: (_) => sl<PoliticaReservaBloc>(),
        ),
        BlocProvider<InfoEmpresaBloc>(create: (_) => sl<InfoEmpresaBloc>()),
        BlocProvider<PagoRealizadoBloc>(create: (_) => sl<PagoRealizadoBloc>()),
        BlocProvider<WhatsAppBloc>(create: (_) => sl<WhatsAppBloc>()),
        BlocProvider<CotizacionBloc>(create: (_) => sl<CotizacionBloc>()),
        BlocProvider<AgenteBloc>(create: (_) => sl<AgenteBloc>()),
        BlocProvider<ReservaBloc>(create: (_) => sl<ReservaBloc>()),
        BlocProvider<ClienteBloc>(create: (_) => sl<ClienteBloc>()),
        BlocProvider<AuthBloc>(create: (_) => sl<AuthBloc>()),
      ],
      child: MaterialApp(
        title: 'Travel Tours Florencia - Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('es', 'CO'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'CO'),
          Locale('en', 'US'),
        ],
        initialRoute: AppRouter.splash,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
  }
}
