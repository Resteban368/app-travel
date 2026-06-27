import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _key = 'app_theme_mode';

  final FlutterSecureStorage _storage;

  ThemeCubit(this._storage) : super(ThemeMode.light);

  Future<void> loadSavedTheme() async {
    final saved = await _storage.read(key: _key);
    emit(saved == 'dark' ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> setDark() async {
    await _storage.write(key: _key, value: 'dark');
    emit(ThemeMode.dark);
  }

  Future<void> setLight() async {
    await _storage.write(key: _key, value: 'light');
    emit(ThemeMode.light);
  }

  Future<void> toggle() async {
    state == ThemeMode.dark ? await setLight() : await setDark();
  }
}
