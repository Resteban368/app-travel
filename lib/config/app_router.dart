import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection_container.dart';
import '../core/navigation/entity_loader.dart';
import '../core/navigation/entity_route_matcher.dart';
import '../core/navigation/not_found_screen.dart';
import '../features/tour/domain/repositories/tour_repository.dart';
import '../features/reservas/domain/repositories/reserva_repository.dart';
import '../features/clientes/domain/repositories/cliente_repository.dart';

import '../core/layout/admin_shell_wrapper.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/tour/presentation/screens/tour_list_screen.dart';
import '../features/tour/presentation/screens/tour_form_screen.dart';
import '../features/tour/presentation/screens/tour_detalle_screen.dart';
import '../features/tour/presentation/screens/tour_historico_screen.dart';
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
import '../features/cotizaciones/presentation/screens/respuesta_cotizacion_form_screen.dart';
import '../features/cotizaciones/domain/entities/cotizacion.dart';
import '../features/cotizaciones/domain/entities/respuesta_cotizacion.dart';
import '../features/agentes/presentation/screens/agente_list_screen.dart';
import '../features/agentes/presentation/screens/agente_form_screen.dart';
import '../features/agentes/domain/entities/agente.dart';

import '../features/reservas/presentation/screens/reserva_list_screen.dart';
import '../features/reservas/presentation/screens/reserva_form_screen.dart';
import '../features/reservas/domain/entities/reserva.dart';
import '../features/clientes/presentation/screens/cliente_list_screen.dart';
import '../features/clientes/presentation/screens/cliente_form_screen.dart';
import '../features/clientes/presentation/screens/cliente_historial_screen.dart';
import '../features/clientes/presentation/bloc/historial/cliente_historial_bloc.dart';
import '../features/clientes/domain/entities/cliente.dart';
import '../features/hoteles/presentation/screens/hotel_list_screen.dart';
import '../features/hoteles/presentation/screens/hotel_form_screen.dart';
import '../features/hoteles/domain/entities/hotel.dart';
import '../features/proveedores/presentation/screens/proveedor_list_screen.dart';
import '../features/proveedores/presentation/screens/proveedor_form_screen.dart';
import '../features/proveedores/domain/entities/proveedor.dart';
import '../features/bus_layouts/presentation/screens/bus_layout_list_screen.dart';
import '../features/bus_layouts/presentation/screens/bus_layout_form_screen.dart';
import '../features/bus_layouts/domain/entities/bus_layout.dart';
import '../features/bus_layouts/presentation/screens/bus_manifiesto_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/auditoria/presentation/screens/auditoria_screen.dart';
import '../features/auditoria/presentation/bloc/sesiones_bloc.dart';
import '../features/auditoria/presentation/bloc/sesiones_event.dart';
import '../features/auditoria/presentation/bloc/auditoria_general_bloc.dart';
import '../features/auditoria/presentation/bloc/auditoria_general_event.dart';
import '../features/saldos_pendientes/presentation/screens/saldo_pendiente_screen.dart';
import '../features/saldos_pendientes/presentation/screens/saldo_pendiente_detail_screen.dart';
import '../features/saldos_pendientes/presentation/bloc/saldo_pendiente_bloc.dart';
import '../features/saldos_pendientes/presentation/bloc/saldo_pendiente_detail_bloc.dart';
import '../features/saldos_pendientes/domain/entities/saldo_pendiente.dart';
import '../features/notificaciones/presentation/screens/enviar_notificacion_screen.dart';

