-- Map + level system scaffolding aligned with "Home Screen, Map Navigation & Lessons Flow".
-- Content (verse text/meaning) remains in app assets for now. Supabase owns progress + unlocking state.

create extension if not exists "pgcrypto";

-- -----------------------------
-- Map metadata (read-only)
-- -----------------------------

create table if not exists public.galaxies (
  id int primary key,
  name_en text not null,
  name_ar text,
  order_index int not null
);

create table if not exists public.galaxy_surahs (
  galaxy_id int not null references public.galaxies (id) on delete cascade,
  surah_id int not null references public.surahs (id) on delete cascade,
  order_index int not null,
  primary key (galaxy_id, surah_id)
);

create index if not exists galaxy_surahs_surah_idx
  on public.galaxy_surahs (surah_id);

create table if not exists public.surah_checkpoint_defs (
  surah_id int not null references public.surahs (id) on delete cascade,
  checkpoint_index int not null,
  from_ayah int not null,
  to_ayah int not null,
  order_index int not null,
  primary key (surah_id, checkpoint_index)
);

-- -----------------------------
-- Child map state
-- -----------------------------

create table if not exists public.child_surah_state (
  child_id uuid not null references public.children (id) on delete cascade,
  surah_id int not null references public.surahs (id) on delete cascade,
  status text not null default 'NOT_STARTED',
  active_slot int,
  started_at timestamptz,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint child_surah_state_status_check check (status in ('NOT_STARTED', 'ACTIVE', 'COMPLETED')),
  constraint child_surah_state_active_slot_check check (active_slot is null or (active_slot >= 1 and active_slot <= 3)),
  primary key (child_id, surah_id)
);

create index if not exists child_surah_state_child_status_idx
  on public.child_surah_state (child_id, status);

create table if not exists public.child_galaxy_state (
  child_id uuid not null references public.children (id) on delete cascade,
  galaxy_id int not null references public.galaxies (id) on delete cascade,
  unlocked boolean not null default false,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (child_id, galaxy_id)
);

create index if not exists child_galaxy_state_child_idx
  on public.child_galaxy_state (child_id);

-- -----------------------------
-- Level system (scaffold)
-- -----------------------------

create table if not exists public.levels (
  id uuid primary key default gen_random_uuid(),
  surah_id int not null references public.surahs (id) on delete cascade,
  type text not null,
  order_index int not null,
  ayah_id int,
  checkpoint_index int,
  config jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint levels_type_check check (type in ('SURAH_INTRO', 'VERSE_LESSON', 'CHECKPOINT', 'FINAL_EXAM')),
  constraint levels_unique_order unique (surah_id, order_index)
);

create index if not exists levels_surah_order_idx
  on public.levels (surah_id, order_index);

create index if not exists levels_surah_ayah_idx
  on public.levels (surah_id, ayah_id);

create table if not exists public.child_level_progress (
  child_id uuid not null references public.children (id) on delete cascade,
  level_id uuid not null references public.levels (id) on delete cascade,
  status text not null default 'LOCKED',
  attempts_today int not null default 0,
  attempts_date date,
  consecutive_fails int not null default 0,
  pass_count_total int not null default 0,
  locked_until timestamptz,
  last_score int,
  completed_at timestamptz,
  updated_at timestamptz not null default now(),
  constraint child_level_progress_status_check check (status in ('LOCKED', 'UNLOCKED', 'IN_PROGRESS', 'COMPLETED')),
  primary key (child_id, level_id)
);

create index if not exists child_level_progress_child_status_idx
  on public.child_level_progress (child_id, status);

create table if not exists public.level_attempts (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  level_id uuid not null references public.levels (id) on delete cascade,
  attempt_number_today int not null,
  score int not null,
  passed boolean not null,
  detailed_feedback_used boolean not null default false,
  mistake_type text,
  meta jsonb,
  created_at timestamptz not null default now()
);

create index if not exists level_attempts_child_date_idx
  on public.level_attempts (child_id, created_at);

