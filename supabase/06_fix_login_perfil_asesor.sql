-- Fix login "invalid input syntax for type integer" (UUID auth.uid vs id entero)
-- Ejecutar en Supabase SQL Editor si el login con asesor@pichincha.com falla.

create or replace function public.rpc_fv_perfil_asesor(p_email text)
returns table(
  id integer,
  codigo text,
  codigo_empleado text,
  id_agencia integer,
  agencia_id integer,
  nombres text,
  apellidos text,
  email text,
  nivel text,
  perfil text,
  activo boolean,
  rol text
)
language plpgsql
security definer
set search_path = public
as $$
begin
  return query
  select
    a.id,
    a.codigo,
    a.codigo as codigo_empleado,
    a.id_agencia,
    a.id_agencia as agencia_id,
    a.nombres,
    a.apellidos,
    a.email,
    a.nivel,
    a.nivel as perfil,
    a.activo,
    a.rol
  from public.asesores_negocio a
  where lower(coalesce(a.email, '')) = lower(trim(p_email))
  limit 1;
end;
$$;

grant execute on function public.rpc_fv_perfil_asesor(text) to anon, authenticated;

drop policy if exists "auth_select_asesor_email" on public.asesores_negocio;
create policy "auth_select_asesor_email" on public.asesores_negocio
  for select to authenticated
  using (lower(coalesce(email, '')) = lower(coalesce(auth.email(), '')));

-- Verificar fila demo del asesor
select id, codigo, nombres, email, rol, activo
from public.asesores_negocio
where lower(coalesce(email, '')) = 'asesor@pichincha.com';
