-- Optional Reddit link on author pages.
alter table public.profiles add column if not exists reddit text;

create or replace function public.profiles_language_check() returns trigger
language plpgsql as $$
begin
  if not public.text_is_clean(new.display_name) or not public.text_is_clean(new.bio)
     or not public.text_is_clean(new.twitch) or not public.text_is_clean(new.youtube)
     or not public.text_is_clean(new.kick) or not public.text_is_clean(new.steam)
     or not public.text_is_clean(new.reddit) then
    raise exception 'That text contains language that isn''t allowed here.';
  end if;
  return new;
end $$;
