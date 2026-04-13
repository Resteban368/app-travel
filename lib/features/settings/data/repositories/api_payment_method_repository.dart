import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/payment_method_repository.dart';
import 'package:agente_viajes/core/constants/api_constants.dart';

class ApiPaymentMethodRepository implements PaymentMethodRepository {
  final http.Client client;

  ApiPaymentMethodRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/metodos-pago';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _fromJson(item)).toList();
    }
    throw Exception('Failed to load payment methods: ${response.statusCode}');
  }

  @override
  Future<void> createPaymentMethod(PaymentMethod method) async {
    final body = json.encode(_toJson(method));
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Failed to create payment method: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> updatePaymentMethod(PaymentMethod method) async {
    final body = json.encode(_toJson(method));
    final response = await client.patch(
      Uri.parse('$_baseUrl/${method.id}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update payment method: ${response.statusCode}',
      );
    }
  }

  @override
  Future<void> deletePaymentMethod(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete payment method: ${response.statusCode}',
      );
    }
  }

  PaymentMethod _fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id_metodo_pago'] as int,
      name: json['nombre_metodo'] ?? '',
      paymentType: json['tipo_pago'] ?? '',
      accountType: json['tipo_cuenta'] ?? '',
      accountNumber: json['numero_metodo'] ?? '',
      accountHolder: json['titular_cuenta'] ?? '',
      isActive: json['activo'] ?? true,
      createdAt: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : null,
    );
  }

  Map<String, dynamic> _toJson(PaymentMethod method) {
    return {
      'nombre_metodo': method.name,
      'tipo_pago': method.paymentType,
      'tipo_cuenta': method.accountType,
      'numero_metodo': method.accountNumber,
      'titular_cuenta': method.accountHolder,
      'activo': method.isActive,
    };
  }
}
