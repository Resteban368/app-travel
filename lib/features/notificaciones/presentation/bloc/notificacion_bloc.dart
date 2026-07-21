import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/notificacion.dart';
import '../../domain/repositories/notificacion_repository.dart';
import '../../data/services/sse_notificacion_service.dart';
import '../../data/services/web_notification_service.dart';

// ─── Events ──────────────────────────────────────────────

abstract class NotificacionEvent extends Equatable {
  const NotificacionEvent();
  @override
  List<Object?> get props => [];
}

class CargarNotificaciones extends NotificacionEvent {}

class ConectarSse extends NotificacionEvent {}

class DesconectarSse extends NotificacionEvent {}

class _SseDataRecibida extends NotificacionEvent {
  final Map<String, dynamic> data;
  const _SseDataRecibida(this.data);
  @override
  List<Object?> get props => [data];
}

class MarcarLeida extends NotificacionEvent {
  final int id;
  const MarcarLeida(this.id);
  @override
  List<Object?> get props => [id];
}

class MarcarTodasLeidas extends NotificacionEvent {}

class CrearNotificacion extends NotificacionEvent {
  final String titulo;
  final String mensaje;
  final String tipo;
  final int? usuarioId;

  const CrearNotificacion({
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    this.usuarioId,
  });

  @override
  List<Object?> get props => [titulo, mensaje, tipo, usuarioId];
}

class EliminarNotificacion extends NotificacionEvent {
  final int id;
  const EliminarNotificacion(this.id);
  @override
  List<Object?> get props => [id];
}

// ─── States ──────────────────────────────────────────────

abstract class NotificacionState extends Equatable {
  const NotificacionState();
  @override
  List<Object?> get props => [];
}

class NotificacionInitial extends NotificacionState {}

class NotificacionCargando extends NotificacionState {}

class NotificacionesCargadas extends NotificacionState {
  final List<Notificacion> items;
  final int totalNoLeidas;
  final bool sseConectado;

  const NotificacionesCargadas({
    required this.items,
    required this.totalNoLeidas,
    this.sseConectado = false,
  });

  NotificacionesCargadas copyWith({
    List<Notificacion>? items,
    int? totalNoLeidas,
    bool? sseConectado,
  }) =>
      NotificacionesCargadas(
        items: items ?? this.items,
        totalNoLeidas: totalNoLeidas ?? this.totalNoLeidas,
        sseConectado: sseConectado ?? this.sseConectado,
      );

  @override
  List<Object?> get props => [items, totalNoLeidas, sseConectado];
}

class NotificacionError extends NotificacionState {
  final String mensaje;
  const NotificacionError(this.mensaje);
  @override
  List<Object?> get props => [mensaje];
}

class NotificacionCreada extends NotificacionState {}

// ─── BLoC ────────────────────────────────────────────────

class NotificacionBloc extends Bloc<NotificacionEvent, NotificacionState> {
  final NotificacionRepository _repo;
  final SseNotificacionService _sseService;
  final FlutterSecureStorage _storage;
  final WebNotificationService _webNotif;

  // Reconexión SSE con backoff exponencial (1s, 2s, 4s… tope 32s).
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxBackoffExp = 6; // 2^5 = 32s máximo

  NotificacionBloc({
    required NotificacionRepository repository,
    required SseNotificacionService sseService,
    required FlutterSecureStorage storage,
    required WebNotificationService webNotificationService,
  })  : _repo = repository,
        _sseService = sseService,
        _storage = storage,
        _webNotif = webNotificationService,
        super(NotificacionInitial()) {
    on<CargarNotificaciones>(_onCargar);
    on<ConectarSse>(_onConectar);
    on<DesconectarSse>(_onDesconectar);
    on<_SseDataRecibida>(_onSseData);
    on<MarcarLeida>(_onMarcarLeida);
    on<MarcarTodasLeidas>(_onMarcarTodas);
    on<CrearNotificacion>(_onCrear);
    on<EliminarNotificacion>(_onEliminar);
  }

  List<Notificacion> get _currentItems {
    final s = state;
    if (s is NotificacionesCargadas) return s.items;
    return [];
  }

  int get _currentCount {
    final s = state;
    if (s is NotificacionesCargadas) return s.totalNoLeidas;
    return 0;
  }

  bool get _sseConectado {
    final s = state;
    if (s is NotificacionesCargadas) return s.sseConectado;
    return false;
  }

  Future<void> _onCargar(
    CargarNotificaciones event,
    Emitter<NotificacionState> emit,
  ) async {
    try {
      final listado = await _repo.getNotificaciones(limite: 30);
      emit(NotificacionesCargadas(
        items: listado.items,
        totalNoLeidas: listado.totalNoLeidas,
        sseConectado: _sseConectado,
      ));
    } catch (e) {
      debugPrint('⚠️ [NotificacionBloc] Error cargando: $e');
    }
  }

