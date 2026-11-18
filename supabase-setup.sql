-- Otolith Isles: database setup (separate tables + accounts from Starlung).
-- Paste ALL of this into Supabase > SQL Editor > New query > Run.

-- 1) Each player's save (only that player can read/write it)
create table if not exists public.oto_saves (
  user_id uuid primary key references auth.users(id) on delete cascade,
  state jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.oto_saves enable row level security;
drop policy if exists "oto own read" on public.oto_saves;
drop policy if exists "oto own insert" on public.oto_saves;
drop policy if exists "oto own update" on public.oto_saves;
create policy "oto own read"   on public.oto_saves for select to authenticated using (auth.uid() = user_id);
create policy "oto own insert" on public.oto_saves for insert to authenticated with check (auth.uid() = user_id);
create policy "oto own update" on public.oto_saves for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 2) Leaderboard (everyone can read; each player writes only their own row)
create table if not exists public.oto_board (
  user_id uuid primary key references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 24),
  earned integer not null default 0 check (earned >= 0 and earned < 10000000),
  lv integer not null default 1,
  mastered integer not null default 0,
  ans integer not null default 0,
  acc integer not null default 0,
  bosses integer not null default 0,
  eq jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now()
);
alter table public.oto_board enable row level security;
drop policy if exists "oto board read" on public.oto_board;
drop policy if exists "oto board insert own" on public.oto_board;
drop policy if exists "oto board update own" on public.oto_board;
create policy "oto board read"       on public.oto_board for select to anon, authenticated using (true);
create policy "oto board insert own" on public.oto_board for insert to authenticated with check (auth.uid() = user_id);
create policy "oto board update own" on public.oto_board for update to authenticated using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- 3) Live leaderboard updates
do $$ begin
  alter publication supabase_realtime add table public.oto_board;
exception when duplicate_object then null; end $$;
