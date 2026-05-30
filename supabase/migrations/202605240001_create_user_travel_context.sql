create table if not exists public.user_travel_context (
  user_id uuid primary key references auth.users(id) on delete cascade,
  origin_airport_iata text,
  origin_airport_name text,
  origin_city text,
  origin_country text,
  adults_count integer not null default 1 check (adults_count >= 1),
  children_count integer not null default 0 check (children_count >= 0),
  child_ages integer[] not null default '{}',
  trip_purpose text not null default 'relaxation',
  budget_type text not null default 'flexible',
  cabin_class text not null default 'economy',
  flexible_dates boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_travel_context enable row level security;

create policy "Users can read own travel context"
  on public.user_travel_context
  for select
  using (auth.uid() = user_id);

create policy "Users can insert own travel context"
  on public.user_travel_context
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update own travel context"
  on public.user_travel_context
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
