import 'package:flutter/material.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/tour/presentation/screens/tour_list_screen.dart';
import '../features/tour/presentation/screens/tour_form_screen.dart';
import '../features/tour/presentation/screens/tour_detalle_screen.dart';
import '../features/settings/presentation/screens/sede_list_screen.dart';
import '../features/settings/presentation/screens/sede_form_screen.dart';
import '../features/settings/presentation/screens/payment_method_list_screen.dart';
import '../features/settings/presentation/screens/payment_method_form_screen.dart';
import '../features/tour/domain/entities/tour.dart';
import '../features/settings/domain/entities/sede.dart';
import '../features/settings/domain/entities/payment_method.dart';
import '../features/catalogue/presentation/screens/catalogue_list_screen.dart';
import '../features/catalogue/presentation/screens/catalogue_form_screen.dart';
import '../features/catalogue/domain/entities/catalogue.dart';
import '../features/faq/presentation/screens/faq_list_screen.dart';
import '../features/faq/presentation/screens/faq_form_screen.dart';
import '../features/faq/domain/entities/faq.dart';
import '../features/info_empresa/presentation/screens/info_empresa_list_screen.dart';
import '../features/info_empresa/presentation/screens/info_empresa_form_screen.dart';
import '../features/info_empresa/domain/entities/info_empresa.dart';
import '../features/service/presentation/screens/service_list_screen.dart';
import '../features/service/presentation/screens/service_form_screen.dart';
import '../features/service/domain/entities/service.dart';
import '../features/politica_reserva/presentation/screens/politica_reserva_list_screen.dart';
import '../features/politica_reserva/presentation/screens/politica_reserva_form_screen.dart';
import '../features/politica_reserva/domain/entities/politica_reserva.dart';
import '../features/pagos_realizados/presentation/screens/pago_realizado_list_screen.dart';
import '../features/pagos_realizados/presentation/screens/pago_realizado_form_screen.dart';
import '../../features/pagos_realizados/domain/entities/pago_realizado.dart';
import '../features/cotizaciones/presentation/screens/cotizaciones_list_screen.dart';
import '../features/cotizaciones/presentation/screens/cotizacion_form_screen.dart';
import '../features/cotizaciones/domain/entities/cotizacion.dart';
import '../features/agentes/presentation/screens/agente_list_screen.dart';
import '../features/agentes/presentation/screens/agente_form_screen.dart';
import '../features/agentes/domain/entities/agente.dart';

import '../features/reservas/presentation/screens/reserva_list_screen.dart';
import '../features/reservas/presentation/screens/reserva_form_screen.dart';
import '../features/reservas/domain/entities/reserva.dart';
import '../features/clientes/presentation/screens/cliente_list_screen.dart';
import '../features/clientes/presentation/screens/cliente_form_screen.dart';
import '../features/clientes/domain/entities/cliente.dart';
import '../features/hoteles/presentation/screens/hotel_list_screen.dart';
import '../features/hoteles/presentation/screens/hotel_form_screen.dart';
import '../features/hoteles/domain/entities/hotel.dart';
import '../features/profile/presentation/screens/profile_screen.dart';

