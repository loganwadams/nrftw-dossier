-- Adds the optional Discord username to profiles (shown on the author page only when the user opts in).
alter table public.profiles add column if not exists discord_name text;
