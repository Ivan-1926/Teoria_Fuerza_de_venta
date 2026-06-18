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

Luego crea el bucket **documents** (público) en Storage para fotos de expediente.

## Funcionalidades

- **Originación**: cartera del día, ruta con GPS, ficha de cliente con semáforo de mora, buró (SBS + lista negra), wizard de solicitud (datos → negocio → simulador de cronograma → firma digital), expediente de documentos y **cola offline** con reintento automático.
- **Seguridad (RBAC)**: Supabase Auth (JWT), tokens en `flutter_secure_storage`, roles `asesor`/`supervisor`/`admin`, bloqueo tras **5 intentos** fallidos.
- **Integración E2E**: al aprobar una solicitud, el crédito se refleja automáticamente en la app cliente (`banco_pichincha`) vía `sync_outbox`.

## Roles / Login

| Email | Rol | Contraseña (demo) |
|-------|-----|-------------------|
| `demo@pichincha.com` | supervisor | `pichincha123` (respaldo offline) |
| `asesor@pichincha.com` | asesor | (crear en Supabase Auth) |

## Documentación rúbrica

- `docs/RUBRICA_AUTOEVALUACION.md` — evidencias por criterio
- `docs/ARQUITECTURA.md` — capas, tablas y diagrama E2E

## Ejecutar la app

```bash
flutter pub get
flutter run
```

## Repositorio

https://github.com/Ivan-1926/Teoria_Fuerza_de_venta.git
