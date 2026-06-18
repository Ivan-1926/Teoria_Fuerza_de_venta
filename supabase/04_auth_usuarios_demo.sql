-- =============================================================================
-- Supabase AUTH — usuarios demo (asesor + supervisor)
-- Ejecutar DESPUÉS de 03_usuarios_demo_docente.sql
-- Proyecto: uomaqpphyouzbnestbba.supabase.co
--
--   asesor@pichincha.com      / Docente2025!
--   supervisor@pichincha.com  / Docente2025!
-- =============================================================================

create extension if not exists pgcrypto;

-- ─── Perfiles demo en asesores_negocio (esquema real) ────────────────────────
alter table public.asesores_negocio
  add column if not exists rol text not null default 'asesor',
  add column if not exists email text,
  add column if not exists login_attempts integer not null default 0,
  add column if not exists locked_until timestamptz;

insert into public.asesores_negocio (
  codigo, id_agencia, nombres, apellidos, dni, email, telefono,
  nivel, zona_asignada, activo, rol,
  cartera_clientes_promedio, meta_creditos_mes, meta_monto_mes
)
select 'SUP-DEMO-01', 1, 'María', 'Supervisor', '90000002',
  'supervisor@pichincha.com', '999000002', 'Senior II', 'Zona Demo', true, 'supervisor', 0, 0, 0
where not exists (
  select 1 from public.asesores_negocio where lower(coalesce(email,'')) = 'supervisor@pichincha.com'
);

insert into public.asesores_negocio (
  codigo, id_agencia, nombres, apellidos, dni, email, telefono,
  nivel, zona_asignada, activo, rol,
  cartera_clientes_promedio, meta_creditos_mes, meta_monto_mes
)
select 'ASE-DEMO-01', 1, 'Carlos', 'Mendoza', '90000001',
  'asesor@pichincha.com', '999000001', 'Senior I', 'Zona Demo', true, 'asesor', 100, 10, 15000
where not exists (
  select 1 from public.asesores_negocio where lower(coalesce(email,'')) = 'asesor@pichincha.com'
);

update public.asesores_negocio set rol = 'supervisor', activo = true, nivel = 'Senior II'
where lower(coalesce(email,'')) = 'supervisor@pichincha.com';

update public.asesores_negocio set rol = 'asesor', activo = true, email = lower(trim(email))
where lower(coalesce(email,'')) = 'asesor@pichincha.com';

-- Rol JWT cuando aún no hay fila en asesores_negocio
create or replace function public.fn_rol_actual()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select rol from public.asesores_negocio
       where lower(email) = lower(coalesce(auth.email(), '')) limit 1),
    nullif(lower(coalesce(auth.jwt()->'user_metadata'->>'rol', '')), ''),
    'asesor'
  );
$$;

-- Parche: staff FV no crea perfil cliente (trigger app banco_pichincha)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid       text := new.id::text;
  v_staff_rol text := lower(coalesce(nullif(trim(new.raw_user_meta_data->>'rol'), ''), ''));
  v_nombre    text := coalesce(nullif(trim(new.raw_user_meta_data->>'nombre'), ''), 'Usuario Nuevo');
  v_documento text := coalesce(
    nullif(trim(new.raw_user_meta_data->>'documento'), ''),
    '9' || substr(replace(v_uid, '-', ''), 1, 7)
  );
  v_celular   text := coalesce(new.raw_user_meta_data->>'celular', '');
  v_seed      bigint := abs(hashtext(v_uid));
  v_num_ah    text := '2100' || lpad((v_seed % 1000000)::text, 6, '0');
  v_num_cte   text := '2101' || lpad(((v_seed / 7) % 1000000)::text, 6, '0');
  v_cci_ah    text := '002A' || replace(v_uid, '-', '');
  v_cci_cte   text := '002B' || replace(v_uid, '-', '');
