import 'package:agente_viajes/features/clientes/domain/entities/cliente.dart';
import 'package:agente_viajes/features/clientes/domain/repositories/cliente_repository.dart';
import 'package:agente_viajes/features/clientes/presentation/bloc/cliente_bloc.dart';
import 'package:agente_viajes/features/clientes/presentation/bloc/cliente_event.dart';
import 'package:agente_viajes/features/clientes/presentation/bloc/cliente_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockClienteRepository extends Mock implements ClienteRepository {}

Cliente _cliente(int id) => Cliente(
      id: id,
      nombre: 'Cliente $id',
      correo: 'c$id@test.com',
      telefono: '300',
      tipoDocumento: 'CC',
      documento: '$id',
    );

List<Cliente> _page(int from, int count) =>
    List.generate(count, (i) => _cliente(from + i));

void main() {
  late MockClienteRepository repo;

  setUp(() => repo = MockClienteRepository());

  group('ClienteBloc — paginación', () {
    blocTest<ClienteBloc, ClienteState>(
      'página 1 emite [Loading, Loaded]; hasReachedMax=true si llega menos que el limit',
      build: () {
        when(() => repo.getClientes(
              search: any(named: 'search'),
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => _page(1, 5));
        return ClienteBloc(repository: repo);
      },
      act: (b) => b.add(const LoadClientes(page: 1, limit: 20)),
      expect: () => [
        isA<ClienteLoading>(),
        isA<ClienteLoaded>()
            .having((s) => s.clientes.length, 'clientes', 5)
            .having((s) => s.page, 'page', 1)
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
    );

    blocTest<ClienteBloc, ClienteState>(
      'página 1 completa (== limit) deja hasReachedMax=false',
      build: () {
        when(() => repo.getClientes(
              search: any(named: 'search'),
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => _page(1, 20));
        return ClienteBloc(repository: repo);
      },
      act: (b) => b.add(const LoadClientes(page: 1, limit: 20)),
      expect: () => [
        isA<ClienteLoading>(),
        isA<ClienteLoaded>()
            .having((s) => s.clientes.length, 'clientes', 20)
            .having((s) => s.hasReachedMax, 'hasReachedMax', false),
      ],
    );

    blocTest<ClienteBloc, ClienteState>(
      'LoadMore (página 2) APENDE a la lista sin re-emitir Loading',
      build: () {
        when(() => repo.getClientes(
              search: any(named: 'search'),
              page: 1,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => _page(1, 20));
        when(() => repo.getClientes(
              search: any(named: 'search'),
              page: 2,
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => _page(21, 5));
        return ClienteBloc(repository: repo);
      },
      act: (b) async {
        b.add(const LoadClientes(page: 1, limit: 20));
        await Future<void>.delayed(Duration.zero);
        b.add(const LoadClientes(page: 2, limit: 20));
      },
      expect: () => [
        isA<ClienteLoading>(),
        isA<ClienteLoaded>().having((s) => s.clientes.length, 'pág 1', 20),
        isA<ClienteLoaded>()
            .having((s) => s.clientes.length, 'pág 1+2', 25)
            .having((s) => s.page, 'page', 2)
            .having((s) => s.hasReachedMax, 'hasReachedMax', true),
      ],
      verify: (_) {
        // Nunca hubo un segundo Loading para la página 2.
        verify(() => repo.getClientes(
            search: any(named: 'search'),
            page: 2,
            limit: any(named: 'limit'))).called(1);
      },
    );

    blocTest<ClienteBloc, ClienteState>(
      'error del repo emite ClienteError',
      build: () {
        when(() => repo.getClientes(
              search: any(named: 'search'),
              page: any(named: 'page'),
              limit: any(named: 'limit'),
            )).thenThrow(Exception('boom'));
        return ClienteBloc(repository: repo);
      },
      act: (b) => b.add(const LoadClientes(page: 1)),
      expect: () => [isA<ClienteLoading>(), isA<ClienteError>()],
    );
  });
}
