-- Baseline schema for core account tables that already exist in production.
-- Uses IF NOT EXISTS so the migration is idempotent on existing environments.

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  pin_hash text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.children (
  id uuid primary key default gen_random_uuid(),
  parent_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  avatar_key text,
  created_at timestamptz not null default now(),
  birth_year int,
  gender text
);

create table if not exists public.child_settings (
  child_id uuid primary key references public.children (id) on delete cascade,
  daily_attempt_cap int not null default 6,
  realtime_feedback_cap int not null default 3,
  passes_required int not null default 3,
  pass_threshold int not null default 80,
  blur_after_attempt int,
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.children enable row level security;
alter table public.child_settings enable row level security;

-- RLS policies (create only if missing)
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'profile_select_own'
  ) then
    create policy profile_select_own on public.profiles
      for select
      using (auth.uid() = id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'profile_insert_own'
  ) then
    create policy profile_insert_own on public.profiles
      for insert
      with check (auth.uid() = id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'profiles' and policyname = 'profile_update_own'
  ) then
    create policy profile_update_own on public.profiles
      for update
      using (auth.uid() = id);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'children' and policyname = 'children_select_own'
  ) then
    create policy children_select_own on public.children
      for select
      using (parent_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'children' and policyname = 'children_insert_own'
  ) then
    create policy children_insert_own on public.children
      for insert
      with check (parent_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'children' and policyname = 'children_update_own'
  ) then
    create policy children_update_own on public.children
      for update
      using (parent_id = auth.uid());
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'child_settings' and policyname = 'child_settings_select_own'
  ) then
    create policy child_settings_select_own on public.child_settings
      for select
      using (
        exists (
          select 1 from public.children
          where children.id = child_settings.child_id
            and children.parent_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'child_settings' and policyname = 'child_settings_insert_own'
  ) then
    create policy child_settings_insert_own on public.child_settings
      for insert
      with check (
        exists (
          select 1 from public.children
          where children.id = child_settings.child_id
            and children.parent_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'child_settings' and policyname = 'child_settings_update_own'
  ) then
    create policy child_settings_update_own on public.child_settings
      for update
      using (
        exists (
          select 1 from public.children
          where children.id = child_settings.child_id
            and children.parent_id = auth.uid()
        )
      );
  end if;
end $$;
