import '../entities/notificacion.dart';

abstract class NotificacionRepository {
  Future<NotificacionListado> getNotificaciones({
    bool soloNoLeidas = false,
    int limite = 30,
    int pagina = 1,
  });
  Future<int> getCountNoLeidas();
  Future<void> marcarLeida(int id);
  Future<int> marcarTodasLeidas();
  Future<Notificacion> crearNotificacion({
    required String titulo,
    required String mensaje,
    required String tipo,
    int? usuarioId,
  });
  Future<void> eliminarNotificacion(int id);
}
