/// Centralised API configuration.
/// Change [kBaseUrl] to point to a different environment.
class ApiConstants {
  ApiConstants._();

  //todo produccion
  // static const String kBaseUrl = 'https://api-travel.agenteviajes.com';

  // todo para el navegador
  static const String kBaseUrl = 'http://localhost:3001';
  // todo vamos a usar el emulador de android
  // static const String kBaseUrl = 'http://10.0.2.2:3001';

  /// URL pública de propuesta para compartir al cliente.
  /// Formato final: $kBaseUrl/cotizacion/{token}
  static String propuestaUrl(String token) => '$kBaseUrl/cotizacion/$token';
}
