-- =============================================================================
-- Usuarios demo para docente / evaluación — Fuerza de Ventas
-- Ejecutar DESPUÉS de schema_and_seed.sql y 02_rubrica_integracion.sql
-- Proyecto: uomaqpphyouzbnestbba.supabase.co
-- =============================================================================
--
-- PASO A (Supabase Dashboard → Authentication → Users → Add user):
--   supervisor@pichincha.com  |  contraseña: Docente2025!
--   asesor@pichincha.com      |  contraseña: Docente2025!
--
-- PASO B: ejecutar este script (asigna roles en asesores_negocio).
--
-- App móvil FV (respaldo sin Auth): demo@pichincha.com / pichincha123  → rol asesor
-- Web supervisor: login en /login → supervisor@pichincha.com / Docente2025!
-- App cliente: registro libre; Caso 1 → DNI 40118120
-- =============================================================================

-- Asegurar columnas RBAC (idempotente si ya corrió 02_rubrica_integracion.sql)
alter table public.asesores_negocio
  add column if not exists rol  text not null default 'asesor',
  add column if not exists email text;

-- Supervisor (aprueba/rechaza en web; rol supervisor en BD)
insert into public.asesores_negocio (
  codigo_empleado, nombres, apellidos, agencia_id, perfil, activo, email, rol
)
select
  'SUP-001', 'María', 'Supervisor', '101', 'Supervisor de Crédito', true,
  'supervisor@pichincha.com', 'supervisor'
where not exists (
  select 1 from public.asesores_negocio
  where lower(coalesce(email, '')) = 'supervisor@pichincha.com'
);

update public.asesores_negocio
set rol = 'supervisor', activo = true, perfil = 'Supervisor de Crédito'
where lower(coalesce(email, '')) = 'supervisor@pichincha.com';

-- Asesor de campo (app móvil)
insert into public.asesores_negocio (
  codigo_empleado, nombres, apellidos, agencia_id, perfil, activo, email, rol
)
select
  'ASE-001', 'Carlos', 'Mendoza', '101', 'Oficial de Crédito Principal', true,
  'asesor@pichincha.com', 'asesor'
where not exists (
  select 1 from public.asesores_negocio
  where lower(coalesce(email, '')) = 'asesor@pichincha.com'
);

update public.asesores_negocio
set rol = 'asesor', activo = true, email = lower(email)
where lower(coalesce(email, '')) = 'asesor@pichincha.com';

-- Normalizar correos en minúsculas (login app móvil)
update public.asesores_negocio set email = lower(trim(email)) where email is not null;

-- Demo offline app móvil (tabla officers legacy + perfil asesor si existe fila demo)
insert into public.officers (email, password, name, agency_id)
values ('demo@pichincha.com', 'pichincha123', 'Carlos Mendoza (demo)', '101')
on conflict (email) do update
set password = excluded.password, name = excluded.name;

-- Si el id de asesores_negocio es uuid y coincide con auth.users, enlazar supervisor:
-- (descomenta tras crear el usuario en Auth)
-- update public.asesores_negocio a
-- set id = u.id::text
-- from auth.users u
-- where lower(u.email) = 'supervisor@pichincha.com'
--   and lower(a.email) = 'supervisor@pichincha.com';

-- Verificación
select id, codigo_empleado, nombres, apellidos, email, rol, activo
from public.asesores_negocio
where lower(coalesce(email, '')) in (
  'supervisor@pichincha.com', 'asesor@pichincha.com', 'demo@pichincha.com'
)
order by email;
