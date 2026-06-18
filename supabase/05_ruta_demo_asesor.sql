-- =============================================================================
-- Ruta demo para app Asesor Ventas (pestaña Ruta)
-- Ejecutar DESPUÉS de 03 + 04
-- Proyecto: uomaqpphyouzbnestbba.supabase.co
--
-- Inserta visitas de HOY en fv_route_visits con officer_id = id del asesor
-- (asesores_negocio) Y también con el uuid de auth.users (por si la app filtra
-- con cualquiera de los dos).
-- =============================================================================

do $$
declare
  v_asesor_id text;
  v_auth_id   text;
  v_client1   uuid;
  v_client2   uuid;
  v_client3   uuid;
begin
  select a.id::text into v_asesor_id
  from public.asesores_negocio a
  where lower(coalesce(a.email, '')) = 'asesor@pichincha.com'
  limit 1;

  select u.id::text into v_auth_id
  from auth.users u
  where lower(u.email) = 'asesor@pichincha.com'
  limit 1;

  if v_asesor_id is null and v_auth_id is null then
    raise notice 'No se encontró asesor@pichincha.com. Ejecuta 03 y 04 primero.';
    return;
  end if;

  -- Clientes demo (fv_clients si existe; si no, ids fijos)
  select id into v_client1 from public.fv_clients where dni = '1712345678' limit 1;
  select id into v_client2 from public.fv_clients where dni = '1723456789' limit 1;
  select id into v_client3 from public.fv_clients where dni = '1709876543' limit 1;

  v_client1 := coalesce(v_client1, 'c0000000-0000-4000-8000-000000000001'::uuid);
  v_client2 := coalesce(v_client2, 'c0000000-0000-4000-8000-000000000002'::uuid);
  v_client3 := coalesce(v_client3, 'c0000000-0000-4000-8000-000000000003'::uuid);

  -- Borrar visitas demo previas del día (evita duplicados al re-ejecutar)
  delete from public.fv_route_visits
  where visit_date = current_date
    and officer_id in (
      coalesce(v_asesor_id, ''),
      coalesce(v_auth_id, ''),
      'demo-officer-001',
      'a0000000-0000-4000-8000-000000000001'
    );

  -- Insertar con id de asesores_negocio (lo que devuelve el login por email)
  if v_asesor_id is not null then
    insert into public.fv_route_visits (
      officer_id, client_id, client_name, visit_date, visit_order,
      address, lat, lng, estimated_time, visit_status, notes
    ) values
      (v_asesor_id, v_client1, 'María Elena Vásquez', current_date, 1,
       'Av. 6 de Diciembre N45-12, Quito', -0.180653, -78.467838, '09:00', 'pending', 'Renovación crédito'),
      (v_asesor_id, v_client2, 'Roberto Andrés Morales', current_date, 2,
       'Cdla. Kennedy, Guayaquil', -2.1709, -79.9224, '10:30', 'pending', 'Seguimiento cartera'),
      (v_asesor_id, v_client3, 'Ana Lucía Herrera', current_date, 3,
       'Calle Sucre 102, Cuenca', -2.9001, -79.0059, '12:00', 'visited', 'Visita completada');
  end if;

  -- Si auth uuid es distinto, también insertar (app puede filtrar por auth.uid)
  if v_auth_id is not null and v_auth_id is distinct from v_asesor_id then
    insert into public.fv_route_visits (
      officer_id, client_id, client_name, visit_date, visit_order,
      address, lat, lng, estimated_time, visit_status, notes
    ) values
      (v_auth_id, v_client1, 'María Elena Vásquez', current_date, 1,
       'Av. 6 de Diciembre N45-12, Quito', -0.180653, -78.467838, '09:00', 'pending', 'Renovación crédito'),
      (v_auth_id, v_client2, 'Roberto Andrés Morales', current_date, 2,
       'Cdla. Kennedy, Guayaquil', -2.1709, -79.9224, '10:30', 'pending', 'Seguimiento cartera'),
      (v_auth_id, v_client3, 'Ana Lucía Herrera', current_date, 3,
       'Calle Sucre 102, Cuenca', -2.9001, -79.0059, '12:00', 'visited', 'Visita completada');
  end if;

  raise notice 'Ruta demo creada. asesor_id=%, auth_id=%', v_asesor_id, v_auth_id;
end $$;

-- Verificación
select id, officer_id, client_name, visit_date, visit_order, visit_status
from public.fv_route_visits
where visit_date = current_date
order by officer_id, visit_order;
