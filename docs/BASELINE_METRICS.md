# Métricas base — línea de referencia (Fase 0)

> Capturado el 2026-07-21 al completar la Fase 0 del plan ([ANALISIS_Y_PLAN_MEJORAS.md](../ANALISIS_Y_PLAN_MEJORAS.md)).
> Sirven como punto de comparación para medir el impacto de las Fases 4 (performance) y 5 (WASM/escalabilidad).

## Entorno

| Herramienta | Versión |
|-------------|---------|
| Flutter | 3.38.8 (stable) |
| Dart | 3.10.7 (stable) |
| Renderer web | CanvasKit (default) |
| Comando de build | `flutter build web --release` |

## Tamaño del bundle web (release)

| Artefacto | Tamaño |
|-----------|--------|
| `build/web` (total) | 36 MB |
| `main.dart.js` | 5.94 MB (sin comprimir) |
| `canvaskit/` | 26 MB |
| `assets/` | 3.2 MB |

**Notas:**
- `canvaskit/` domina el peso; incluye variantes que el navegador no descarga todas (solo la que aplica). El tamaño *transferido* real es mucho menor que 26 MB.
- `main.dart.js` a 5.94 MB sin comprimir es el número a vigilar; con gzip/brotli el navegador recibe ~1.3–1.8 MB. Objetivo Fase 4: reducirlo con `const` agresivo, tree-shaking de features y quitando fuentes/PDF.js remotos.
- Tiempo de build release en frío: ~29 s (máquina de desarrollo).

## Calidad estática

| Métrica | Antes de Fase 0 | Después de Fase 0 |
|---------|-----------------|-------------------|
| `flutter analyze` issues | 263 | **0** |
| `flutter analyze --fatal-infos` | falla | **pasa** |
| Tests (`flutter test`) | 0 reales (1 comentado) | **5 pasando** |
| Archivos sueltos en root | `refactor.dart`, `replace_ip.dart`, `sd.md` | movidos a `tool/` / eliminados |

## Cómo re-medir

```bash
flutter build web --release
du -sh build/web build/web/canvaskit build/web/assets
ls -la build/web/main.dart.js

flutter analyze
flutter test
```

## Pendientes de perfilado (capturar antes de Fase 4)

Estas métricas requieren la app corriendo y se tomarán al iniciar la Fase 4, cuando haya cambios de performance que medir:

- [ ] DevTools timeline del **dashboard** (frames > 16 ms al cargar).
- [ ] DevTools timeline de la **lista de reservas** (rebuild counts, jank al hacer scroll).
- [ ] "Track widget rebuilds" en el **formulario de reservas** al teclear en un campo (baseline del problema de god-widget).
- [ ] Lighthouse (Performance / TTI) sobre el build release servido.
- [ ] Tiempo de arranque en frío (First Contentful Paint).
