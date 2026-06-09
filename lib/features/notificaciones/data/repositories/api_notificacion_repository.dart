import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import 'package:agente_viajes/core/network/api_exception.dart';
import '../../domain/entities/notificacion.dart';
import '../../domain/repositories/notificacion_repository.dart';

class ApiNotificacionRepository implements NotificacionRepository {
  final http.Client client;

  ApiNotificacionRepository({required this.client});

  static String get _base => '${ApiConstants.kBaseUrl}/v1/notificaciones';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<NotificacionListado> getNotificaciones({
    bool soloNoLeidas = false,
    int limite = 30,
    int pagina = 1,
  }) async {
    final params = <String, String>{
      'limite': limite.toString(),
      'pagina': pagina.toString(),
      if (soloNoLeidas) 'solo_no_leidas': 'true',
    };
    final uri = Uri.parse(_base).replace(queryParameters: params);
    final response = await client.get(uri, headers: _headers);
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (json['data'] as List? ?? [])
        .map((e) => Notificacion.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificacionListado(
      items: items,
      total: json['total'] as int? ?? items.length,
      totalNoLeidas: json['total_no_leidas'] as int? ?? 0,
      pagina: json['pagina'] as int? ?? pagina,
      limite: json['limite'] as int? ?? limite,
      totalPaginas: json['totalPaginas'] as int? ?? 1,
    );
  }

  @override
  Future<int> getCountNoLeidas() async {
    final response = await client.get(
      Uri.parse('$_base/no-leidas/count'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['count'] as int? ?? 0;
  }

  @override
  Future<void> marcarLeida(int id) async {
    final response = await client.patch(
      Uri.parse('$_base/$id/leer'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
  }

  @override
  Future<int> marcarTodasLeidas() async {
    final response = await client.patch(
      Uri.parse('$_base/leer-todas'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw ApiException.fromResponse(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['actualizadas'] as int? ?? 0;
  }

  @override
  Future<Notificacion> crearNotificacion({
    required String titulo,
    required String mensaje,
    required String tipo,
    int? usuarioId,
  }) async {
    final body = jsonEncode({
      'titulo': titulo,
      'mensaje': mensaje,
      'tipo': tipo,
      if (usuarioId != null) 'usuario_id': usuarioId,
    });
    final response = await client.post(
      Uri.parse(_base),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
    return Notificacion.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> eliminarNotificacion(int id) async {
    final response = await client.delete(
      Uri.parse('$_base/$id'),
      headers: _headers,
    );
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw ApiException.fromResponse(response);
    }
  }
}