/// Centralised route configuration.
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String tours = '/tours';
  static const String tourCreate = '/tours/create';
  static const String tourEdit = '/tours/edit';
  static const String tourDetalle = '/tours/detalle';
  static const String sedes = '/settings/sedes';
  static const String sedeForm = '/settings/sedes/form';
  static const String paymentMethods = '/settings/payment-methods';
  static const String paymentMethodForm = '/settings/payment-methods/form';
  static const String catalogues = '/catalogues';
  static const String catalogueCreate = '/catalogues/create';
  static const String catalogueEdit = '/catalogues/edit';
  static const String faqs = '/faqs';
  static const String faqCreate = '/faqs/create';
  static const String faqEdit = '/faqs/edit';
  static const String services = '/services';
  static const String serviceCreate = '/services/create';
  static const String serviceEdit = '/services/edit';
  static const String politicasReserva = '/politicas-reserva';
  static const String politicaReservaCreate = '/politicas-reserva/create';
  static const String politicaReservaEdit = '/politicas-reserva/edit';
  static const String infoEmpresa = '/info-empresa';
  static const String infoEmpresaCreate = '/info-empresa/create';
  static const String infoEmpresaEdit = '/info-empresa/edit';
  static const String pagosRealizados = '/pagos-realizados';
  static const String pagoRealizadoCreate = '/pagos-realizados/create';
  static const String pagoRealizadoEdit = '/pagos-realizados/edit';
  static const String cotizaciones = '/cotizaciones';
  static const String cotizacionCreate = '/cotizaciones/create';
  static const String agentes = '/agentes';
  static const String agenteCreate = '/agentes/create';
  static const String agenteEdit = '/agentes/edit';

  static const String reservas = '/reservas';
  static const String reservaCreate = '/reservas/create';
  static const String reservaEdit = '/reservas/edit';
  static const String clientes = '/clientes';
  static const String clienteCreate = '/clientes/create';
  static const String clienteEdit = '/clientes/edit';
  static const String hoteles = '/hoteles';
  static const String hotelCreate = '/hoteles/create';
  static const String hotelEdit = '/hoteles/edit';
  static const String profile = '/profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen(), settings);
      case login:
        return _fadeRoute(const LoginScreen(), settings);
      case dashboard:
        return _fadeRoute(const DashboardScreen(), settings);
      case tours:
        return _fadeRoute(const TourListScreen(), settings);
      case tourCreate:
        return _fadeRoute(const TourFormScreen(), settings);
      case tourEdit:
        final tour = settings.arguments as Tour;
        return _fadeRoute(TourFormScreen(tour: tour), settings);
      case tourDetalle:
        final tour = settings.arguments as Tour;
        return _fadeRoute(TourDetalleScreen(tour: tour), settings);
      case sedes:
        return _fadeRoute(const SedeListScreen(), settings);
      case sedeForm:
        final sede = settings.arguments as Sede?;
        return _fadeRoute(SedeFormScreen(sede: sede), settings);
      case paymentMethods:
        return _fadeRoute(const PaymentMethodListScreen(), settings);
      case paymentMethodForm:
        final method = settings.arguments as PaymentMethod?;
        return _fadeRoute(
          PaymentMethodFormScreen(paymentMethod: method),
          settings,
        );
      case catalogues:
        return _fadeRoute(const CatalogueListScreen(), settings);
      case catalogueCreate:
        return _fadeRoute(const CatalogueFormScreen(), settings);
      case catalogueEdit:
        final catalogue = settings.arguments as Catalogue;
        return _fadeRoute(CatalogueFormScreen(catalogue: catalogue), settings);
      case faqs:
        return _fadeRoute(const FaqListScreen(), settings);
      case faqCreate:
        return _fadeRoute(const FaqFormScreen(), settings);
      case faqEdit:
        final faq = settings.arguments as Faq;
        return _fadeRoute(FaqFormScreen(faq: faq), settings);
      case services:
        return _fadeRoute(const ServiceListScreen(), settings);
      case serviceCreate:
        return _fadeRoute(const ServiceFormScreen(), settings);
      case serviceEdit:
        final service = settings.arguments as Service;
        return _fadeRoute(ServiceFormScreen(service: service), settings);
      case politicasReserva:
        return _fadeRoute(const PoliticaReservaListScreen(), settings);
      case politicaReservaCreate:
        return _fadeRoute(const PoliticaReservaFormScreen(), settings);
      case politicaReservaEdit:
        final politica = settings.arguments as PoliticaReserva;
        return _fadeRoute(
          PoliticaReservaFormScreen(politica: politica),
          settings,
        );
      case infoEmpresa:
        return _fadeRoute(const InfoEmpresaListScreen(), settings);
      case infoEmpresaCreate:
        return _fadeRoute(const InfoEmpresaFormScreen(), settings);
      case infoEmpresaEdit:
        final info = settings.arguments as InfoEmpresa;
        return _fadeRoute(InfoEmpresaFormScreen(info: info), settings);
      case pagosRealizados:
        return _fadeRoute(const PagoRealizadoListScreen(), settings);
      case pagoRealizadoCreate:
        return _fadeRoute(const PagoRealizadoFormScreen(), settings);
      case pagoRealizadoEdit:
        final pago = settings.arguments as PagoRealizado;
        return _fadeRoute(PagoRealizadoFormScreen(pago: pago), settings);
      case cotizaciones:
        return _fadeRoute(const CotizacionesListScreen(), settings);
      case cotizacionCreate:
        final cotizacion = settings.arguments as Cotizacion?;
        return _fadeRoute(
          CotizacionFormScreen(cotizacion: cotizacion),
          settings,
        );

      case agentes:
        return _fadeRoute(const AgenteListScreen(), settings);
      case agenteCreate:
        return _fadeRoute(const AgenteFormScreen(), settings);
      case agenteEdit:
        final agente = settings.arguments as Agente;
        return _fadeRoute(AgenteFormScreen(agente: agente), settings);
      case reservas:
        return _fadeRoute(const ReservaListScreen(), settings);
      case reservaCreate:
        return _fadeRoute(const ReservaFormScreen(), settings);
      case reservaEdit:
        final reserva = settings.arguments as Reserva;
        return _fadeRoute(ReservaFormScreen(reserva: reserva), settings);
      case clientes:
        return _fadeRoute(const ClienteListScreen(), settings);
      case clienteCreate:
        return _fadeRoute(const ClienteFormScreen(), settings);
      case clienteEdit:
        final cliente = settings.arguments as Cliente;
        return _fadeRoute(ClienteFormScreen(cliente: cliente), settings);
      case hoteles:
        return _fadeRoute(const HotelListScreen(), settings);
      case hotelCreate:
        return _fadeRoute(const HotelFormScreen(), settings);
      case hotelEdit:
        final hotel = settings.arguments as Hotel;
        return _fadeRoute(HotelFormScreen(hotel: hotel), settings);
      case profile:
        return _fadeRoute(const ProfileScreen(), settings);
      default:
        return _fadeRoute(const LoginScreen(), settings);
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  }
}
