# Teoria_Fuerza_de_venta — Fuerza de Ventas Banco Pichincha

App Flutter para oficiales de crédito (cartera, ruta, solicitudes, buró, documentos).

## Supabase

| Parámetro | Valor |
|-----------|--------|
| URL | `https://uomaqpphyouzbnestbba.supabase.co` |
| Anon / publishable key | `sb_publishable_fymmXEWgkQSdaXe-F3_8OA_QK6ZOnCe` |

**Base de datos:** ejecuta en el SQL Editor de Supabase, **en orden**:

1. `supabase/schema_and_seed.sql`
2. `supabase/02_rubrica_integracion.sql` ← roles, bloqueo de intentos y puente E2E
3. `supabase/03_usuarios_demo_docente.sql` ← roles docente (opcional si ya corriste 2)

Luego crea el bucket **documents** (público) en Storage para fotos de expediente.
## Funcionalidades

- **Originación**: cartera del día, ruta con GPS, ficha de cliente con semáforo de mora, buró (SBS + lista negra), wizard de solicitud (datos → negocio → simulador de cronograma → firma digital), expediente de documentos y **cola offline** con reintento automático.
- **Seguridad (RBAC)**: Supabase Auth (JWT), tokens en `flutter_secure_storage`, roles `asesor`/`supervisor`/`admin`, bloqueo tras **5 intentos** fallidos.
- **Integración E2E**: al aprobar una solicitud, el crédito se refleja automáticamente en la app cliente (`banco_pichincha`) vía `sync_outbox`.

## Roles / Login

| Email | Rol | Contraseña | Uso |
|-------|-----|------------|-----|
| `demo@pichincha.com` | **asesor** | `pichincha123` | Demo rápida (botón en login). Aceptar y enviar a comité. |
| `asesor@pichincha.com` | **asesor** | `Docente2025!` | Login real Supabase Auth (botón en pantalla de login) |
| `supervisor@pichincha.com` | supervisor | `Docente2025!` | Aprueba en **web** (`web_fuerza_de_venta`) |

Ver credenciales completas (cliente Caso 1, SQL, flujo): repo web → `CREDENCIALES_DEMO.md`.

## Documentación rúbrica

- `docs/RUBRICA_AUTOEVALUACION.md` — evidencias por criterio
- `docs/ARQUITECTURA.md` — capas, tablas y diagrama E2E

## Ejecutar la app

Requisitos: Flutter SDK 3.11+, Android Studio o VS Code.

```bash
flutter pub get
flutter run
```

## Repositorio

https://github.com/Ivan-1926/Teoria_Fuerza_de_venta.git
