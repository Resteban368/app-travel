/// Jerarquía de errores de red compartida por toda la capa de datos.
///
/// Objetivo (Fase 1): reemplazar progresivamente los ~146 `catch (e)` ad-hoc
/// por tipos que la UI pueda distinguir (¿error del servidor?, ¿sin red?,
/// ¿sesión expirada?) sin parsear strings de mensajes.
///
/// - [ApiException] (en `api_exception.dart`): el servidor respondió con un
///   status de error y, normalmente, un mensaje de negocio.
/// - [NetworkException]: no se pudo hablar con el servidor (sin conexión, DNS,
///   TLS, conexión cortada).
/// - [NetworkTimeoutException]: caso especial de [NetworkException]; la petición
///   no respondió dentro del timeout.
/// - [SessionExpiredException]: el refresh de token falló; la sesión ya no es
///   recuperable y el usuario debe volver a autenticarse.
library;

/// No se pudo establecer/completar la comunicación con el servidor.
class NetworkException implements Exception {
  final String message;
  final Object? cause;

  const NetworkException([
    this.message = 'No se pudo conectar con el servidor. Verifica tu conexión.',
    this.cause,
  ]);

  @override
  String toString() => message;
}

/// La petición superó el tiempo máximo de espera.
class NetworkTimeoutException extends NetworkException {
  const NetworkTimeoutException([
    super.message =
        'La solicitud tardó demasiado en responder. Inténtalo de nuevo.',
    super.cause,
  ]);
}

/// La sesión expiró y no pudo renovarse (refresh token inválido o ausente).
/// La UI debe redirigir al login.
class SessionExpiredException implements Exception {
  final String message;

  const SessionExpiredException([
    this.message = 'Tu sesión expiró. Vuelve a iniciar sesión.',
  ]);

  @override
  String toString() => message;
}