-- -----------------------------
-- RLS policies (select-only; mutations happen via Edge Functions with service role)
-- -----------------------------

alter table public.child_surah_state enable row level security;
alter table public.child_galaxy_state enable row level security;
alter table public.child_level_progress enable row level security;
alter table public.level_attempts enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'child_surah_state' and policyname = 'parent_select_child_surah_state'
  ) then
    create policy parent_select_child_surah_state on public.child_surah_state
      for select
      using (
        exists (
          select 1 from public.children
          where children.id = child_surah_state.child_id
            and children.parent_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'child_galaxy_state' and policyname = 'parent_select_child_galaxy_state'
  ) then
    create policy parent_select_child_galaxy_state on public.child_galaxy_state
      for select
      using (
        exists (
          select 1 from public.children
          where children.id = child_galaxy_state.child_id
            and children.parent_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'child_level_progress' and policyname = 'parent_select_child_level_progress'
  ) then
    create policy parent_select_child_level_progress on public.child_level_progress
      for select
      using (
        exists (
          select 1 from public.children
          where children.id = child_level_progress.child_id
            and children.parent_id = auth.uid()
        )
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public' and tablename = 'level_attempts' and policyname = 'parent_select_level_attempts'
  ) then
    create policy parent_select_level_attempts on public.level_attempts
      for select
      using (
        exists (
          select 1 from public.children
          where children.id = level_attempts.child_id
            and children.parent_id = auth.uid()
        )
      );
  end if;
end $$;

-- -----------------------------
-- Seed: 6 galaxies + 38 surahs (metadata only)
-- -----------------------------

insert into public.galaxies (id, name_en, name_ar, order_index) values
  (1, 'Entry', 'سهل', 1),
  (2, 'Beginner', 'مبتدئ', 2),
  (3, 'Medium', 'متوسط', 3),
  (4, 'Growing', 'نامي', 4),
  (5, 'Advanced', 'متقدم', 5),
  (6, 'Master', 'إتقان', 6)
  on conflict (id) do nothing;

-- Surah reference rows (name is English; translation can be filled later).
-- NOTE: translation is required by schema; we use the name for now.
insert into public.surahs (id, name, translation, ayah_count, summary) values
  (114, 'An-Nas', 'An-Nas', 6, null),
  (113, 'Al-Falaq', 'Al-Falaq', 5, null),
  (103, 'Al-''Asr', 'Al-''Asr', 3, null),
  (108, 'Al-Kawthar', 'Al-Kawthar', 3, null),
  (110, 'An-Nasr', 'An-Nasr', 3, null),
  (111, 'Al-Masad', 'Al-Masad', 5, null),
  (105, 'Al-Fil', 'Al-Fil', 5, null),
  (106, 'Quraish', 'Quraish', 4, null),
  (109, 'Al-Kafirun', 'Al-Kafirun', 6, null),
  (97, 'Al-Qadr', 'Al-Qadr', 5, null),
  (107, 'Al-Ma''un', 'Al-Ma''un', 7, null),
  (95, 'At-Tin', 'At-Tin', 8, null),
  (94, 'Ash-Sharh', 'Ash-Sharh', 8, null),
  (99, 'Az-Zalzalah', 'Az-Zalzalah', 8, null),
  (102, 'At-Takathur', 'At-Takathur', 8, null),
  (98, 'Al-Bayyinah', 'Al-Bayyinah', 8, null),
  (104, 'Al-Humazah', 'Al-Humazah', 9, null),
  (93, 'Ad-Duha', 'Ad-Duha', 11, null),
  (100, 'Al-''Adiyat', 'Al-''Adiyat', 11, null),
  (101, 'Al-Qari''ah', 'Al-Qari''ah', 11, null),
  (91, 'Ash-Shams', 'Ash-Shams', 15, null),
  (86, 'At-Tariq', 'At-Tariq', 17, null),
  (96, 'Al-''Alaq', 'Al-''Alaq', 19, null),
  (82, 'Al-Infitar', 'Al-Infitar', 19, null),
  (87, 'Al-A''la', 'Al-A''la', 19, null),
  (90, 'Al-Balad', 'Al-Balad', 20, null),
  (92, 'Al-Lail', 'Al-Lail', 21, null),
  (85, 'Al-Buruj', 'Al-Buruj', 22, null),
  (84, 'Al-Inshiqaq', 'Al-Inshiqaq', 25, null),
  (88, 'Al-Ghashiyah', 'Al-Ghashiyah', 26, null),
  (81, 'At-Takwir', 'At-Takwir', 29, null),
  (89, 'Al-Fajr', 'Al-Fajr', 30, null),
  (83, 'Al-Mutaffifin', 'Al-Mutaffifin', 36, null),
  (78, 'An-Naba', 'An-Naba', 40, null),
  (80, '''Abasa', '''Abasa', 42, null),
  (79, 'An-Nazi''at', 'An-Nazi''at', 46, null)
  on conflict (id) do nothing;

-- Galaxy membership + ordering (difficulty progression) per PDF.
insert into public.galaxy_surahs (galaxy_id, surah_id, order_index) values
  (1, 1, 1),
  (1, 112, 2),
  (1, 114, 3),
  (1, 113, 4),
  (1, 103, 5),
  (1, 108, 6),
  (1, 110, 7),
  (2, 111, 1),
  (2, 105, 2),
  (2, 106, 3),
  (2, 109, 4),
  (2, 97, 5),
  (2, 107, 6),
  (3, 95, 1),
  (3, 94, 2),
  (3, 99, 3),
  (3, 102, 4),
  (3, 98, 5),
  (3, 104, 6),
  (4, 93, 1),
  (4, 100, 2),
  (4, 101, 3),
  (4, 91, 4),
  (4, 86, 5),
  (4, 96, 6),
  (5, 82, 1),
  (5, 87, 2),
  (5, 90, 3),
  (5, 92, 4),
  (5, 85, 5),
  (5, 84, 6),
  (5, 88, 7),
  (6, 81, 1),
  (6, 89, 2),
  (6, 83, 3),
  (6, 78, 4),
  (6, 80, 5),
  (6, 79, 6)
  on conflict (galaxy_id, surah_id) do nothing;

-- Seed level graph for currently playable surahs (1, 112).
-- Level ordering inserts checkpoint + final exam nodes aligned with existing mini quizzes.
insert into public.levels (surah_id, type, order_index, ayah_id, checkpoint_index, config) values
  (1, 'SURAH_INTRO', 1, null, null, null),
  (1, 'VERSE_LESSON', 2, 1, null, null),
  (1, 'VERSE_LESSON', 3, 2, null, null),
  (1, 'CHECKPOINT', 4, null, 1, '{"quiz_type":"mini_1"}'),
  (1, 'VERSE_LESSON', 5, 3, null, null),
  (1, 'VERSE_LESSON', 6, 4, null, null),
  (1, 'CHECKPOINT', 7, null, 2, '{"quiz_type":"mini_2"}'),
  (1, 'VERSE_LESSON', 8, 5, null, null),
  (1, 'VERSE_LESSON', 9, 6, null, null),
  (1, 'VERSE_LESSON', 10, 7, null, null),
  (1, 'FINAL_EXAM', 11, null, null, '{"quiz_type":"final"}'),

  (112, 'SURAH_INTRO', 1, null, null, null),
  (112, 'VERSE_LESSON', 2, 1, null, null),
  (112, 'VERSE_LESSON', 3, 2, null, null),
  (112, 'CHECKPOINT', 4, null, 1, '{"quiz_type":"mini_1"}'),
  (112, 'VERSE_LESSON', 5, 3, null, null),
  (112, 'VERSE_LESSON', 6, 4, null, null),
  (112, 'CHECKPOINT', 7, null, 2, '{"quiz_type":"mini_2"}'),
  (112, 'FINAL_EXAM', 8, null, null, '{"quiz_type":"final"}')
  on conflict (surah_id, order_index) do nothing;