/// Centralised route configuration.
class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String tours = '/tours';
  static const String tourCreate = '/tours/create';
  static const String toursHistorico = '/tours/historico';
  static const String tourHistoricoDetalle = '/tours/historico/detalle';
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
  static const String cotizacionResponder = '/cotizaciones/responder';
  static const String respuestaDetalle = '/cotizaciones/respuesta-detalle';
  static const String agentes = '/agentes';
  static const String agenteCreate = '/agentes/create';
  static const String agenteEdit = '/agentes/edit';

  static const String reservas = '/reservas';
  static const String reservaCreate = '/reservas/create';
  static const String clientes = '/clientes';
  static const String clienteCreate = '/clientes/create';
  static const String hoteles = '/hoteles';
  static const String hotelCreate = '/hoteles/create';
  static const String hotelEdit = '/hoteles/edit';
  static const String proveedores = '/proveedores';
  static const String proveedorCreate = '/proveedores/create';
  static const String proveedorEdit = '/proveedores/edit';
  static const String busLayouts = '/bus-layouts';
  static const String busLayoutCreate = '/bus-layouts/create';
  static const String busLayoutEdit = '/bus-layouts/edit';
  static const String busManifiesto = '/bus-layouts/manifiesto';
  static const String profile = '/profile';
  static const String auditoria = '/auditoria';
  static const String saldosPendientes = '/saldos-pendientes';
  static const String saldosPendientesDetalle = '/saldos-pendientes/detalle';
  static const String enviarNotificacion = '/notificaciones/enviar';

  // ── Rutas con ID en la URL (deep-linking real, Fase 3) ──────────────
  // La URL codifica QUÉ entidad se abre, así el refresh (F5) o compartir el
  // enlace la restauran vía fetch por ID. El objeto sigue pudiéndose pasar por
  // `arguments` como vía rápida (evita el fetch en la navegación normal).
  static String tourEditPath(String id) => '/tours/$id/edit';
  static String tourDetallePath(String id) => '/tours/$id/detalle';
  static String reservaEditPath(String id) => '/reservas/$id/edit';
  static String clienteEditPath(int id) => '/clientes/$id/edit';
  static String clienteHistorialPath(int id) => '/clientes/$id/historial';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _fadeRoute(const SplashScreen(), settings);
      case login:
        return _fadeRoute(const LoginScreen(), settings);
      default:
        // Cualquier otra ruta se abre dentro del AdminShellWrapper
        return _fadeRoute(AdminShellWrapper(initialRoute: settings.name), settings);
    }
  }

  static Route<dynamic> onGenerateNestedRoute(RouteSettings settings) {
    try {
      // 1) Rutas con ID en la URL (tours/reservas/clientes): deep-linking real.
      final byId = _matchEntityRoute(settings);
      if (byId != null) return byId;
      // 2) Rutas estáticas.
      return _buildNestedRoute(settings);
    } catch (e, st) {
      debugPrint('⚠️ [AppRouter] Error building route "${settings.name}": $e\n$st');
      return _fadeRoute(
        const NotFoundScreen(message: 'Ocurrió un error al abrir esta página.'),
        settings,
      );
    }
  }

  /// Matchea rutas cuyo path lleva el ID de la entidad (`/tours/123/edit`).
  /// Devuelve `null` si no aplica, para caer al switch de rutas estáticas.
  static Route<dynamic>? _matchEntityRoute(RouteSettings settings) {
    final match = parseEntityRoute(settings.name);
    if (match == null) return null;
    final id = match.id;

    if (match.resource == 'tours' && match.action == 'edit') {
      return _fadeRouteLight(_tourFormFor(id, argOf<Tour>(settings)), settings);
    }
    if (match.resource == 'tours' && match.action == 'detalle') {
      return _fadeRouteLight(
          _tourDetalleFor(id, argOf<Tour>(settings)), settings);
    }
    if (match.resource == 'reservas' && match.action == 'edit') {
      return _fadeRouteLight(
          _reservaFormFor(id, argOf<Reserva>(settings)), settings);
    }
    if (match.resource == 'clientes' && match.action == 'edit') {
      final intId = int.tryParse(id);
      if (intId == null) return null;
      return _fadeRouteLight(
          _clienteFormFor(intId, argOf<Cliente>(settings)), settings);
    }
    if (match.resource == 'clientes' && match.action == 'historial') {
      final intId = int.tryParse(id);
      if (intId == null) return null;
      return _fadeRoute(
          _clienteHistorialFor(intId, argOf<Cliente>(settings)), settings);
    }
    return null;
  }

  static Widget _tourFormFor(String id, Tour? preloaded) {
    if (preloaded != null) return TourFormScreen(tour: preloaded);
    return EntityLoader<Tour>(
      fetch: () => sl<TourRepository>().getTourById(id),
      builder: (_, tour) => TourFormScreen(tour: tour),
      notFoundMessage: 'No se encontró el tour solicitado.',
    );
  }

  static Widget _tourDetalleFor(String id, Tour? preloaded) {
    if (preloaded != null) return TourDetalleScreen(tour: preloaded);
    return EntityLoader<Tour>(
      fetch: () => sl<TourRepository>().getTourById(id),
      builder: (_, tour) => TourDetalleScreen(tour: tour),
      notFoundMessage: 'No se encontró el tour solicitado.',
    );
  }

  static Widget _reservaFormFor(String id, Reserva? preloaded) {
    if (preloaded != null) return ReservaFormScreen(reserva: preloaded);
    return EntityLoader<Reserva>(
      fetch: () => sl<ReservaRepository>().getReservaById(id),
      builder: (_, reserva) => ReservaFormScreen(reserva: reserva),
      notFoundMessage: 'No se encontró la reserva solicitada.',
    );
  }

  static Widget _clienteFormFor(int id, Cliente? preloaded) {
    if (preloaded != null) return ClienteFormScreen(cliente: preloaded);
    return EntityLoader<Cliente>(
      fetch: () => sl<ClienteRepository>().getClienteById(id),
      builder: (_, cliente) => ClienteFormScreen(cliente: cliente),
      notFoundMessage: 'No se encontró el cliente solicitado.',
    );
  }

  static Widget _clienteHistorialFor(int id, Cliente? preloaded) {
    Widget wrap(Cliente c) => BlocProvider(
          create: (_) => sl<ClienteHistorialBloc>(),
          child: ClienteHistorialScreen(cliente: c),
        );
    if (preloaded != null) return wrap(preloaded);
    return EntityLoader<Cliente>(
      fetch: () => sl<ClienteRepository>().getClienteById(id),
      builder: (_, cliente) => wrap(cliente),
      notFoundMessage: 'No se encontró el cliente solicitado.',
    );
  }

  static Route<dynamic> _buildNestedRoute(RouteSettings settings) {
    switch (settings.name) {
      case dashboard:
        return _fadeRoute(const DashboardScreen(), settings);
      case tours:
        return _fadeRoute(const TourListScreen(), settings);
      case toursHistorico:
        return _fadeRoute(const TourHistoricoScreen(), settings);
      case sedes:
        return _fadeRoute(const SedeListScreen(), settings);
      case paymentMethods:
        return _fadeRoute(const PaymentMethodListScreen(), settings);
      case catalogues:
        return _fadeRoute(const CatalogueListScreen(), settings);
      case faqs:
        return _fadeRoute(const FaqListScreen(), settings);
      case services:
        return _fadeRoute(const ServiceListScreen(), settings);
      case politicasReserva:
        return _fadeRoute(const PoliticaReservaListScreen(), settings);
      case infoEmpresa:
        return _fadeRoute(const InfoEmpresaListScreen(), settings);
      case pagosRealizados:
        return _fadeRoute(const PagoRealizadoListScreen(), settings);
      case cotizaciones:
        return _fadeRoute(const CotizacionesListScreen(), settings);
      case agentes:
        return _fadeRoute(const AgenteListScreen(), settings);
      case reservas:
        return _fadeRoute(const ReservaListScreen(), settings);
      case clientes:
        return _fadeRoute(const ClienteListScreen(), settings);
      case hoteles:
        return _fadeRoute(const HotelListScreen(), settings);
      case proveedores:
        return _fadeRoute(const ProveedorListScreen(), settings);
      case busLayouts:
        return _fadeRoute(const BusLayoutListScreen(), settings);
      case saldosPendientes:
        return _fadeRoute(
          BlocProvider(
            create: (_) =>
                sl<SaldoPendienteBloc>()..add(const LoadSaldosPendientes()),
            child: const SaldoPendienteScreen(),
          ),
          settings,
        );
      case saldosPendientesDetalle:
        final tour = settings.arguments as TourConSaldo;
        return _fadeRoute(
          BlocProvider(
            create: (_) => sl<SaldoPendienteDetailBloc>()
              ..add(LoadReservasPorTour(tour.tourId)),
            child: SaldoPendienteDetailScreen(tour: tour),
          ),
          settings,
        );
      case profile:
        return _fadeRoute(const ProfileScreen(), settings);
      case auditoria:
        return _fadeRoute(
          MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => sl<SesionesBloc>()..add(const LoadSesiones()),
              ),
              BlocProvider(
                create: (_) =>
                    sl<AuditoriaGeneralBloc>()..add(const LoadAuditoriaGeneral()),
              ),
            ],
            child: const AuditoriaScreen(),
          ),
          settings,
        );

      // -- Formularios y Detalles --
      // Nota: tours/reservas/clientes (edit, detalle, historial) se resuelven en
      // _matchEntityRoute con el ID en la URL (deep-linking real). Aquí solo
      // quedan las rutas estáticas; toda ruta que exija un argumento usa argOf<T>
      // y, si falta, redirige a su LISTA (nunca al perfil).
      case tourHistoricoDetalle:
        final tour = argOf<Tour>(settings);
        if (tour == null) return _fadeRoute(const TourHistoricoScreen(), settings);
        return _fadeRouteLight(
            TourFormScreen(tour: tour, duplicateMode: true), settings);
      case tourCreate:
        return _fadeRouteLight(const TourFormScreen(), settings);
      case sedeForm:
        final sede = settings.arguments as Sede?;
        return _fadeRoute(SedeFormScreen(sede: sede), settings);
      case paymentMethodForm:
        final pm = settings.arguments as PaymentMethod?;
        return _fadeRoute(PaymentMethodFormScreen(paymentMethod: pm), settings);
      case catalogueCreate:
        return _fadeRoute(const CatalogueFormScreen(), settings);
      case catalogueEdit:
        final cat = argOf<Catalogue>(settings);
        if (cat == null) return _fadeRoute(const CatalogueListScreen(), settings);
        return _fadeRoute(CatalogueFormScreen(catalogue: cat), settings);
      case faqCreate:
        return _fadeRoute(const FaqFormScreen(), settings);
      case faqEdit:
        final faq = argOf<Faq>(settings);
        if (faq == null) return _fadeRoute(const FaqListScreen(), settings);
        return _fadeRoute(FaqFormScreen(faq: faq), settings);
      case serviceCreate:
        return _fadeRoute(const ServiceFormScreen(), settings);
      case serviceEdit:
        final service = argOf<Service>(settings);
        if (service == null) return _fadeRoute(const ServiceListScreen(), settings);
        return _fadeRoute(ServiceFormScreen(service: service), settings);
      case politicaReservaCreate:
        return _fadeRoute(const PoliticaReservaFormScreen(), settings);
      case politicaReservaEdit:
        final politica = argOf<PoliticaReserva>(settings);
        if (politica == null) {
          return _fadeRoute(const PoliticaReservaListScreen(), settings);
        }
        return _fadeRoute(PoliticaReservaFormScreen(politica: politica), settings);
      case infoEmpresaCreate:
        return _fadeRoute(const InfoEmpresaFormScreen(), settings);
      case infoEmpresaEdit:
        final info = argOf<InfoEmpresa>(settings);
        if (info == null) return _fadeRoute(const InfoEmpresaListScreen(), settings);
        return _fadeRoute(InfoEmpresaFormScreen(info: info), settings);
      case pagoRealizadoCreate:
        return _fadeRouteLight(const PagoRealizadoFormScreen(), settings);
      case pagoRealizadoEdit:
        final pago = argOf<PagoRealizado>(settings);
        if (pago == null) {
          return _fadeRoute(const PagoRealizadoListScreen(), settings);
        }
        return _fadeRouteLight(PagoRealizadoFormScreen(pago: pago), settings);
      case cotizacionCreate:
        return _fadeRouteLight(
            CotizacionFormScreen(cotizacion: argOf<Cotizacion>(settings)),
            settings);
      case cotizacionResponder:
        final duplicarDe = argOf<RespuestaCotizacion>(settings);
        if (duplicarDe != null) {
          return _fadeRouteLight(
            RespuestaCotizacionFormScreen(duplicarDe: duplicarDe),
            settings,
          );
        }
        return _fadeRouteLight(
            RespuestaCotizacionFormScreen(
                cotizacion: argOf<Cotizacion>(settings)),
            settings);
      case respuestaDetalle:
        final respuesta = argOf<RespuestaCotizacion>(settings);
        if (respuesta == null) {
          return _fadeRoute(const CotizacionesListScreen(), settings);
        }
        return _fadeRouteLight(
            RespuestaCotizacionFormScreen(respuesta: respuesta), settings);
      case agenteCreate:
        return _fadeRoute(const AgenteFormScreen(), settings);
      case agenteEdit:
        final agente = argOf<Agente>(settings);
        if (agente == null) return _fadeRoute(const AgenteListScreen(), settings);
        return _fadeRoute(AgenteFormScreen(agente: agente), settings);
      case reservaCreate:
        return _fadeRouteLight(const ReservaFormScreen(), settings);
      case clienteCreate:
        return _fadeRoute(const ClienteFormScreen(), settings);
      case hotelCreate:
        return _fadeRoute(const HotelFormScreen(), settings);
      case hotelEdit:
        final hotel = argOf<Hotel>(settings);
        if (hotel == null) return _fadeRoute(const HotelListScreen(), settings);
        return _fadeRoute(HotelFormScreen(hotel: hotel), settings);
      case proveedorCreate:
        return _fadeRoute(const ProveedorFormScreen(), settings);
      case proveedorEdit:
        final proveedor = argOf<Proveedor>(settings);
        if (proveedor == null) {
          return _fadeRoute(const ProveedorListScreen(), settings);
        }
        return _fadeRoute(ProveedorFormScreen(proveedor: proveedor), settings);
      case busLayoutCreate:
        return _fadeRoute(const BusLayoutFormScreen(), settings);
      case busLayoutEdit:
        final busLayout = argOf<BusLayout>(settings);
        if (busLayout == null) {
          return _fadeRoute(const BusLayoutListScreen(), settings);
        }
        return _fadeRoute(BusLayoutFormScreen(layout: busLayout), settings);
      case busManifiesto:
        final arg = settings.arguments;
        int? tourId;
        int? salidaId;
        if (arg is Map<String, dynamic>) {
          tourId = arg['tourId'] as int?;
          salidaId = arg['salidaId'] as int?;
        } else if (arg is int) {
          tourId = arg;
        } else if (arg != null) {
          tourId = int.tryParse(arg.toString());
        }
        if (tourId == null) {
          return _fadeRoute(const BusLayoutListScreen(), settings);
        }
        return _fadeRoute(
            BusManifiestoScreen(tourId: tourId, salidaId: salidaId), settings);
      case enviarNotificacion:
        return _fadeRoute(const EnviarNotificacionScreen(), settings);

      default:
        return _fadeRoute(
          NotFoundScreen(
            message:
                'La ruta "${settings.name ?? ''}" no existe en el panel.',
          ),
          settings,
        );
    }
  }

  static PageRouteBuilder _fadeRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final fadeIn = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final fadeOut = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(fadeIn),
          child: FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: 0.92).animate(fadeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(fadeIn),
              child: child,
            ),
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
    );
  }

  /// Transición ligera (fade simple y corto, sin scale) para pantallas pesadas
  /// de formulario/detalle (reserva ~7.7k líneas, tour, cotización, pago). El
  /// fade+scale de 280 ms de [_fadeRoute] suma jank al primer frame en esas
  /// pantallas grandes; aquí lo reducimos a un fade de 120 ms.
  static PageRouteBuilder _fadeRouteLight(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 120),
      reverseTransitionDuration: const Duration(milliseconds: 100),
    );
  }
}
