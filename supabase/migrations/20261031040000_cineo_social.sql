create table public.cineo_likes (
 episode_id bigint not null references public.cineo_episodes(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(episode_id,user_id));
create index cineo_likes_user_idx on public.cineo_likes(user_id);
create table public.cineo_saved (
 user_id uuid not null references auth.users(id) on delete cascade,
 show_id bigint not null references public.cineo_shows(id) on delete cascade,
 created_at timestamptz not null default now(), primary key(user_id,show_id));
create index cineo_saved_show_idx on public.cineo_saved(show_id);
create table public.cineo_comments (
 id bigint generated always as identity primary key,
 episode_id bigint not null references public.cineo_episodes(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 author_name text not null check(char_length(btrim(author_name)) between 1 and 60),
 body text not null check(char_length(btrim(body)) between 1 and 1000),
 created_at timestamptz not null default now());
create index cineo_comments_episode_idx on public.cineo_comments(episode_id,id desc);
create index cineo_comments_user_idx on public.cineo_comments(user_id,created_at desc);
alter table public.cineo_likes enable row level security;
alter table public.cineo_saved enable row level security;
alter table public.cineo_comments enable row level security;
-- Only the authenticated Edge API accesses social data; browser/mobile roles have no table privileges.
revoke all on public.cineo_likes,public.cineo_saved,public.cineo_comments from anon,authenticated;
grant all on public.cineo_likes,public.cineo_saved,public.cineo_comments to service_role;
grant usage,select on sequence public.cineo_comments_id_seq to service_role;