  Future<void> _onConectar(
    ConectarSse event,
    Emitter<NotificacionState> emit,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    // Al (re)conectar cancelamos cualquier reintento pendiente.
    _reconnectTimer?.cancel();

    // Carga inmediata sin esperar al evento SSE "connected"
    add(CargarNotificaciones());

    _sseService.connect(
      ApiConstants.kBaseUrl,
      token,
      onConnected: () {
        _reconnectAttempts = 0; // conexión sana → resetear backoff
        add(CargarNotificaciones());
      },
      onData: (data) => add(_SseDataRecibida(data)),
      onError: _scheduleReconnect,
    );
  }

  /// Programa una reconexión con backoff exponencial. La cae de la conexión
  /// SSE antes solo se logueaba, dejando las notificaciones muertas hasta
  /// recargar la página.
  void _scheduleReconnect() {
    if (isClosed) return;
    _reconnectTimer?.cancel();
    _reconnectAttempts = (_reconnectAttempts + 1).clamp(1, _maxBackoffExp);
    final seconds = 1 << (_reconnectAttempts - 1); // 1,2,4,8,16,32
    debugPrint('⚠️ [SSE] Conexión perdida — reintentando en ${seconds}s');
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      if (!isClosed) add(ConectarSse());
    });
  }

  Future<void> _onDesconectar(
    DesconectarSse event,
    Emitter<NotificacionState> emit,
  ) async {
    // Desconexión manual: cancelar reintentos para no reconectar solo.
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    _sseService.disconnect();
  }

  Future<void> _onSseData(
    _SseDataRecibida event,
    Emitter<NotificacionState> emit,
  ) async {
    try {
      final nueva = Notificacion.fromJson(event.data);
      final items = [nueva, ..._currentItems];
      emit(NotificacionesCargadas(
        items: items,
        totalNoLeidas: _currentCount + 1,
        sseConectado: true,
      ));
      _webNotif.showNotification(nueva.titulo, body: nueva.mensaje);
    } catch (e) {
      debugPrint('⚠️ [NotificacionBloc] Error procesando SSE: $e');
    }
  }

  Future<void> _onMarcarLeida(
    MarcarLeida event,
    Emitter<NotificacionState> emit,
  ) async {
    try {
      await _repo.marcarLeida(event.id);
      final wasUnread = _currentItems
          .where((n) => n.id == event.id)
          .any((n) => !n.leida);
      final items =
          _currentItems.map((n) => n.id == event.id ? n.copyWith(leida: true) : n).toList();
      emit(NotificacionesCargadas(
        items: items,
        totalNoLeidas: wasUnread ? (_currentCount - 1).clamp(0, 9999) : _currentCount,
        sseConectado: _sseConectado,
      ));
    } catch (e) {
      debugPrint('⚠️ [NotificacionBloc] Error marcando leída: $e');
    }
  }

  Future<void> _onMarcarTodas(
    MarcarTodasLeidas event,
    Emitter<NotificacionState> emit,
  ) async {
    try {
      await _repo.marcarTodasLeidas();
      final items = _currentItems.map((n) => n.copyWith(leida: true)).toList();
      emit(NotificacionesCargadas(
        items: items,
        totalNoLeidas: 0,
        sseConectado: _sseConectado,
      ));
    } catch (e) {
      debugPrint('⚠️ [NotificacionBloc] Error marcando todas: $e');
    }
  }

  Future<void> _onCrear(
    CrearNotificacion event,
    Emitter<NotificacionState> emit,
  ) async {
    try {
      await _repo.crearNotificacion(
        titulo: event.titulo,
        mensaje: event.mensaje,
        tipo: event.tipo,
        usuarioId: event.usuarioId,
      );
      emit(NotificacionCreada());
      // Reload para refrescar la lista del admin
      final listado = await _repo.getNotificaciones(limite: 30);
      emit(NotificacionesCargadas(
        items: listado.items,
        totalNoLeidas: listado.totalNoLeidas,
        sseConectado: _sseConectado,
      ));
    } catch (e) {
      emit(NotificacionError(e.toString()));
    }
  }

  Future<void> _onEliminar(
    EliminarNotificacion event,
    Emitter<NotificacionState> emit,
  ) async {
    try {
      await _repo.eliminarNotificacion(event.id);
      final deleted = _currentItems.firstWhere(
        (n) => n.id == event.id,
        orElse: () => Notificacion(
          id: 0, titulo: '', mensaje: '', tipo: '',
          leida: true, createdAt: DateTime.now(),
        ),
      );
      final items = _currentItems.where((n) => n.id != event.id).toList();
      final count = deleted.leida ? _currentCount : (_currentCount - 1).clamp(0, 9999);
      emit(NotificacionesCargadas(
        items: items,
        totalNoLeidas: count,
        sseConectado: _sseConectado,
      ));
    } catch (e) {
      debugPrint('⚠️ [NotificacionBloc] Error eliminando: $e');
    }
  }

  @override
  Future<void> close() {
    _reconnectTimer?.cancel();
    _sseService.disconnect();
    return super.close();
  }
}
