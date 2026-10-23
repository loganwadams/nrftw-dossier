-- Usernames are registered once at first sign-in and must be unique (case-insensitive).
create unique index if not exists profiles_username_key on public.profiles (lower(display_name));
