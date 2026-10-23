-- Discord user id, stored when someone chooses to share their Discord profile (the icon links to discord.com/users/<id>).
alter table public.profiles add column if not exists discord_id text;
