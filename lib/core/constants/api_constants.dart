/// Centralised API configuration.
/// Change [kBaseUrl] to point to a different environment.
class ApiConstants {
  ApiConstants._();

  // todo produccion
  // static const String kBaseUrl = 'https://api-travel.agenteviajes.com';

  // todo para el navegador
  //
  // static const String kBaseUrl = 'http://localhost:3001';
  //todo api de test
  static const String kBaseUrl = 'https://api-travel-tours.vercel.app';
  // todo vamos a usar el emulador de android
  // static const String kBaseUrl = 'http://10.0.2.2:3001';

  /// Dominio público para los links que se comparten con el cliente.
  /// Apunta a la misma API de Vercel; el agente sigue usando [kBaseUrl].
  static const String kCotizacionesUrl =
      'https://cotizaciones.travelclubagencia.com';

  /// URL pública de propuesta para compartir al cliente.
  /// Formato final: $kCotizacionesUrl/cotizacion/{token}
  static String propuestaUrl(String token) =>
      '$kCotizacionesUrl/cotizacion/$token';

  /// Link personal del asesor para recibir cotizaciones de clientes.
  /// Formato final: $kCotizacionesUrl/cotizacion.html?asesor={id}
  static String cotizacionAsesorUrl(String asesorId) =>
      '$kCotizacionesUrl/cotizacion.html?asesor=$asesorId';
}
