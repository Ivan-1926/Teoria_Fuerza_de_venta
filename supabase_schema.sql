-- =============================================================================
-- Fuerza de Ventas – Banco Pichincha  |  Supabase SQL Schema
-- Run this in the Supabase SQL Editor (https://supabase.com/dashboard)
-- =============================================================================

-- Officers (Sales Force users)
create table if not exists officers (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  email       text unique not null,
  password    text not null,          -- plain text for demo; use Auth in production
  zone        text,
  phone       text,
  avatar_url  text,
  created_at  timestamptz default now()
);

-- Clients
create table if not exists clients (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  dni             text unique not null,
  phone           text,
  email           text,
  address         text,
  lat             double precision,
  lng             double precision,
  credit_score    integer default 650,
  total_debt      numeric(12,2) default 0,
  monthly_income  numeric(12,2),
  occupation      text,
  business_name   text,
  status          text default 'active',  -- active | blacklisted | inactive
  officer_id      uuid references officers(id),
  created_at      timestamptz default now()
);

-- Daily Portfolio (clients scheduled for today's visit / renewal)
create table if not exists daily_portfolio (
  id              uuid primary key default gen_random_uuid(),
  client_id       uuid references clients(id),
  client_name     text not null,
  officer_id      uuid references officers(id),
  next_visit_date date not null,
  loan_balance    numeric(12,2) default 0,
  days_overdue    integer default 0,
  loan_number     text,
  purpose         text,
  renewal_type    text default 'renovation',  -- renovation | new | collection
  priority        integer default 0,          -- higher = more urgent
  created_at      timestamptz default now()
);

-- Credit Applications
create table if not exists credit_applications (
  id              uuid primary key default gen_random_uuid(),
  client_id       uuid references clients(id),
  client_name     text not null,
  client_dni      text,
  amount          numeric(12,2) not null,
  term_months     integer not null default 12,
  purpose         text,
  monthly_payment numeric(12,2),
  interest_rate   numeric(5,2) default 18.0,
  collateral      text,
  status          text default 'enviado',   -- enviado | comite | aprobado | desembolsado | rechazado
  officer_id      uuid references officers(id),
  notes           text,
  document_urls   jsonb default '[]',
  submitted_at    timestamptz default now(),
  updated_at      timestamptz default now()
);

-- Route Visits
create table if not exists route_visits (
  id              uuid primary key default gen_random_uuid(),
  officer_id      uuid references officers(id),
  client_id       uuid references clients(id),
  client_name     text not null,
  visit_date      date not null,
  visit_order     integer default 0,
  address         text,
  lat             double precision,
  lng             double precision,
  estimated_time  text,
  visit_status    text default 'pending',   -- pending | visited | skipped
  notes           text,
  created_at      timestamptz default now()
);

-- =============================================================================
-- Demo seed data
-- =============================================================================

insert into officers (name, email, password, zone, phone) values
  ('Carlos Mendoza', 'demo@pichincha.com', 'pichincha123', 'Zona Norte – Quito', '0991234567')
on conflict (email) do nothing;

insert into clients (name, dni, phone, address, credit_score, total_debt, monthly_income, occupation, business_name) values
  ('María López',    '1710234567', '0987654321', 'Av. Colón 123, Quito',         720, 3500.00, 1800.00, 'Comerciante',  'Tienda López'),
  ('Juan Quispe',    '1723456789', '0976543210', 'Calle Sucre 45, Cotocollao',    590, 8200.00, 2200.00, 'Agricultor',   'Finca Quispe'),
  ('Rosa Pilataxi',  '1745678901', '0965432109', 'Mercado Central Local 12',      680, 1200.00, 1500.00, 'Vendedora',    'Abastos Rosa'),
  ('Pedro Andrade',  '1756789012', '0954321098', 'Barrio La Floresta, Casa 7',    810, 0.00,    3500.00, 'Profesional',  ''),
  ('Ana Simbaña',    '1767890123', '0943210987', 'Coop. El Calzado Mz3 V2',      640, 5600.00, 1200.00, 'Artesana',     'Calzado Simbaña')
on conflict (dni) do nothing;
