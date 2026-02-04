-- Phase 1 backend foundations: progress/attempts/sessions/streaks

create table if not exists public.surah_progress (
  child_id uuid not null references public.children (id) on delete cascade,
  surah_id int not null,
  stage text not null default 'LEARN_1_2',
  unlocked_ayah_max int not null default 1,
  mini_quiz_1_passed_at timestamptz,
  mini_quiz_2_passed_at timestamptz,
  final_exam_passed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint surah_progress_stage_check check (
    stage in (
      'LEARN_1_2',
      'MINI_QUIZ_1',
      'LEARN_3_4',
      'MINI_QUIZ_2',
      'LEARN_REST',
      'FINAL_EXAM',
      'COMPLETED'
    )
  ),
  primary key (child_id, surah_id)
);

create table if not exists public.ayah_progress (
  child_id uuid not null references public.children (id) on delete cascade,
  surah_id int not null,
  ayah_id int not null,
  pass_count_total int not null default 0,
  attempts_today int not null default 0,
  attempts_date date,
  consecutive_fails int not null default 0,
  mastered_at timestamptz,
  locked_until timestamptz,
  last_score int,
  updated_at timestamptz not null default now(),
  primary key (child_id, surah_id, ayah_id)
);

create table if not exists public.recitation_attempts (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  surah_id int not null,
  ayah_id int not null,
  attempt_number_today int not null,
  score int not null,
  passed boolean not null,
  detailed_feedback_used boolean not null default false,
  mistake_type text,
  audio_path text not null,
  transcript text,
  meta jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  surah_id int not null,
  quiz_type text not null,
  attempt_number int not null,
  score int not null,
  passed boolean not null,
  details jsonb,
  created_at timestamptz not null default now(),
  constraint quiz_attempts_type_check check (quiz_type in ('mini_1', 'mini_2', 'final'))
);

create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.children (id) on delete cascade,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  counted boolean not null default false
);

create table if not exists public.streaks (
  child_id uuid primary key references public.children (id) on delete cascade,
  current_streak int not null default 0,
  best_streak int not null default 0,
  last_practice_date date
);

create index if not exists recitation_attempts_child_date_idx
  on public.recitation_attempts (child_id, created_at);

create index if not exists quiz_attempts_child_date_idx
  on public.quiz_attempts (child_id, created_at);

alter table public.surah_progress enable row level security;
alter table public.ayah_progress enable row level security;
alter table public.recitation_attempts enable row level security;
alter table public.quiz_attempts enable row level security;
alter table public.sessions enable row level security;
alter table public.streaks enable row level security;

create policy "parent_select_surah_progress" on public.surah_progress
  for select
  using (
    exists (
      select 1
      from public.children
      where children.id = surah_progress.child_id
        and children.parent_id = auth.uid()
    )
  );

create policy "parent_select_ayah_progress" on public.ayah_progress
  for select
  using (
    exists (
      select 1
      from public.children
      where children.id = ayah_progress.child_id
        and children.parent_id = auth.uid()
    )
  );

create policy "parent_select_recitation_attempts" on public.recitation_attempts
  for select
  using (
    exists (
      select 1
      from public.children
      where children.id = recitation_attempts.child_id
        and children.parent_id = auth.uid()
    )
  );

create policy "parent_insert_recitation_attempts" on public.recitation_attempts
  for insert
  with check (
    exists (
      select 1
      from public.children
      where children.id = recitation_attempts.child_id
        and children.parent_id = auth.uid()
    )
  );

create policy "parent_select_quiz_attempts" on public.quiz_attempts
  for select
  using (
    exists (
      select 1
      from public.children
      where children.id = quiz_attempts.child_id
        and children.parent_id = auth.uid()
    )
  );

create policy "parent_select_sessions" on public.sessions
  for select
  using (
    exists (
      select 1
      from public.children
      where children.id = sessions.child_id
        and children.parent_id = auth.uid()
    )
  );

create policy "parent_select_streaks" on public.streaks
  for select
  using (
    exists (
      select 1
      from public.children
      where children.id = streaks.child_id
        and children.parent_id = auth.uid()
    )
  );
