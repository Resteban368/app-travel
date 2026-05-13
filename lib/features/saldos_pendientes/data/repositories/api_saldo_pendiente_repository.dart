import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/core/network/api_exception.dart';
import '../../domain/entities/saldo_pendiente.dart';
import '../../domain/repositories/saldo_pendiente_repository.dart';

export '../../domain/repositories/saldo_pendiente_repository.dart'
    show RecordatorioResult;

class ApiSaldoPendienteRepository implements SaldoPendienteRepository {
  final http.Client client;

  ApiSaldoPendienteRepository({required this.client});

  static String get _baseUrl =>
      '${ApiConstants.kBaseUrl}/v1/saldos-pendientes';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  @override
  Future<({List<TourConSaldo> tours, int totalTours, int page, int limit})>
      getSaldosPendientes({
    int page = 1,
    int limit = 5,
    String? tourId,
    String? responsable,
    String? idReserva,
    bool sinRecordatorioReciente = false,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (tourId != null && tourId.isNotEmpty) params['tour_id'] = tourId;
    if (responsable != null && responsable.isNotEmpty) {
      params['responsable'] = responsable;
    }
    if (idReserva != null && idReserva.isNotEmpty) {
      params['id_reserva'] = idReserva;
    }
    if (sinRecordatorioReciente) {
      params['sin_recordatorio_reciente'] = 'true';
    }

    final uri = Uri.parse(_baseUrl).replace(queryParameters: params);
    debugPrint('API CALL: GET $uri');
    final response = await client.get(uri, headers: _headers);
    debugPrint('API RESPONSE: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    final tours = (body['tours'] as List<dynamic>? ?? [])
        .map((j) => TourConSaldo.fromJson(j as Map<String, dynamic>))
        .toList();

    return (
      tours: tours,
      totalTours: body['total_tours'] as int? ?? 0,
      page: body['page'] as int? ?? page,
      limit: body['limit'] as int? ?? limit,
    );
  }

  @override
  Future<RecordatorioResult> enviarRecordatorio(
    int reservaId, {
    int? conversationId,
  }) async {
    final uri = Uri.parse('${ApiConstants.kBaseUrl}/v1/recordatorio-saldo');
    final bodyMap = <String, dynamic>{'reserva_id': reservaId};
    if (conversationId != null) bodyMap['conversation_id'] = conversationId;

    debugPrint('API CALL: POST $uri body=$bodyMap');
    final response = await client.post(
      uri,
      headers: _headers,
      body: json.encode(bodyMap),
    );
    debugPrint('API RESPONSE: ${response.statusCode} ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException.fromResponse(response);
    }

    final body = json.decode(response.body) as Map<String, dynamic>;
    return RecordatorioResult.fromJson(body);
  }
}
