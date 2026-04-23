import 'package:get_it/get_it.dart';
import '../network/session_expired_notifier.dart';
import '../../features/uploads/data/repositories/api_upload_repository.dart';
import '../../features/uploads/domain/repositories/upload_repository.dart';
import '../../features/uploads/presentation/bloc/upload_bloc.dart';

import '../../features/auth/data/repositories/api_auth_repository.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/tour/data/repositories/api_tour_repository.dart';
import '../../features/tour/domain/repositories/tour_repository.dart';
import '../../features/tour/presentation/bloc/tour_bloc.dart';

import '../../features/settings/data/repositories/api_sede_repository.dart';
import '../../features/settings/domain/repositories/sede_repository.dart';
import '../../features/settings/presentation/bloc/sede_bloc.dart';

import '../../features/settings/data/repositories/api_payment_method_repository.dart';
import '../../features/settings/domain/repositories/payment_method_repository.dart';
import '../../features/settings/presentation/bloc/payment_method_bloc.dart';

import '../../features/catalogue/data/repositories/api_catalogue_repository.dart';
import '../../features/catalogue/domain/repositories/catalogue_repository.dart';
import '../../features/catalogue/presentation/bloc/catalogue_bloc.dart';
import '../../features/faq/data/repositories/api_faq_repository.dart';
import '../../features/faq/domain/repositories/faq_repository.dart';
import '../../features/faq/presentation/bloc/faq_bloc.dart';
import '../../features/service/data/repositories/api_service_repository.dart';
import '../../features/service/domain/repositories/service_repository.dart';
import '../../features/service/presentation/bloc/service_bloc.dart';
import '../../features/politica_reserva/data/repositories/api_politica_reserva_repository.dart';
import '../../features/politica_reserva/domain/repositories/politica_reserva_repository.dart';
import 'package:agente_viajes/features/politica_reserva/presentation/bloc/politica_reserva_bloc.dart';
import 'package:agente_viajes/features/info_empresa/presentation/bloc/info_empresa_bloc.dart';
import 'package:agente_viajes/features/info_empresa/domain/repositories/info_empresa_repository.dart';
import 'package:agente_viajes/features/info_empresa/data/repositories/api_info_empresa_repository.dart';
import '../../features/pagos_realizados/data/repositories/api_pago_realizado_repository.dart';
import '../../features/pagos_realizados/domain/repositories/pago_realizado_repository.dart';
import '../../features/pagos_realizados/presentation/bloc/pago_realizado_bloc.dart';
import '../../features/whatsapp/data/repositories/api_whatsapp_repository.dart';
import '../../features/whatsapp/domain/repositories/whatsapp_repository.dart';
import '../../features/whatsapp/domain/usecases/send_whatsapp_message.dart';
import '../../features/whatsapp/presentation/bloc/whatsapp_bloc.dart';

import '../../features/cotizaciones/data/repositories/api_cotizacion_repository.dart';
import '../../features/cotizaciones/domain/repositories/cotizacion_repository.dart';
import '../../features/cotizaciones/presentation/bloc/cotizacion_bloc.dart';
import '../../features/agentes/data/repositories/api_agente_repository.dart';
import '../../features/agentes/domain/repositories/agente_repository.dart';
import '../../features/agentes/presentation/bloc/agente_bloc.dart';

import '../../features/reservas/data/repositories/api_reserva_repository.dart';
import '../../features/reservas/domain/repositories/reserva_repository.dart';
import '../../features/reservas/presentation/bloc/reserva_bloc.dart';
import '../../features/clientes/data/repositories/api_cliente_repository.dart';
import '../../features/clientes/domain/repositories/cliente_repository.dart';
import '../../features/clientes/presentation/bloc/cliente_bloc.dart';
import '../../features/hoteles/data/repositories/api_hotel_repository.dart';
import '../../features/hoteles/domain/repositories/hotel_repository.dart';
import '../../features/hoteles/presentation/bloc/hotel_bloc.dart';
import '../../features/clientes/presentation/bloc/historial/cliente_historial_bloc.dart';
import '../../features/auditoria/data/repositories/api_auditoria_repository.dart';
import '../../features/auditoria/domain/repositories/auditoria_repository.dart';
import '../../features/auditoria/presentation/bloc/sesiones_bloc.dart';
import '../../features/auditoria/presentation/bloc/auditoria_general_bloc.dart';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../network/auth_client.dart';

