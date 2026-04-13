import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/repositories/whatsapp_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

class ApiWhatsAppRepository implements WhatsAppRepository {
  final http.Client client;

  ApiWhatsAppRepository({required this.client});

  @override
  Future<void> sendMessage({required String to, required String body}) async {
    final url = '${ApiConstants.kBaseUrl}/v1/whatsapp/send';

    try {
      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'to': to,
          'body': body,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Error sending WhatsApp: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('WhatsApp API Error: $e');
      rethrow;
    }
  }
}
