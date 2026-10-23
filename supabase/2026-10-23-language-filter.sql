-- Language filter for user-written text: usernames, About me, build names and descriptions.
-- Run once in the Supabase SQL Editor. Safe to re-run.
--
-- text_is_clean(t) normalises the text (lower-case, common letter/number substitutions, then
-- letters only) and refuses it if it contains any of the hard slurs below, or any of the
-- word-boundary terms as a whole word. The lists live only here, server side; the site just
-- shows the error. Edit the arrays to add or remove terms, then re-run this file.

create or replace function public.text_is_clean(t text) returns boolean
language plpgsql immutable as $$
declare
  squashed text;   -- letters only: catches "n i g g e r", "n1gg3r", "n.i.g.g.e.r"
  spaced   text;   -- lower-cased, substitutions applied, word boundaries kept
  w text;
  hard text[] := array[
    'nigger','nigga','niggur','negro','faggot','fagot','kike','kyke','wetback','spick','chink','gook',
    'raghead','towelhead','sandnigger','beaner','tranny','trannie','dyke','retard','retarded','zipperhead',
    'jigaboo','porchmonkey','coonass','muzzie','paki ','pakis','shemale','heeb','hymie','honky','honkey',
    'spearchucker','junglebunny','darkie','darky','golliwog','goyim'
  ];
  bounded text[] := array[
    'fag','fags','coon','coons','spic','spics','paki','jap','japs','kraut','krauts','gyp','gyps','gypped','abo','abos',
    'homo','homos','trap','slut','whore','cunt','rape','rapist','hitler','nazi','nazis','kkk'
  ];
begin
  if t is null or t = '' then return true; end if;
  spaced := lower(t);
  spaced := translate(spaced, '013457$@!|¡', 'oieastsaiil');
  spaced := regexp_replace(spaced, '[^a-z0-9 ]+', ' ', 'g');
  spaced := regexp_replace(spaced, '\s+', ' ', 'g');
  squashed := regexp_replace(spaced, '[^a-z]', '', 'g');
  foreach w in array hard loop
    if position(regexp_replace(w, '[^a-z]', '', 'g') in squashed) > 0 then return false; end if;
  end loop;
  foreach w in array bounded loop
    if spaced ~ ('(^| )' || w || '( |$)') then return false; end if;
  end loop;
  return true;
end $$;

create or replace function public.profiles_language_check() returns trigger
language plpgsql as $$
begin
  if not public.text_is_clean(new.display_name) or not public.text_is_clean(new.bio) then
    raise exception 'That text contains language that isn''t allowed here.';
  end if;
  return new;
end $$;
drop trigger if exists profiles_language_check_trg on public.profiles;
create trigger profiles_language_check_trg before insert or update on public.profiles
  for each row execute function public.profiles_language_check();

create or replace function public.builds_language_check() returns trigger
language plpgsql as $$
begin
  if not public.text_is_clean(new.name) or not public.text_is_clean(new.description) then
    raise exception 'That text contains language that isn''t allowed here.';
  end if;
  return new;
end $$;
drop trigger if exists builds_language_check_trg on public.builds;
create trigger builds_language_check_trg before insert or update on public.builds
  for each row execute function public.builds_language_check();
