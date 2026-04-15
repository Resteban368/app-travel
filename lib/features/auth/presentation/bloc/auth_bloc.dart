import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

// ─── Events ──────────────────────────────────────────────

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginRequested extends AuthEvent {
  final String username;
  final String password;
  const LoginRequested({required this.username, required this.password});
  @override
  List<Object?> get props => [username, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class RefreshProfile extends AuthEvent {
  const RefreshProfile();
}

class ChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
  });
  @override
  List<Object?> get props => [currentPassword, newPassword];
}

// ─── States ──────────────────────────────────────────────

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class ChangePasswordLoading extends AuthState {
  final User user;
  const ChangePasswordLoading(this.user);
  @override
  List<Object?> get props => [user];
}

class ChangePasswordFailed extends AuthState {
  final User user;
  final String message;
  const ChangePasswordFailed(this.user, this.message);
  @override
  List<Object?> get props => [user, message];
}

// ─── BLoC ────────────────────────────────────────────────

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<RefreshProfile>(_onRefreshProfile);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final user = await _authRepository.restoreSession();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthInitial());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _authRepository.login(event.username, event.password);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRefreshProfile(
    RefreshProfile event,
    Emitter<AuthState> emit,
  ) async {
    final user = await _authRepository.fetchMe();
    if (user != null) {
      emit(AuthAuthenticated(user));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(AuthInitial());
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    User? user;
    if (currentState is AuthAuthenticated) {
      user = currentState.user;
    } else if (currentState is ChangePasswordFailed) {
      user = currentState.user;
    }
    if (user == null) return;

    emit(ChangePasswordLoading(user));
    try {
      await _authRepository.changePassword(event.currentPassword, event.newPassword);
      await _authRepository.logout();
      emit(AuthInitial());
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('wrong_password')) {
        emit(ChangePasswordFailed(user, 'La contraseña actual es incorrecta'));
      } else if (msg.contains('token_expired')) {
        await _authRepository.logout();
        emit(AuthInitial());
      } else {
        emit(ChangePasswordFailed(user, 'Error al cambiar la contraseña. Inténtalo de nuevo.'));
      }
    }
  }
}