final sl = GetIt.instance;

/// Initialize all dependency injection bindings.
void initDependencies() {
  // ─── Network ──────────────────────────────────────────
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => SessionExpiredNotifier());
  sl.registerLazySingleton<http.Client>(
    () => AuthClient(http.Client(), sl(), sl()),
  );

  // ─── Repositories ─────────────────────────────────────
  sl.registerLazySingleton<AuthRepository>(
    () => ApiAuthRepository(storage: sl()),
  );
  sl.registerLazySingleton<TourRepository>(
    () => ApiTourRepository(client: sl()),
  );
  sl.registerLazySingleton<SedeRepository>(
    () => ApiSedeRepository(client: sl()),
  );
  sl.registerLazySingleton<PaymentMethodRepository>(
    () => ApiPaymentMethodRepository(client: sl()),
  );
  sl.registerLazySingleton<CatalogueRepository>(
    () => ApiCatalogueRepository(client: sl()),
  );
  sl.registerLazySingleton<FaqRepository>(() => ApiFaqRepository(client: sl()));
  sl.registerLazySingleton<ServiceRepository>(
    () => ApiServiceRepository(client: sl()),
  );
  sl.registerLazySingleton<PoliticaReservaRepository>(
    () => ApiPoliticaReservaRepository(client: sl()),
  );
  sl.registerLazySingleton<InfoEmpresaRepository>(
    () => ApiInfoEmpresaRepository(client: sl()),
  );
  sl.registerLazySingleton<PagoRealizadoRepository>(
    () => ApiPagoRealizadoRepository(client: sl()),
  );
  sl.registerLazySingleton<WhatsAppRepository>(
    () => ApiWhatsAppRepository(client: sl()),
  );
  sl.registerLazySingleton<CotizacionRepository>(
    () => ApiCotizacionRepository(client: sl()),
  );
  sl.registerLazySingleton<AgenteRepository>(
    () => ApiAgenteRepository(client: sl()),
  );
  sl.registerLazySingleton<ReservaRepository>(
    () => ApiReservaRepository(client: sl()),
  );
  sl.registerLazySingleton<ClienteRepository>(
    () => ApiClienteRepository(client: sl()),
  );
  sl.registerLazySingleton<HotelRepository>(
    () => ApiHotelRepository(client: sl()),
  );
  sl.registerLazySingleton<UploadRepository>(
    () => ApiUploadRepository(client: sl()),
  );
  sl.registerLazySingleton<AuditoriaRepository>(
    () => ApiAuditoriaRepository(client: sl()),
  );

  // ─── Use Cases ────────────────────────────────────────
  sl.registerLazySingleton(() => SendWhatsAppMessage(sl()));

  // ─── BLoCs ────────────────────────────────────────────
  sl.registerFactory(() => AuthBloc(authRepository: sl()));
  sl.registerLazySingleton(() => TourBloc(tourRepository: sl()));
  sl.registerFactory(() => SedeBloc(sedeRepository: sl()));
  sl.registerFactory(() => PaymentMethodBloc(paymentMethodRepository: sl()));
  sl.registerLazySingleton(() => CatalogueBloc(catalogueRepository: sl()));
  sl.registerLazySingleton(() => FaqBloc(faqRepository: sl()));
  sl.registerLazySingleton(() => ServiceBloc(serviceRepository: sl()));
  sl.registerLazySingleton(() => PoliticaReservaBloc(repository: sl()));
  sl.registerFactory(() => InfoEmpresaBloc(repository: sl()));
  sl.registerLazySingleton(() => PagoRealizadoBloc(repository: sl()));
  sl.registerFactory(() => WhatsAppBloc(sendWhatsAppMessage: sl()));
  sl.registerLazySingleton(() => CotizacionBloc(repository: sl()));
  sl.registerFactory(() => AgenteBloc(repository: sl()));
  sl.registerFactory(() => ReservaBloc(repository: sl()));
  sl.registerFactory(() => ClienteBloc(repository: sl()));
  sl.registerLazySingleton(() => HotelBloc(repository: sl()));
  sl.registerFactory(() => UploadBloc(repository: sl()));
  sl.registerFactory(() => ClienteHistorialBloc(repository: sl()));
  sl.registerFactory(() => SesionesBloc(repository: sl()));
  sl.registerFactory(() => AuditoriaGeneralBloc(repository: sl()));
}
