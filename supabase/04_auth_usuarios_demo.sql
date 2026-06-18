-- =============================================================================
-- Supabase AUTH — usuarios demo con contraseña (asesor + supervisor)
-- Ejecutar DESPUÉS de 03_usuarios_demo_docente.sql
-- Proyecto: uomaqpphyouzbnestbba.supabase.co
--
-- Crea o actualiza en auth.users + auth.identities:
--   asesor@pichincha.com      / Docente2025!
--   supervisor@pichincha.com  / Docente2025!
--
-- Si el login sigue fallando: Authentication → Providers → desactiva
-- "Confirm email" y vuelve a ejecutar este script.
-- =============================================================================

create extension if not exists pgcrypto;

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

  select id into v_user_id
  from auth.users
  where lower(email) = v_email;

  if v_user_id is null then
    v_user_id := gen_random_uuid();

    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      confirmation_sent_at,
      recovery_sent_at,
      last_sign_in_at,
      raw_app_meta_data,
      raw_user_meta_data,
      is_super_admin,
      created_at,
      updated_at,
      confirmation_token,
      email_change,
      email_change_token_new,
      recovery_token
    ) values (
      '00000000-0000-0000-0000-000000000000',
      v_user_id,
      'authenticated',
      'authenticated',
      v_email,
      v_pw,
      now(),
      now(),
      now(),
      now(),
      '{"provider":"email","providers":["email"]}'::jsonb,
      coalesce(p_meta, '{}'::jsonb),
      false,
      now(),
      now(),
      '',
      '',
      '',
      ''
    );

    insert into auth.identities (
      id,
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) values (
      gen_random_uuid(),
      v_user_id::text,
      v_user_id,
      jsonb_build_object(
        'sub', v_user_id::text,
        'email', v_email,
        'email_verified', true,
        'phone_verified', false
      ),
      'email',
      now(),
      now(),
      now()
    );
  else
    update auth.users
    set
      encrypted_password = v_pw,
      email_confirmed_at = coalesce(email_confirmed_at, now()),
      updated_at = now()
    where id = v_user_id;

    update auth.identities
    set
      identity_data = jsonb_build_object(
        'sub', v_user_id::text,
        'email', v_email,
        'email_verified', true,
        'phone_verified', false
      ),
      updated_at = now()
    where user_id = v_user_id and provider = 'email';
  end if;

  return v_user_id;
end;
$$;

-- ─── Crear / resetear contraseñas demo ───────────────────────────────────────
select public.fn_upsert_demo_auth_user(
  'asesor@pichincha.com',
  'Docente2025!',
  '{"rol":"asesor","nombre":"Carlos Mendoza"}'::jsonb
) as auth_user_asesor;

select public.fn_upsert_demo_auth_user(
  'supervisor@pichincha.com',
  'Docente2025!',
  '{"rol":"supervisor","nombre":"María Supervisor"}'::jsonb
) as auth_user_supervisor;

-- ─── Verificación ────────────────────────────────────────────────────────────
select
  u.id,
  u.email,
  u.email_confirmed_at is not null as email_confirmado,
  u.created_at
from auth.users u
where lower(u.email) in ('asesor@pichincha.com', 'supervisor@pichincha.com')
order by u.email;

select id, codigo_empleado, nombres, apellidos, email, rol, activo
from public.asesores_negocio
where lower(coalesce(email, '')) in ('asesor@pichincha.com', 'supervisor@pichincha.com')
order by email;
