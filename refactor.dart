import 'dart:io';

void main() {
  final files = [
    'lib/features/tour/data/repositories/api_tour_repository.dart',
    'lib/features/settings/data/repositories/api_sede_repository.dart',
    'lib/features/settings/data/repositories/api_payment_method_repository.dart',
    'lib/features/catalogue/data/repositories/api_catalogue_repository.dart',
    'lib/features/faq/data/repositories/api_faq_repository.dart',
    'lib/features/service/data/repositories/api_service_repository.dart',
    'lib/features/politica_reserva/data/repositories/api_politica_reserva_repository.dart',
    'lib/features/info_empresa/data/repositories/api_info_empresa_repository.dart',
    'lib/features/pagos_realizados/data/repositories/api_pago_realizado_repository.dart',
    'lib/features/whatsapp/data/repositories/api_whatsapp_repository.dart'
  ];

  for (var path in files) {
    if (!File(path).existsSync()) {
      print('Not found: $path');
      continue;
    }
    var content = File(path).readAsStringSync();
    
    if (content.contains('final http.Client client;')) {
       print('Already injected: $path');
       continue;
    }

    String newContent = content.replaceFirstMapped(
      RegExp(r'(class\s+(Api[A-Za-z]+Repository)\s+implements\s+[A-Za-z]+Repository)\s*\{'),
      (m) => '${m.group(1)} {\n  final http.Client client;\n\n  ${m.group(2)}({required this.client});\n'
    );
    
    newContent = newContent.replaceAll('http.get(', 'client.get(');
    newContent = newContent.replaceAll('http.post(', 'client.post(');
    newContent = newContent.replaceAll('http.put(', 'client.put(');
    newContent = newContent.replaceAll('http.delete(', 'client.delete(');
    newContent = newContent.replaceAll('http.patch(', 'client.patch(');

    File(path).writeAsStringSync(newContent);
    print('Updated $path');
  }
}
