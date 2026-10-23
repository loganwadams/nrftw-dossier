-- Profile picture from the sign-in provider (Google / Discord), stored so others can see it on the author page.
alter table public.profiles add column if not exists avatar_url text;
