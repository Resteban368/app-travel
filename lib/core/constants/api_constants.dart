/// Centralised API configuration.
/// Change [kBaseUrl] to point to a different environment.
class ApiConstants {
  ApiConstants._();

  // static const String kBaseUrl =
  //     'https://unvolubly-undefiled-kristian.ngrok-free.dev';
  // Para Web/iOS Simulator: http://localhost:3001
  // Para Android Emulator: http://[IP_ADDRESS]
  static const String kBaseUrl = 'http://localhost:3001';
  //vamos a usar el emulador de android
  // static const String kBaseUrl = 'http://10.0.2.2:3001';
}
