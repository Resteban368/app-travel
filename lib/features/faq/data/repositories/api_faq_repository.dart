import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/faq.dart';
import '../../domain/repositories/faq_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

class ApiFaqRepository implements FaqRepository {
  final http.Client client;

  ApiFaqRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/faqs';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<Faq>> getFaqs() async {
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _fromJson(item)).toList();
    }
    throw Exception('Failed to load FAQs: ${response.statusCode}');
  }

  @override
  Future<void> createFaq(Faq faq) async {
    final body = json.encode(_toJson(faq));
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create FAQ: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateFaq(Faq faq) async {
    final body = json.encode(_toJson(faq));
    final response = await client.patch(
      Uri.parse('$_baseUrl/${faq.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update FAQ: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteFaq(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete FAQ: ${response.statusCode}');
    }
  }

  Faq _fromJson(Map<String, dynamic> json) {
    return Faq(
      id: json['id_faq'] as int,
      question: json['pregunta'] ?? '',
      answer: json['respuesta'] ?? '',
      isActive: json['activo'] ?? true,
      createdAt: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
    );
  }

  Map<String, dynamic> _toJson(Faq faq) {
    return {
      'pregunta': faq.question,
      'respuesta': faq.answer,
      'activo': faq.isActive,
    };
  }
}