begin
  if v_staff_rol in ('asesor', 'supervisor', 'admin') then
    return new;
  end if;

  insert into public.usuarios (id, nombre, documento, email, celular)
  values (v_uid, v_nombre, v_documento, new.email, v_celular)
  on conflict (id) do update
    set nombre = excluded.nombre, documento = excluded.documento, celular = excluded.celular;

  insert into public.profiles (id, rol, documento, login_attempts)
  values (new.id, 'cliente', v_documento, 0)
  on conflict (id) do update set documento = excluded.documento;

  insert into public.cuentas_ahorro (id, usuario_id, numero, cci, tipo, saldo)
  values
    ('ca_' || v_uid || '_ahorros',   v_uid, v_num_ah,  v_cci_ah,  'Cuenta de Ahorros', 5000.00),
    ('ca_' || v_uid || '_corriente', v_uid, v_num_cte, v_cci_cte, 'Cuenta Corriente',  1000.00)
  on conflict (id) do nothing;

  insert into public.tarjetas (id, usuario_id, cuenta_id, numero_enmascarado, tipo, bloqueada)
  values ('td_' || v_uid || '_1', v_uid, 'ca_' || v_uid || '_ahorros',
          '*' || right(v_num_ah, 4), 'Tarjeta De Débito', false)
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

create or replace function public.fn_upsert_demo_auth_user(
  p_email text,
  p_password text,
  p_meta jsonb default '{}'::jsonb
)
returns uuid
language plpgsql
security definer
set search_path = auth, public, extensions
as $$
declare
  v_user_id uuid;
  v_email text := lower(trim(p_email));
  v_pw text;
begin
  if v_email = '' or p_password is null or length(p_password) < 6 then
    raise exception 'Email y contraseña (mín. 6 caracteres) son obligatorios.';
  end if;

  v_pw := extensions.crypt(p_password, extensions.gen_salt('bf'));

  select id into v_user_id from auth.users where lower(email) = v_email;

  if v_user_id is null then
    v_user_id := gen_random_uuid();
    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, confirmation_sent_at, recovery_sent_at, last_sign_in_at,
      raw_app_meta_data, raw_user_meta_data, is_super_admin,
      created_at, updated_at,
      confirmation_token, email_change, email_change_token_new, recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v_user_id,
      'authenticated', 'authenticated', v_email, v_pw,
      now(), now(), now(), now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      coalesce(p_meta, '{}'::jsonb), false, now(), now(), '', '', '', ''
    );
    insert into auth.identities (
      id, provider_id, user_id, identity_data, provider,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), v_user_id::text, v_user_id,
      jsonb_build_object('sub', v_user_id::text, 'email', v_email,
        'email_verified', true, 'phone_verified', false),
      'email', now(), now(), now()
    );
  else
    update auth.users
    set encrypted_password = v_pw,
        email_confirmed_at = coalesce(email_confirmed_at, now()),
        raw_user_meta_data = coalesce(p_meta, raw_user_meta_data),
        updated_at = now()
    where id = v_user_id;
    update auth.identities
    set identity_data = jsonb_build_object(
          'sub', v_user_id::text, 'email', v_email,
          'email_verified', true, 'phone_verified', false),
        updated_at = now()
    where user_id = v_user_id and provider = 'email';
  end if;

  return v_user_id;
end;
$$;

select public.fn_upsert_demo_auth_user(
  'asesor@pichincha.com', 'Docente2025!',
  '{"rol":"asesor","nombre":"Carlos Mendoza","documento":"90000001"}'::jsonb
) as auth_user_asesor;

select public.fn_upsert_demo_auth_user(
  'supervisor@pichincha.com', 'Docente2025!',
  '{"rol":"supervisor","nombre":"María Supervisor","documento":"90000002"}'::jsonb
) as auth_user_supervisor;

-- Verificación Auth (debe devolver 2 filas)
select u.id, u.email,
  u.email_confirmed_at is not null as email_confirmado,
  u.raw_user_meta_data->>'rol' as rol_meta
from auth.users u
where lower(u.email) in ('asesor@pichincha.com', 'supervisor@pichincha.com')
order by u.email;

-- Verificación perfiles BD (esquema real — sin codigo_empleado)
select id, codigo, nombres, apellidos, email, rol, nivel, activo
from public.asesores_negocio
where lower(coalesce(email, '')) in ('asesor@pichincha.com', 'supervisor@pichincha.com')
order by email;
