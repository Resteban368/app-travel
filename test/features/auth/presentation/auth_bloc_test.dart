import 'package:agente_viajes/features/auth/domain/entities/user.dart';
import 'package:agente_viajes/features/auth/domain/repositories/auth_repository.dart';
import 'package:agente_viajes/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repo;

  const user = User(id: '1', username: 'ana', name: 'Ana', role: 'admin');

  setUp(() => repo = MockAuthRepository());

  group('AuthBloc', () {
    test('estado inicial es AuthInitial', () {
      expect(AuthBloc(authRepository: repo).state, isA<AuthInitial>());
    });

    blocTest<AuthBloc, AuthState>(
      'LoginRequested exitoso emite [AuthLoading, AuthAuthenticated]',
      build: () {
        when(() => repo.login(any(), any())).thenAnswer((_) async => user);
        return AuthBloc(authRepository: repo);
      },
      act: (b) => b.add(const LoginRequested(username: 'ana', password: 'x')),
      expect: () => [isA<AuthLoading>(), const AuthAuthenticated(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'LoginRequested fallido emite [AuthLoading, AuthError] sin el prefijo Exception',
      build: () {
        when(() => repo.login(any(), any()))
            .thenThrow(Exception('Credenciales inválidas'));
        return AuthBloc(authRepository: repo);
      },
      act: (b) => b.add(const LoginRequested(username: 'ana', password: 'x')),
      expect: () => [isA<AuthLoading>(), const AuthError('Credenciales inválidas')],
    );

    blocTest<AuthBloc, AuthState>(
      'AppStarted con sesión válida restaura y emite AuthAuthenticated',
      build: () {
        when(() => repo.restoreSession()).thenAnswer((_) async => user);
        return AuthBloc(authRepository: repo);
      },
      act: (b) => b.add(const AppStarted()),
      expect: () => [isA<AuthLoading>(), const AuthAuthenticated(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'AppStarted sin sesión emite [AuthLoading, AuthInitial]',
      build: () {
        when(() => repo.restoreSession()).thenAnswer((_) async => null);
        return AuthBloc(authRepository: repo);
      },
      act: (b) => b.add(const AppStarted()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
    );

    blocTest<AuthBloc, AuthState>(
      'AppStarted con excepción cae a AuthInitial (no propaga el error)',
      build: () {
        when(() => repo.restoreSession()).thenThrow(Exception('network'));
        return AuthBloc(authRepository: repo);
      },
      act: (b) => b.add(const AppStarted()),
      expect: () => [isA<AuthLoading>(), isA<AuthInitial>()],
    );

    blocTest<AuthBloc, AuthState>(
      'LogoutRequested cierra sesión y emite AuthInitial',
      build: () {
        when(() => repo.logout()).thenAnswer((_) async {});
        return AuthBloc(authRepository: repo);
      },
      act: (b) => b.add(const LogoutRequested()),
      expect: () => [isA<AuthInitial>()],
      verify: (_) => verify(() => repo.logout()).called(1),
    );
  });
}
