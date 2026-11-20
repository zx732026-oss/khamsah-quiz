-- خمشه كويز: الجداول الأولية
-- شغّل هذا الملف من Supabase > SQL Editor > New query.
-- لا تضع مفاتيح سرية داخل هذا الملف.

create extension if not exists pgcrypto;

create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  is_published boolean not null default false,
  owner_id uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  question_text text not null,
  options jsonb not null default '[]'::jsonb,
  correct_answer integer not null default 0,
  points integer not null default 1,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.sessions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  join_token text not null unique default encode(gen_random_bytes(6), 'hex'),
  status text not null default 'waiting'
    check (status in ('waiting', 'active', 'finished')),
  created_at timestamptz not null default now()
);

create table if not exists public.players (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.sessions(id) on delete cascade,
  display_name text not null,
  score integer not null default 0,
  joined_at timestamptz not null default now()
);

create table if not exists public.answers (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.players(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  selected_answer integer not null,
  is_correct boolean,
  answered_at timestamptz not null default now(),
  unique (player_id, question_id)
);

create index if not exists questions_quiz_sort_idx
  on public.questions (quiz_id, sort_order);
create index if not exists players_session_idx
  on public.players (session_id);
create index if not exists answers_player_idx
  on public.answers (player_id);

alter table public.quizzes enable row level security;
alter table public.questions enable row level security;
alter table public.sessions enable row level security;
alter table public.players enable row level security;
alter table public.answers enable row level security;

-- سياسات آمنة كبداية: لا وصول عام مباشر إلى بيانات الجداول.
-- سنضيف سياسات محددة أو Edge Functions عند تنفيذ الدخول واللعب الجماعي.
