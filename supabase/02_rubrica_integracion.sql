-- =============================================================================
-- Fuerza de Ventas – Integración rúbrica (Criterios 1, 4 y 5)
-- Ejecutar DESPUÉS de schema_and_seed.sql en Supabase SQL Editor
-- Proyecto compartido con app cliente (banco_pichincha): uomaqpphyouzbnestbba
-- =============================================================================
-- Resuelve:
--   • Criterio 1 (E2E): al APROBAR una solicitud, se publica un evento en
--     sync_outbox que la app cliente consume (rpc_procesar_sync_outbox) y
--     refleja el crédito en su pantalla "Mis créditos".
--   • Criterio 4 (RBAC/JWT): roles asesor/supervisor/admin + bloqueo tras 5
--     intentos fallidos + matriz RLS por rol documentada.
--   • Criterio 5: SQL versionado e idempotente.
-- =============================================================================

-- ─── 1. RBAC: roles + control de intentos en asesores_negocio ────────────────
-- NOTA: el esquema real de asesores_negocio usa id entero, columna `nivel`
-- (Senior/Junior) y ya trae `email`. No se asume uuid ni columnas inexistentes.
alter table public.asesores_negocio
  add column if not exists rol            text not null default 'asesor',
  add column if not exists login_attempts integer not null default 0,
  add column if not exists locked_until   timestamptz;

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'asesores_rol_check'
  ) then
    alter table public.asesores_negocio
      add constraint asesores_rol_check
      check (rol in ('asesor', 'supervisor', 'admin'));
  end if;
end $$;

create unique index if not exists idx_asesores_email on public.asesores_negocio(lower(email))
  where email is not null;

-- Mapeo de rol a partir del `nivel` existente (idempotente):
--   Senior II  → supervisor (puede aprobar/rechazar)
--   resto      → asesor
update public.asesores_negocio set rol = 'supervisor'
  where nivel ilike 'Senior II%' and rol = 'asesor';

-- Un admin demo (el asesor con id más bajo) para pruebas de la matriz RBAC.
update public.asesores_negocio set rol = 'admin'
  where id = (select min(id) from public.asesores_negocio);

-- ─── 2. PUENTE SINCRONIZACIÓN (compartido con app cliente) ───────────────────
-- create if not exists para poder correr este script de forma independiente.
create table if not exists public.sync_outbox (
  id                 uuid primary key default gen_random_uuid(),
  tipo_evento        text not null check (tipo_evento in ('solicitud_aprobada', 'desembolso')),
  payload            jsonb not null,
  documento_cliente  text not null,
  estado             text not null default 'pendiente'
                     check (estado in ('pendiente', 'procesado', 'error')),
  error_mensaje      text,
  created_at         timestamptz not null default now(),
  processed_at       timestamptz
);

create table if not exists public.sync_log (
  id          uuid primary key default gen_random_uuid(),
  outbox_id   uuid references public.sync_outbox(id) on delete set null,
  evento      text not null,
  detalle     text,
  created_at  timestamptz not null default now()
);

create index if not exists idx_sync_outbox_estado on public.sync_outbox(estado);
create index if not exists idx_sync_outbox_dni on public.sync_outbox(documento_cliente);

alter table public.sync_outbox enable row level security;
alter table public.sync_log enable row level security;

do $$
begin
  -- anon (apps) puede leer/insertar outbox; el cliente procesa vía RPC security definer
  drop policy if exists "sync_outbox_rw_anon" on public.sync_outbox;
  create policy "sync_outbox_rw_anon" on public.sync_outbox for all to anon using (true) with check (true);
  drop policy if exists "sync_outbox_rw_auth" on public.sync_outbox;
  create policy "sync_outbox_rw_auth" on public.sync_outbox for all to authenticated using (true) with check (true);
  drop policy if exists "sync_log_r_anon" on public.sync_log;
  create policy "sync_log_r_anon" on public.sync_log for select to anon using (true);
  drop policy if exists "sync_log_r_auth" on public.sync_log;
  create policy "sync_log_r_auth" on public.sync_log for select to authenticated using (true);
end $$;

