-- =============================================================================
-- Usuarios demo — ESQUEMA REAL de asesores_negocio
-- Ejecutar DESPUÉS de 02_rubrica_integracion.sql
-- Luego: 04_auth_usuarios_demo.sql y 05_ruta_demo_asesor.sql
-- =============================================================================
-- Columnas reales: id, codigo, id_agencia, nombres, apellidos, dni, email,
-- telefono, nivel, zona_asignada, activo, rol, login_attempts, locked_until
-- (NO existen: codigo_empleado, agencia_id, perfil)
-- =============================================================================

alter table public.asesores_negocio
  add column if not exists rol text not null default 'asesor',
  add column if not exists email text,
  add column if not exists login_attempts integer not null default 0,
  add column if not exists locked_until timestamptz;

-- Supervisor web
insert into public.asesores_negocio (
  codigo, id_agencia, nombres, apellidos, dni, email, telefono,
  nivel, zona_asignada, activo, rol,
  cartera_clientes_promedio, meta_creditos_mes, meta_monto_mes
)
select
  'SUP-DEMO-01', 1, 'María', 'Supervisor', '90000002',
  'supervisor@pichincha.com', '999000002', 'Senior II', 'Zona Demo', true, 'supervisor',
  0, 0, 0
where not exists (
  select 1 from public.asesores_negocio
  where lower(coalesce(email, '')) = 'supervisor@pichincha.com'
);

update public.asesores_negocio
set rol = 'supervisor', activo = true, nivel = 'Senior II', email = lower(trim(email))
where lower(coalesce(email, '')) = 'supervisor@pichincha.com';

-- Asesor app móvil
insert into public.asesores_negocio (
  codigo, id_agencia, nombres, apellidos, dni, email, telefono,
  nivel, zona_asignada, activo, rol,
  cartera_clientes_promedio, meta_creditos_mes, meta_monto_mes
)
select
  'ASE-DEMO-01', 1, 'Carlos', 'Mendoza', '90000001',
  'asesor@pichincha.com', '999000001', 'Senior I', 'Zona Demo', true, 'asesor',
  100, 10, 15000
where not exists (
  select 1 from public.asesores_negocio
  where lower(coalesce(email, '')) = 'asesor@pichincha.com'
);

update public.asesores_negocio
set rol = 'asesor', activo = true, email = lower(trim(email))
where lower(coalesce(email, '')) = 'asesor@pichincha.com';

-- Verificación (columnas del esquema real)
select id, codigo, nombres, apellidos, email, rol, nivel, activo
from public.asesores_negocio
where lower(coalesce(email, '')) in (
  'supervisor@pichincha.com', 'asesor@pichincha.com'
)
order by email;
