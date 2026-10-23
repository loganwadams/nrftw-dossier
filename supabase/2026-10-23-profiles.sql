-- Author profiles for Community Builds. Run once in the Supabase dashboard: SQL Editor -> paste -> Run.
-- Safe to re-run.
--
--   profiles  - one optional row per signed-in user: display name, short bio, and is_public.
--               No row = treated as public. Private hides the author link on their builds.
--   community_builds (view) - gains user_id (only when the author's profile is public) and
--               profile_public, so the site can link a build to its author's page.

create table if not exists public.profiles (
  user_id      uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  display_name text,
  bio          text,
  is_public    boolean not null default true,
  updated_at   timestamptz not null default now()
);
alter table public.profiles enable row level security;

drop policy if exists "public profiles are readable by anyone" on public.profiles;
create policy "public profiles are readable by anyone"
  on public.profiles for select using (is_public or auth.uid() = user_id);
drop policy if exists "users can create their own profile" on public.profiles;
create policy "users can create their own profile"
  on public.profiles for insert with check (auth.uid() = user_id);
drop policy if exists "users can update their own profile" on public.profiles;
create policy "users can update their own profile"
  on public.profiles for update using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select on public.profiles to anon, authenticated;
grant insert, update on public.profiles to authenticated;

-- Rebuild the view with the author columns. The builds table's owner column is looked up by
-- name so this works whatever it was called when the table was created.
do $$
declare owner_col text;
begin
  select column_name into owner_col
    from information_schema.columns
   where table_schema = 'public' and table_name = 'builds'
     and data_type = 'uuid' and column_name in ('user_id','owner_id','owner','uid','user','author_id','created_by')
   order by case column_name when 'user_id' then 0 else 1 end
   limit 1;
  if owner_col is null then
    raise exception 'builds: could not find the owner (uuid) column';
  end if;

  execute format($v$
    create or replace view public.community_builds
      with (security_invoker = true) as
      select b.id, b.name, b.code, b.description, b.author_name, b.published_at, b.updated_at,
             (select count(*) from public.build_likes l where l.build_id = b.id) as likes,
             case when coalesce(p.is_public, true) then b.%1$I end as user_id,
             coalesce(p.is_public, true) as profile_public
        from public.builds b
        left join public.profiles p on p.user_id = b.%1$I
       where b.is_public
  $v$, owner_col);
end $$;

grant select on public.community_builds to anon, authenticated;
