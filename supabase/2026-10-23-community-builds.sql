-- Community builds: lets a saved build be published for everyone to browse.
-- Run once in the Supabase dashboard: SQL Editor -> New query -> paste -> Run.
-- Safe to re-run (every step checks whether it already exists).
--
-- What it adds:
--   builds.is_public / description / author_name / published_at  - the publish switch and its blurb
--   build_likes   - one like per signed-in user per build
--   build_reports - "report this build" (only readable from the dashboard, never from the site)
--   community_builds (view) - what the site's Community page reads: public builds + like counts
--   row-level security: anyone can READ public builds; only the owner can change theirs.

-- 1. Publish fields on the existing builds table
alter table public.builds
  add column if not exists is_public    boolean     not null default false,
  add column if not exists description  text,
  add column if not exists author_name  text,
  add column if not exists published_at timestamptz;

create index if not exists builds_public_idx on public.builds (published_at desc) where is_public;

-- 2. Likes and reports. builds.id's type (uuid or bigint) is looked up so the new tables match it.
do $$
declare idtype text;
begin
  select format_type(a.atttypid, a.atttypmod) into idtype
    from pg_attribute a where a.attrelid = 'public.builds'::regclass and a.attname = 'id';

  execute format($f$
    create table if not exists public.build_likes (
      build_id   %s not null references public.builds(id) on delete cascade,
      user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
      created_at timestamptz not null default now(),
      primary key (build_id, user_id)
    )$f$, idtype);

  execute format($f$
    create table if not exists public.build_reports (
      id         bigint generated always as identity primary key,
      build_id   %s not null references public.builds(id) on delete cascade,
      user_id    uuid default auth.uid(),
      reason     text,
      created_at timestamptz not null default now()
    )$f$, idtype);
end $$;

alter table public.build_likes   enable row level security;
alter table public.build_reports enable row level security;

-- 3. Row-level security
drop policy if exists "public builds are readable by anyone" on public.builds;
create policy "public builds are readable by anyone"
  on public.builds for select using (is_public);

drop policy if exists "likes are readable by anyone" on public.build_likes;
create policy "likes are readable by anyone"
  on public.build_likes for select using (true);
drop policy if exists "signed-in users can like" on public.build_likes;
create policy "signed-in users can like"
  on public.build_likes for insert with check (auth.uid() = user_id);
drop policy if exists "users can remove their own like" on public.build_likes;
create policy "users can remove their own like"
  on public.build_likes for delete using (auth.uid() = user_id);

drop policy if exists "signed-in users can report" on public.build_reports;
create policy "signed-in users can report"
  on public.build_reports for insert with check (auth.uid() is not null);
-- (no select policy on build_reports on purpose: only the dashboard can read reports)

-- 4. What the Community page reads
create or replace view public.community_builds
  with (security_invoker = true) as
  select b.id, b.name, b.code, b.description, b.author_name, b.published_at, b.updated_at,
         (select count(*) from public.build_likes l where l.build_id = b.id) as likes
    from public.builds b
   where b.is_public;

grant select on public.community_builds to anon, authenticated;
grant select, insert, delete on public.build_likes to authenticated;
grant select on public.build_likes to anon;
grant insert on public.build_reports to authenticated;
-- Anonymous visitors need table-level SELECT for the security_invoker view to work;
-- the "public builds are readable by anyone" policy still limits them to is_public rows.
grant select on public.builds to anon;
