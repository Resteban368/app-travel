import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:agente_viajes/core/constants/api_constants.dart';
import '../../domain/entities/catalogue.dart';
import '../../domain/repositories/catalogue_repository.dart';

class ApiCatalogueRepository implements CatalogueRepository {
  final http.Client client;

  ApiCatalogueRepository({required this.client});

  static String get _baseUrl => '${ApiConstants.kBaseUrl}/v1/catalogos';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept': 'application/json',
  };

  @override
  Future<List<Catalogue>> getCatalogues() async {
    final response = await client.get(Uri.parse(_baseUrl), headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => _fromJson(item)).toList();
    }
    throw Exception('Failed to load catalogues: ${response.statusCode}');
  }

  @override
  Future<void> createCatalogue(Catalogue catalogue) async {
    final body = json.encode(_toJson(catalogue));
    final response = await client.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create catalogue: ${response.statusCode}');
    }
  }

  @override
  Future<void> updateCatalogue(Catalogue catalogue) async {
    final body = json.encode(_toJson(catalogue));
    final response = await client.patch(
      Uri.parse('$_baseUrl/${catalogue.idCatalogue}'),
      headers: _headers,
      body: body,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update catalogue: ${response.statusCode}');
    }
  }

  @override
  Future<void> deleteCatalogue(int id) async {
    final response = await client.delete(
      Uri.parse('$_baseUrl/$id'),
      headers: _headers,
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete catalogue: ${response.statusCode}');
    }
  }

  Catalogue _fromJson(Map<String, dynamic> json) {
    return Catalogue(
      idCatalogue: json['id_catalogo'] as int,
      idSede: json['id_sede'] as int,
      nombreCatalogue: json['nombre_catalogo'] ?? '',
      urlArchivo: json['url_archivo'] ?? '',
      activo: json['activo'] ?? true,
      fechaCreacion: DateTime.parse(json['fecha_creacion']),
    );
  }

  Map<String, dynamic> _toJson(Catalogue catalogue) {
    return {
      'id_sede': catalogue.idSede,
      'nombre_catalogo': catalogue.nombreCatalogue,
      'url_archivo': catalogue.urlArchivo,
      'activo': catalogue.activo,
    };
  }
}
