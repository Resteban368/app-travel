import 'dart:async';
import 'dart:convert';

import 'package:agente_viajes/core/network/auth_client.dart';
import 'package:agente_viajes/core/network/network_exceptions.dart';
import 'package:agente_viajes/core/network/session_expired_notifier.dart';
import 'package:agente_viajes/core/network/token_cache.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Storage en memoria mínimo, más simple que stubear cada write/delete.
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _data;
  FakeSecureStorage([Map<String, String>? initial]) : _data = {...?initial};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  late FakeSecureStorage storage;
  late SessionExpiredNotifier notifier;
  late TokenCache cache;

  setUp(() {
    storage = FakeSecureStorage({
      'access_token': 'old-access',
      'refresh_token': 'old-refresh',
    });
    notifier = SessionExpiredNotifier();
    cache = TokenCache();
  });

  AuthClient buildClient(MockClient inner) =>
      AuthClient(inner, storage, notifier, cache);

  group('Inyección de token', () {
    test('añade Authorization: Bearer <access_token> en cada request', () async {
      String? seenAuth;
      final inner = MockClient((req) async {
        seenAuth = req.headers['Authorization'];
        return http.Response('{}', 200);
      });

      await buildClient(inner).get(Uri.parse('https://api.test/x'));

      expect(seenAuth, 'Bearer old-access');
    });

    test('cachea el token y no relee storage en la 2ª request', () async {
      final inner = MockClient((req) async => http.Response('{}', 200));
      final client = buildClient(inner);

      await client.get(Uri.parse('https://api.test/a'));
      // Cambiamos el storage directamente: si releyera, usaría el nuevo valor.
      await storage.write(key: 'access_token', value: 'changed-in-storage');
      String? seenAuth;
      final inner2 = MockClient((req) async {
        seenAuth = req.headers['Authorization'];
        return http.Response('{}', 200);
      });
      // Mismo caché, distinto inner para inspeccionar.
      await AuthClient(inner2, storage, notifier, cache)
          .get(Uri.parse('https://api.test/b'));

      expect(seenAuth, 'Bearer old-access', reason: 'debe venir del caché');
    });
  });

  group('Retry en 500', () {
    test('GET con 500 reintenta una vez', () async {
      var calls = 0;
      final inner = MockClient((req) async {
        calls++;
        return http.Response('err', 500);
      });

      await buildClient(inner).get(Uri.parse('https://api.test/x'));

      expect(calls, 2, reason: 'GET idempotente: 1 intento + 1 retry');
    });

    test('POST con 500 NO reintenta (evita duplicar pagos/reservas)', () async {
      var calls = 0;
      final inner = MockClient((req) async {
        calls++;
        return http.Response('err', 500);
      });

      await buildClient(inner).post(
        Uri.parse('https://api.test/pagos'),
        body: jsonEncode({'monto': 100}),
        headers: {'Content-Type': 'application/json'},
      );

      expect(calls, 1, reason: 'POST no idempotente: nunca se reintenta');
    });
  });

  group('Refresh en 401', () {
    test('401 → refresh → reenvía con el token nuevo', () async {
      var refreshCalls = 0;
      final inner = MockClient((req) async {
        if (req.url.path.endsWith('/refresh')) {
          refreshCalls++;
          return http.Response(
            jsonEncode({'access_token': 'new-access', 'refresh_token': 'new-r'}),
            200,
          );
        }
        // El request original: 401 con el token viejo, 200 con el nuevo.
        if (req.headers['Authorization'] == 'Bearer new-access') {
          return http.Response('{"ok":true}', 200);
        }
        return http.Response('unauthorized', 401);
      });

      final resp =
          await buildClient(inner).get(Uri.parse('https://api.test/x'));

      expect(refreshCalls, 1);
      expect(resp.statusCode, 200);
      expect(cache.accessToken, 'new-access');
      expect(await storage.read(key: 'access_token'), 'new-access');
      expect(await storage.read(key: 'refresh_token'), 'new-r');
    });

    test('refresh fallido limpia sesión y notifica SessionExpiredNotifier',
        () async {
      final expired = Completer<void>();
      final sub = notifier.stream.listen((_) => expired.complete());

      final inner = MockClient((req) async {
        if (req.url.path.endsWith('/refresh')) {
          return http.Response('nope', 401);
        }
        return http.Response('unauthorized', 401);
      });

      await buildClient(inner).get(Uri.parse('https://api.test/x'));

      await expired.future.timeout(const Duration(seconds: 1));
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
      expect(cache.isLoaded, isTrue);
      expect(cache.accessToken, isNull);
      await sub.cancel();
    });

    test('3 peticiones concurrentes con 401 → una sola llamada a /refresh',
        () async {
      var refreshCalls = 0;
      final inner = MockClient((req) async {
        if (req.url.path.endsWith('/refresh')) {
          refreshCalls++;
          // Retenemos el refresh para que los 3 requests coincidan en el gate.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return http.Response(
            jsonEncode({'access_token': 'new-access'}),
            200,
          );
        }
        if (req.headers['Authorization'] == 'Bearer new-access') {
          return http.Response('{"ok":true}', 200);
        }
        return http.Response('unauthorized', 401);
      });

      final client = buildClient(inner);
      final responses = await Future.wait([
        client.get(Uri.parse('https://api.test/a')),
        client.get(Uri.parse('https://api.test/b')),
        client.get(Uri.parse('https://api.test/c')),
      ]);

      expect(refreshCalls, 1, reason: 'refresh serializado');
      expect(responses.every((r) => r.statusCode == 200), isTrue);
    });
  });

  group('Multipart', () {
    test('upload con 401 se reintenta tras el refresh con el body intacto',
        () async {
      final receivedBodies = <String>[];
      final inner = MockClient((req) async {
        if (req.url.path.endsWith('/refresh')) {
          return http.Response(
            jsonEncode({'access_token': 'new-access'}),
            200,
          );
        }
        receivedBodies.add(req.body);
        if (req.headers['Authorization'] == 'Bearer new-access') {
          return http.Response('{"ok":true}', 200);
        }
        return http.Response('unauthorized', 401);
      });

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.test/upload'),
      )..fields['nombre'] = 'foto.png';

      final streamed = await buildClient(inner).send(request);
      final resp = await http.Response.fromStream(streamed);

      expect(resp.statusCode, 200);
      expect(receivedBodies.length, 2, reason: '1 intento 401 + 1 retry');
      // El body multipart (con el field) se reenvió intacto en ambos intentos.
      expect(receivedBodies[0], contains('nombre'));
      expect(receivedBodies[1], contains('nombre'));
    });
  });

  group('Timeout', () {
    test('lanza NetworkTimeoutException si el servidor no responde a tiempo',
        () async {
      final inner = MockClient((req) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('{}', 200);
      });
      final client = AuthClient(
        inner,
        storage,
        notifier,
        cache,
        timeout: const Duration(milliseconds: 20),
      );

      expect(
        () => client.get(Uri.parse('https://api.test/slow')),
        throwsA(isA<NetworkTimeoutException>()),
      );
    });
  });
}
