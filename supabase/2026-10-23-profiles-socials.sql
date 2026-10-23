-- Optional Twitch / YouTube / Kick / Steam links on author pages (handles, entered on Edit Profile).
alter table public.profiles
  add column if not exists twitch  text,
  add column if not exists youtube text,
  add column if not exists kick    text,
  add column if not exists steam   text;

-- The language filter covers the new fields too.
create or replace function public.profiles_language_check() returns trigger
language plpgsql as $$
begin
  if not public.text_is_clean(new.display_name) or not public.text_is_clean(new.bio)
     or not public.text_is_clean(new.twitch) or not public.text_is_clean(new.youtube) or not public.text_is_clean(new.kick) or not public.text_is_clean(new.steam) then
    raise exception 'That text contains language that isn''t allowed here.';
  end if;
  return new;
end $$;