-- ─── 3. TRIGGER E2E: al aprobar/desembolsar → publicar evento al cliente ─────
create or replace function public.fn_fv_publicar_aprobacion()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_dni text := coalesce(new.client_dni, '');
begin
  -- Sólo cuando el estado pasa a aprobado/desembolsado (y cambió)
  if new.status in ('aprobado', 'desembolsado')
     and (tg_op = 'INSERT' or old.status is distinct from new.status) then

    if v_dni = '' then
      -- intenta resolver DNI desde fv_clients si la solicitud no lo trae
      select c.dni into v_dni from public.fv_clients c where c.id = new.client_id limit 1;
    end if;

    if coalesce(v_dni, '') <> '' then
      insert into public.sync_outbox (tipo_evento, documento_cliente, payload)
      values (
        'solicitud_aprobada',
        v_dni,
        jsonb_build_object(
          'solicitud_id',  new.id::text,
          'credito_id',    'cr_fv_' || substr(new.id::text, 1, 8),
          'descripcion',   coalesce(new.purpose, 'Crédito Fuerza de Ventas'),
          'monto',         new.amount,
          'plazo_meses',   coalesce(new.term_months, 12),
          'tasa_interes',  coalesce(new.tea, 18.0),
          'cuota_mensual', coalesce(new.monthly_payment, round(new.amount / greatest(coalesce(new.term_months,12),1), 2))
        )
      );

      insert into public.sync_log (evento, detalle)
      values ('aprobacion_publicada',
              'Solicitud ' || new.id::text || ' (DNI ' || v_dni || ') publicada en sync_outbox');
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists trg_fv_publicar_aprobacion on public.fv_credit_applications;
create trigger trg_fv_publicar_aprobacion
  after insert or update of status on public.fv_credit_applications
  for each row execute procedure public.fn_fv_publicar_aprobacion();

-- ─── 4. RPC: estado de login por email (bloqueo) ─────────────────────────────
create or replace function public.rpc_fv_login_estado(p_email text)
returns table(bloqueado boolean, intentos integer, existe boolean)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_locked timestamptz;
  v_attempts int;
  v_found boolean := false;
begin
  select a.locked_until, a.login_attempts, true
  into v_locked, v_attempts, v_found
  from public.asesores_negocio a
  where lower(a.email) = lower(trim(p_email))
  limit 1;

  bloqueado := v_locked is not null and v_locked > now();
  intentos := coalesce(v_attempts, 0);
  existe := coalesce(v_found, false);
  return next;
end;
$$;

grant execute on function public.rpc_fv_login_estado(text) to anon, authenticated;

-- ─── 5. RPC: registrar intento de login (bloquea tras 5 fallidos) ────────────
create or replace function public.rpc_fv_registrar_intento(p_email text, p_exitoso boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_exitoso then
    update public.asesores_negocio
      set login_attempts = 0, locked_until = null
      where lower(email) = lower(trim(p_email));
  else
    update public.asesores_negocio
      set login_attempts = login_attempts + 1,
          locked_until = case
            when login_attempts + 1 >= 5 then now() + interval '15 minutes'
            else locked_until
          end
      where lower(email) = lower(trim(p_email));
  end if;
end;
$$;

grant execute on function public.rpc_fv_registrar_intento(text, boolean) to anon, authenticated;

-- ─── 6. RLS POR ROL (capa "producción" con JWT; anon sigue activa para demo) ──
-- Matriz: asesor ve sólo lo suyo (officer_id = auth.uid); supervisor/admin ven todo.
create or replace function public.fn_rol_actual()
returns text
language sql
stable
security definer
set search_path = public
as $$
  -- asesores_negocio no se enlaza por uuid; el rol se resuelve por email del JWT.
  select coalesce(
    (select rol from public.asesores_negocio
       where lower(email) = lower(coalesce(auth.email(), '')) limit 1),
    'asesor');
$$;

do $$
begin
  drop policy if exists "apps_select_rol" on public.fv_credit_applications;
  create policy "apps_select_rol" on public.fv_credit_applications for select to authenticated
    using (public.fn_rol_actual() in ('supervisor','admin') or officer_id = auth.uid()::text);

  drop policy if exists "apps_update_rol" on public.fv_credit_applications;
  create policy "apps_update_rol" on public.fv_credit_applications for update to authenticated
    using (public.fn_rol_actual() in ('supervisor','admin') or officer_id = auth.uid()::text);
end $$;

-- =============================================================================
-- DEMO E2E (descomenta para probar sin web):
--   1) Registra un cliente en la app banco_pichincha con DNI = 1712345678
--   2) Aprueba la solicitud de ese cliente:
--      update public.fv_credit_applications set status = 'aprobado'
--      where client_dni = '<DNI_DEL_CLIENTE>';
--   3) El trigger inserta en sync_outbox automáticamente.
--   4) En la app cliente, refresca Inicio → aparece el crédito.
-- =============================================================================
