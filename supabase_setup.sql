-- supabase_setup.sql
-- Run ONCE in the Supabase dashboard → SQL Editor, for project
-- "DhanvinPrakash's Project" (ref: zpfjunyokfujucdoqnwv).
--
-- Creates the `conditions` table used by the app's Conditions tab to store
-- team-added conditions (add + delete from the app), with row-level
-- security policies matching the app's publishable-key access.

create table if not exists public.conditions (
  id          uuid primary key default gen_random_uuid(),
  name        text        not null unique,
  description text        not null default '',
  procedures  text        not null default '',
  roles       jsonb       not null default '[]'::jsonb,
  created_at  timestamptz not null default now()
);

alter table public.conditions enable row level security;

-- The app talks to Supabase with the publishable (anon) key and has no
-- Supabase user accounts, so these policies are intentionally open for
-- this closed hospital deployment. If the project is ever exposed
-- publicly, tighten them (e.g. authenticated-only) in the dashboard.
drop policy if exists "conditions_anon_all" on public.conditions;
create policy "conditions_anon_all"
  on public.conditions
  for all
  using (true)
  with check (true);
