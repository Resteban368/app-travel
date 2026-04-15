# 💎 Guía de Replicación — Premium UI System

Todo el sistema visual premium ya está centralizado en un solo archivo.
Sigue estos pasos para aplicarlo en **cualquier módulo nuevo o existente**.

---

## Paso 0 — Un solo import

```dart
import 'package:agente_viajes/core/widgets/premium_form_widgets.dart';
```

Con esa línea tienes acceso a todos los widgets del sistema.

---

## Paso 1 — Estructura base del Scaffold

Reemplaza el body de cualquier `Scaffold` existente con esta estructura:

```dart
Scaffold(
  backgroundColor: D.bg,
  body: Stack(
    children: [
      // ① Fondo premium con orbes y cuadrícula
      const PremiumBackground(),

      // ② Scroll con encabezado colapsable
      CustomScrollView(
        slivers: [
          PremiumSliverAppBar(title: 'Mi Módulo'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ③ Tus secciones aquí (ver Paso 2)
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  ),
)
```

---

## Paso 2 — Tarjetas de sección con campos

Cada grupo lógico de campos (datos básicos, dirección, contacto…) va dentro de un `PremiumSectionCard`:

```dart
PremiumSectionCard(
  title: 'DATOS DEL CLIENTE',
  icon: Icons.person_rounded,
  children: [
    PremiumTextField(
      controller: _nameCtrl,
      label: 'Nombre Completo *',
      icon: Icons.badge_rounded,
    ),
    const SizedBox(height: 20),
    PremiumTextField(
      controller: _emailCtrl,
      label: 'Correo Electrónico *',
      icon: Icons.email_rounded,
    ),
    const SizedBox(height: 20),
    PremiumTextField(
      controller: _phoneCtrl,
      label: 'Teléfono',
      icon: Icons.phone_rounded,
      isNumeric: true,
    ),
  ],
),
```

Separa secciones con `const SizedBox(height: 24)`.

---

## Paso 3 — Botón de guardado

Al final del formulario, antes del `SizedBox(height: 100)` final:

```dart
BlocBuilder<MiBloc, MiState>(
  builder: (context, state) {
    return PremiumActionButton(
      label: 'GUARDAR',
      icon: Icons.save_rounded,
      isLoading: state is MiStateSaving,
      onTap: () => _save(context),
    );
  },
),
```

---

## Paso 4 — Switches de estado (toggle)

Para activar/desactivar flags del modelo. Se usan dentro de un `Row`:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: D.surfaceHigh.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          PremiumStatusSwitch(
            label: 'Activo',
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: D.emerald,
          ),
          const SizedBox(width: 32),
          PremiumStatusSwitch(
            label: 'Destacado',
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            activeColor: D.gold,
          ),
        ],
      ),
    ),
  ),
)
```

---

## Paso 5 — Listas dinámicas con chips

Para inclusiones, permisos, etiquetas, etc.:

```dart
Wrap(
  spacing: 8,
  runSpacing: 8,
  children: _items.asMap().entries.map((e) =>
    PremiumChip(
      label: e.value,
      color: D.emerald,       // D.rose para exclusiones, D.skyBlue para info
      onRemove: () => setState(() => _items.removeAt(e.key)),
    ),
  ).toList(),
)
```

---

## Paso 6 — Placeholder de lista vacía

```dart
const PremiumEmptyIndicator(
  msg: 'Aún no hay elementos registrados.',
  icon: Icons.inbox_rounded,
)
```

---

## Referencia rápida de widgets

| Widget | Para qué usarlo |
|---|---|
| `PremiumBackground` | Fondo de pantalla con orbes y desenfoque |
| `PremiumSliverAppBar` | Encabezado colapsable de pantalla |
| `PremiumSectionCard` | Agrupa campos bajo una sección visual |
| `PremiumSectionHeader` | Solo el header (si necesitas control manual) |
| `PremiumTextField` | Cualquier campo de texto del formulario |
| `PremiumActionButton` | Botón principal de submit con gradiente |
| `PremiumStatusSwitch` | Toggle on/off para flags del modelo |
| `PremiumChip` | Tag/etiqueta eliminable en listas dinámicas |
| `PremiumEmptyIndicator` | Vacío de lista con icono y mensaje |
| `DotGridPainter` | Pintor decorativo de cuadrícula (uso en CustomPaint) |

---

> [!IMPORTANT]
> Recuerda agregar `import 'dart:ui';` al archivo si usas algún `BackdropFilter` manual (el `PremiumBackground` ya lo incluye internamente).

> [!TIP]
> Para **módulos de detalle** (solo lectura, sin formulario), pasa `readOnly: true` en cada `PremiumTextField`. El aspecto visual es idéntico pero sin interacción.
