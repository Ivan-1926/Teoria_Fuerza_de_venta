-- =============================================================================
-- Banco Pichincha – Fuerza de Ventas
-- Proyecto: https://uomaqpphyouzbnestbba.supabase.co
-- Ejecutar TODO este script en: Supabase Dashboard → SQL Editor → Run
-- =============================================================================

-- Extensiones (por si acaso)
create extension if not exists "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. TABLAS
-- -----------------------------------------------------------------------------

create table if not exists public.asesores_negocio (
  id uuid primary key default uuid_generate_v4(),
  codigo_empleado text not null,
  nombres text not null,
  apellidos text not null,
  agencia_id text not null default '101',
  perfil text not null default 'Oficial de Crédito',
  activo boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.officers (
  id uuid primary key default uuid_generate_v4(),
  email text unique not null,
  password text not null,
  name text,
  agency_id text default '101',
  created_at timestamptz not null default now()
);

create table if not exists public.clients (
  id uuid primary key default uuid_generate_v4(),
  name text not null,
  dni text unique not null,
  phone text,
  email text,
  address text,
  business_name text,
  business_sector text,
  business_address text,
  monthly_income numeric(12,2) default 0,
  business_age_years int default 0,
  credit_score int default 650,
  sbs_score int,
  total_debt numeric(12,2) default 0,
  max_debt numeric(12,2) default 0,
  days_overdue int default 0,
  status text default 'active',
  blacklist_reason text,
  officer_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.daily_portfolio (
  id uuid primary key default uuid_generate_v4(),
  client_id uuid references public.clients(id) on delete cascade,
  client_name text not null,
  officer_id text not null,
  next_visit_date date not null default current_date,
  loan_balance numeric(12,2) default 0,
  days_overdue int default 0,
  loan_number text,
  purpose text default 'Crédito',
  renewal_type text default 'renovation',
  priority int default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.credit_applications (
  id uuid primary key default uuid_generate_v4(),
  client_id uuid references public.clients(id) on delete set null,
  client_name text not null,
  client_dni text,
  amount numeric(12,2) not null,
  term_months int default 12,
  tea numeric(6,2) default 18,
  monthly_payment numeric(12,2),
  purpose text,
  business_name text,
  monthly_income numeric(12,2),
  status text not null default 'pendiente',
  officer_id text,
  submitted_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.route_visits (
  id uuid primary key default uuid_generate_v4(),
  officer_id text not null,
  client_id uuid references public.clients(id) on delete cascade,
  client_name text not null,
  visit_date date not null default current_date,
  visit_order int default 1,
  address text,
  lat double precision,
  lng double precision,
  estimated_time text,
  visit_status text default 'pending',
  notes text,
  created_at timestamptz not null default now()
);

create table if not exists public.client_documents (
  id uuid primary key default uuid_generate_v4(),
  client_id uuid references public.clients(id) on delete cascade,
  dni text not null,
  doc_type text not null,
  file_url text,
  status text default 'pendiente',
  sharpness_score double precision,
  is_sharp boolean default false,
  officer_id text,
  application_id uuid,
  captured_at timestamptz default now()
);

create table if not exists public.buro_queries (
  id uuid primary key default uuid_generate_v4(),
  dni text not null,
  client_id uuid,
  client_name text,
  calificacion_sbs int,
  calificacion_sbs_label text,
  deuda_total numeric(12,2),
  mayor_deuda numeric(12,2),
  dias_mora int default 0,
  in_blacklist boolean default false,
  blacklist_reason text,
  officer_id text,
  consulted_at timestamptz default now()
);

create table if not exists public.blacklist (
  id uuid primary key default uuid_generate_v4(),
  dni text unique not null,
  reason text not null,
  created_at timestamptz not null default now()
);

-- -----------------------------------------------------------------------------
-- 2. RLS (lectura/escritura con anon key de la app – solo desarrollo/demo)
-- -----------------------------------------------------------------------------

alter table public.asesores_negocio enable row level security;
alter table public.officers enable row level security;
alter table public.clients enable row level security;
alter table public.daily_portfolio enable row level security;
alter table public.credit_applications enable row level security;
alter table public.route_visits enable row level security;
alter table public.client_documents enable row level security;
alter table public.buro_queries enable row level security;
alter table public.blacklist enable row level security;

-- Políticas permisivas para rol anon (clave publishable de la app)
do $$
declare
  t text;
  tables text[] := array[
    'asesores_negocio','officers','clients','daily_portfolio',
    'credit_applications','route_visits','client_documents',
    'buro_queries','blacklist'
  ];
begin
  foreach t in array tables loop
    execute format('drop policy if exists "anon_select_%s" on public.%I', t, t);
    execute format('drop policy if exists "anon_insert_%s" on public.%I', t, t);
    execute format('drop policy if exists "anon_update_%s" on public.%I', t, t);
    execute format('create policy "anon_select_%s" on public.%I for select to anon using (true)', t, t);
    execute format('create policy "anon_insert_%s" on public.%I for insert to anon with check (true)', t, t);
    execute format('create policy "anon_update_%s" on public.%I for update to anon using (true)', t, t);
  end loop;
end $$;

-- -----------------------------------------------------------------------------
-- 3. STORAGE – bucket documentos (crear en UI si falla el SQL)
-- Dashboard → Storage → New bucket: "documents" → Public
-- -----------------------------------------------------------------------------

-- insert into storage.buckets (id, name, public) values ('documents', 'documents', true)
-- on conflict (id) do nothing;

-- -----------------------------------------------------------------------------
-- 4. DATOS DE EJEMPLO (oficial demo + clientes + cartera + solicitudes + ruta)
-- -----------------------------------------------------------------------------

-- Asesor (perfil usado si vinculas Auth; id fijo para demo)
insert into public.asesores_negocio (id, codigo_empleado, nombres, apellidos, agencia_id, perfil, activo)
values (
  'a0000000-0000-4000-8000-000000000001',
  'EMP-001',
  'Carlos',
  'Mendoza',
  '101',
  'Oficial de Crédito Principal',
  true
) on conflict (id) do nothing;

-- Login legacy tabla officers (email/password en texto – solo demo académico)
insert into public.officers (email, password, name, agency_id)
values ('demo@pichincha.com', 'pichincha123', 'Carlos Mendoza', '101')
on conflict (email) do nothing;

-- Clientes
insert into public.clients (id, name, dni, phone, email, address, business_name, business_sector, monthly_income, business_age_years, credit_score, total_debt, max_debt, days_overdue, officer_id)
values
  ('c0000000-0000-4000-8000-000000000001', 'María Elena Vásquez', '1712345678', '0991234567', 'maria.vasquez@email.com', 'Av. 6 de Diciembre N45-12, Quito', 'Panadería La Espiga', 'Alimentos', 1850, 4, 720, 3200, 2100, 0, 'a0000000-0000-4000-8000-000000000001'),
  ('c0000000-0000-4000-8000-000000000002', 'Roberto Andrés Morales', '1723456789', '0987654321', 'roberto.morales@email.com', 'Cdla. Kennedy, Guayaquil', 'Taller Mecánico RM', 'Servicios automotriz', 2400, 7, 680, 8500, 5200, 12, 'a0000000-0000-4000-8000-000000000001'),
  ('c0000000-0000-4000-8000-000000000003', 'Ana Lucía Herrera', '1709876543', '0998877665', 'ana.herrera@email.com', 'Calle Sucre 102, Cuenca', 'Boutique Ana Moda', 'Comercio retail', 1600, 3, 640, 4100, 2800, 0, 'a0000000-0000-4000-8000-000000000001'),
  ('c0000000-0000-4000-8000-000000000004', 'Patricia Gómez', '1799887766', '0991122334', 'patricia.gomez@email.com', 'Machala centro', 'Farmacia Salud', 'Salud', 2100, 5, 590, 12000, 7500, 45, 'a0000000-0000-4000-8000-000000000001')
on conflict (id) do nothing;

-- Lista negra (probar modal rojo en Buró con DNI 1799887766)
insert into public.blacklist (dni, reason)
values ('1799887766', 'Incumplimiento grave reportado por buró interno')
on conflict (dni) do nothing;

-- Cartera del día
insert into public.daily_portfolio (client_id, client_name, officer_id, next_visit_date, loan_balance, days_overdue, purpose, renewal_type, priority)
select id, name, 'a0000000-0000-4000-8000-000000000001', current_date,
  case dni when '1712345678' then 3200 when '1723456789' then 8500 when '1709876543' then 4100 else 12000 end,
  days_overdue, 'Crédito comercial', 'renovation',
  case when days_overdue > 0 then 10 else 5 end
from public.clients
where dni in ('1712345678','1723456789','1709876543','1799887766');

-- Solicitudes de crédito
insert into public.credit_applications (client_id, client_name, client_dni, amount, term_months, tea, monthly_payment, purpose, status, officer_id, submitted_at)
values
  ('c0000000-0000-4000-8000-000000000001', 'María Elena Vásquez', '1712345678', 8500, 18, 18, 520, 'Capital de trabajo', 'enviado', 'a0000000-0000-4000-8000-000000000001', now() - interval '2 days'),
  ('c0000000-0000-4000-8000-000000000002', 'Roberto Andrés Morales', '1723456789', 15000, 24, 18, 780, 'Compra de equipo', 'comite', 'a0000000-0000-4000-8000-000000000001', now() - interval '5 days'),
  ('c0000000-0000-4000-8000-000000000003', 'Ana Lucía Herrera', '1709876543', 5200, 12, 18, 480, 'Inventario temporada', 'aprobado', 'a0000000-0000-4000-8000-000000000001', now() - interval '8 days'),
  ('c0000000-0000-4000-8000-000000000004', 'Patricia Gómez', '1799887766', 3000, 6, 18, 530, 'Gastos operativos', 'pendiente', 'a0000000-0000-4000-8000-000000000001', now());

-- Visitas de ruta (hoy)
insert into public.route_visits (officer_id, client_id, client_name, visit_date, visit_order, address, lat, lng, visit_status)
values
  ('a0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000001', 'María Elena Vásquez', current_date, 1, 'Av. 6 de Diciembre N45-12, Quito', -0.1807, -78.4678, 'pending'),
  ('a0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000002', 'Roberto Andrés Morales', current_date, 2, 'Cdla. Kennedy, Guayaquil', -2.1709, -79.9224, 'pending'),
  ('a0000000-0000-4000-8000-000000000001', 'c0000000-0000-4000-8000-000000000003', 'Ana Lucía Herrera', current_date, 3, 'Calle Sucre 102, Cuenca', -2.9001, -79.0059, 'visited');

-- -----------------------------------------------------------------------------
-- FIN – App Flutter ya usa:
--   URL:  https://uomaqpphyouzbnestbba.supabase.co
--   Key:  sb_publishable_fymmXEWgkQSdaXe-F3_8OA_QK6ZOnCe
-- Login demo local: demo@pichincha.com / pichincha123
-- -----------------------------------------------------------------------------
