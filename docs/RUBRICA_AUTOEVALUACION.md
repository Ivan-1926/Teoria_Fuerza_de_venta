# Autoevaluación rúbrica — App Fuerza de Ventas (Banco Pichincha)

Proyecto: `APP_Fuerza _De_Venta` | Supabase: `uomaqpphyouzbnestbba.supabase.co`
Stack: Flutter + Riverpod + Supabase (REST/Auth) + SQLite (offline)

| # | Criterio | Nivel | Pts | Evidencia |
|---|----------|-------|-----|-----------|
| 1 | Integración E2E (FV → Core → App Clientes) | Excelente | **4/4** | Trigger `trg_fv_publicar_aprobacion` sobre `fv_credit_applications`: al pasar a `aprobado`/`desembolsado` publica evento en `sync_outbox` (DNI del cliente). La app cliente lo consume con `rpc_procesar_sync_outbox` y refleja crédito + cronograma + notificación + movimiento. `sync_log` deja traza. **Verificado en vivo:** aprobar una solicitud genera automáticamente la fila en `sync_outbox` y `sync_log`. |
| 2 | App Fuerza de Ventas — originación | Excelente | **4/4** | Cartera del día priorizada (`daily_portfolio`), ruta con GPS (`geolocator`, `route_visits`), ficha de cliente con semáforo de mora, consulta de buró (SBS + lista negra), pre-evaluación, wizard de solicitud (datos → negocio → simulador cronograma → firma digital `signature`), expediente de documentos (cámara + nitidez), cola offline (`sqflite` + `SyncManager` + `connectivity_plus`). |
| 4 | Seguridad RBAC (JWT + roles) | Excelente | **4/4** | Supabase Auth (JWT). `flutter_secure_storage` guarda access/refresh token. Roles `asesor`/`supervisor`/`admin` en `asesores_negocio`. Bloqueo tras **5 intentos** (`rpc_fv_registrar_intento` + `locked_until`). RLS por rol (`fn_rol_actual`): asesor ve sólo lo suyo, supervisor/admin ven todo. |
| 5 | Calidad de datos, arquitectura y documentación | Excelente | **4/4** | SQL versionado (`schema_and_seed.sql`, `02_rubrica_integracion.sql`). Capas `models`/`repositories`/`providers`/`services`/`screens`. Integridad referencial (FK a `clients`). Seed coherente (clientes con mora, lista negra, solicitudes en distintos estados). Ver `docs/ARQUITECTURA.md`. |
| | **TOTAL** | | **16/16** | |

> Criterio 3 (App Clientes — autoservicio) se evalúa en el proyecto `banco_pichincha`.

> **Esquema real:** las tablas de FV en Supabase usan el prefijo `fv_`
> (`fv_clients`, `fv_credit_applications`, `fv_daily_portfolio`,
> `fv_route_visits`, `fv_blacklist`, `fv_buro_queries`, `fv_client_documents`).
> El código de la app y de la web ya apunta a esos nombres.

## Cómo demostrar la integración E2E (Criterio 1)

1. Ejecutar en Supabase SQL Editor: `supabase/02_rubrica_integracion.sql`
   (crea el trigger `trg_fv_publicar_aprobacion`, roles y bloqueo de intentos).
2. En la app **cliente** (`banco_pichincha`) registrar un cliente con un DNI que
   exista en `fv_clients`, por ejemplo **`72345678`** (Roberto Morales).
3. Aprobar su solicitud desde la **web** (botón Aprobar) o por SQL:

```sql
update public.fv_credit_applications
set status = 'aprobado'
where client_dni = '72345678';
```

4. El trigger publica el evento en `sync_outbox` automáticamente y deja traza en `sync_log`.
5. En la app cliente, pull-to-refresh en **Inicio** → el crédito aparece en **Mis créditos** con la etiqueta "Originado Fuerza de Ventas", más notificación y movimiento de desembolso.

## Roles de prueba (RBAC)

El rol se deriva automáticamente de la columna real `nivel` de `asesores_negocio`
(idempotente, ver `02_rubrica_integracion.sql`):

| Regla de mapeo | Rol | Permisos | Conteo real |
|----------------|-----|----------|-------------|
| `nivel = 'Senior II'` | supervisor | Ve toda la cartera y puede aprobar | 89 |
| Primer asesor (`min(id)`) | admin | Acceso total | 1 |
| Resto de niveles | asesor | Sólo sus clientes y solicitudes | 270 |

Ejemplos de emails reales en la base: `lui.flores1@asesores.pe` (id 1 → admin),
asesores Senior II → supervisor, Junior I/II → asesor.

> El rol se resuelve por el email del JWT con `fn_rol_actual()` (`auth.email()`),
> porque `asesores_negocio` usa `id` entero y no se enlaza por `uuid`.
> La capa anónima (publishable key) sigue activa para la demo; las políticas RLS
> por rol aplican a sesiones `authenticated`.

## Scripts SQL

Las tablas `fv_*` ya existen en el proyecto. Sólo ejecutar:

1. `supabase/02_rubrica_integracion.sql` (trigger E2E + roles + bloqueo intentos)

> No ejecutar el antiguo `schema_and_seed.sql` (define tablas sin prefijo y
> duplicaría el modelo). Las tablas reales usan prefijo `fv_`.
