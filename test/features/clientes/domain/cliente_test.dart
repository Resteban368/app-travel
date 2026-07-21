import 'package:agente_viajes/features/clientes/domain/entities/cliente.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regresión de Fase 0: `copyWith` declaraba parámetros fantasma
/// (`numeroDocumento`, `notas`) y omitía `documento`, `estado` y `deletedAt`,
/// por lo que esos campos nunca podían modificarse. Ver ANALISIS_Y_PLAN_MEJORAS.md.
void main() {
  const base = Cliente(
    id: 1,
    nombre: 'Ana',
    correo: 'ana@example.com',
    telefono: '3001112233',
    tipoDocumento: 'CC',
    documento: '123',
    estado: true,
  );

  group('Cliente.copyWith', () {
    test('sin argumentos devuelve un cliente equivalente', () {
      expect(base.copyWith(), equals(base));
    });

    test('actualiza documento, estado y deletedAt', () {
      final borrado = DateTime(2026, 1, 1);
      final actualizado = base.copyWith(
        documento: '999',
        estado: false,
        deletedAt: borrado,
      );

      expect(actualizado.documento, '999');
      expect(actualizado.estado, isFalse);
      expect(actualizado.deletedAt, borrado);
      // Campos no tocados se conservan.
      expect(actualizado.nombre, 'Ana');
      expect(actualizado.id, 1);
    });

    test('conserva los campos no especificados', () {
      final actualizado = base.copyWith(nombre: 'Ana María');
      expect(actualizado.nombre, 'Ana María');
      expect(actualizado.correo, base.correo);
      expect(actualizado.documento, base.documento);
      expect(actualizado.estado, base.estado);
    });
  });

  test('la igualdad de Equatable cubre todos los campos', () {
    expect(base.copyWith(nombre: 'Otro'), isNot(equals(base)));
    expect(base.copyWith(estado: false), isNot(equals(base)));
  });
}
