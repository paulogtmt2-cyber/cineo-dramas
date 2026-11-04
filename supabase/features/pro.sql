alter table public.cineo_shows add column premiere_at timestamptz, add column trailer_path text not null default '', add column hidden boolean not null default false;
alter table public.cineo_episodes add column season integer not null default 1 check(season between 1 and 1000), add column episode_number integer not null default 1 check(episode_number between 1 and 10000), add column duration_seconds integer not null default 0 check(duration_seconds between 0 and 14400), add column review_status text not null default 'approved' check(review_status in ('draft','pending','approved','rejected')), add column review_reason text not null default '', add column low_path text not null default '', add column subtitles text not null default '', add column hidden boolean not null default false;
-- Preserve the historical episode order while assigning chapter numbers.
with numbered as (select id,row_number() over(partition by show_id order by id) as n from public.cineo_episodes) update public.cineo_episodes e set episode_number=n.n from numbered n where e.id=n.id;
alter table public.cineo_comments add column parent_id bigint references public.cineo_comments(id), add column spoiler boolean not null default false, add column hidden boolean not null default false;
create index cineo_comments_parent_idx on public.cineo_comments(parent_id);
create table public.cineo_profiles(user_id uuid primary key references auth.users(id) on delete cascade,name text not null check(char_length(name) between 1 and 60),bio text not null default '' check(char_length(bio)<=500),avatar text not null default '' check(char_length(avatar)<=180000));
create table public.cineo_follows(user_id uuid not null references auth.users(id) on delete cascade,kind text not null check(kind in ('show','creator')),target text not null,created_at timestamptz not null default now(),primary key(user_id,kind,target));
create index cineo_follows_target_idx on public.cineo_follows(kind,target);
create table public.cineo_progress(user_id uuid not null references auth.users(id) on delete cascade,episode_id bigint not null references public.cineo_episodes(id) on delete cascade,position_ms integer not null check(position_ms>=0),duration_ms integer not null check(duration_ms between 1 and 14400000),completed boolean not null default false,updated_at timestamptz not null default now(),primary key(user_id,episode_id),check(position_ms<=duration_ms));
create index cineo_progress_episode_idx on public.cineo_progress(episode_id);
create table public.cineo_notifications(user_id uuid not null references auth.users(id) on delete cascade,episode_id bigint not null references public.cineo_episodes(id) on delete cascade,read boolean not null default false,created_at timestamptz not null default now(),primary key(user_id,episode_id));
create index cineo_notifications_episode_idx on public.cineo_notifications(episode_id);
create table public.cineo_comment_likes(user_id uuid not null references auth.users(id) on delete cascade,comment_id bigint not null references public.cineo_comments(id) on delete cascade,primary key(user_id,comment_id));
create index cineo_comment_likes_comment_idx on public.cineo_comment_likes(comment_id);
create table public.cineo_reports(id bigint generated always as identity primary key,user_id uuid not null references auth.users(id) on delete cascade,kind text not null check(kind in ('show','episode','comment')),target_id bigint not null,reason text not null check(char_length(btrim(reason)) between 3 and 1000),status text not null default 'open' check(status in ('open','resolved','dismissed')),created_at timestamptz not null default now());
create index cineo_reports_status_idx on public.cineo_reports(status,id desc);
create index cineo_reports_user_idx on public.cineo_reports(user_id);
create table public.cineo_editorial(id integer primary key check(id=1),featured_id bigint references public.cineo_shows(id),updated_at timestamptz not null default now());
insert into public.cineo_editorial(id) values(1);
create table public.cineo_collections(id bigint generated always as identity primary key,title text not null check(char_length(btrim(title)) between 1 and 80),show_ids bigint[] not null default '{}',position integer not null default 0,active boolean not null default true);
do $$ declare t text; begin foreach t in array array['cineo_profiles','cineo_follows','cineo_progress','cineo_notifications','cineo_comment_likes','cineo_reports','cineo_editorial','cineo_collections'] loop execute format('alter table public.%I enable row level security',t);execute format('revoke all on public.%I from anon, authenticated',t);execute format('grant all on public.%I to service_role',t);end loop;end $$;
grant usage,select on sequence public.cineo_reports_id_seq,public.cineo_collections_id_seq to service_role;
-- Episode upload is atomic with the publication state check. Only the server can invoke it.
create function public.cineo_pro_episode(actor uuid,sid bigint,episode_title text,object_path text,season_number integer,chapter_number integer,seconds integer) returns bigint language plpgsql security invoker set search_path='' as $$
declare s public.cineo_shows;eid bigint;
begin select * into s from public.cineo_shows where id=sid for update;
if s.id is null or s.owner_id<>actor or s.status='pending' then raise exception 'Envio não permitido.';end if;
insert into public.cineo_episodes(show_id,title,storage_path,season,episode_number,duration_seconds,review_status) values(sid,episode_title,object_path,season_number,chapter_number,seconds,case when s.status='approved' then 'draft' else 'approved' end) returning id into eid;
return eid;end $$;
revoke all on function public.cineo_pro_episode(uuid,bigint,text,text,integer,integer,integer) from public,anon,authenticated;
grant execute on function public.cineo_pro_episode(uuid,bigint,text,text,integer,integer,integer) to service_role;
