import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/entities/user.dart';

extension PermissionHelper on BuildContext {
  User? get currentUser {
    final state = read<AuthBloc>().state;
    return state is AuthAuthenticated ? state.user : null;
  }

  /// True if the user has write access ("completo") for this key.
  bool canWrite(String key) => currentUser?.canWrite(key) ?? false;
}
