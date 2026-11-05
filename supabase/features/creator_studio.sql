-- Creator enrollment, private selfies and prospective qualified-view estimates.
create table public.cineo_creator_accounts (
 user_id uuid primary key references auth.users(id) on delete cascade,
 first_name text not null check(length(first_name) between 2 and 60),
 last_name text not null check(length(last_name) between 2 and 100),
 birth_date date not null,
 status text not null default 'pending' check(status in ('pending','approved','banned','withdrawn')),
 selfie_path text, consent_at timestamptz not null default now(),
 submitted_at timestamptz not null default now(), eligible_at timestamptz not null default now()+interval '1 minute',
 approved_at timestamptz, reason text not null default '', updated_at timestamptz not null default now()
);
create table public.cineo_creator_events (
 id bigint generated always as identity primary key, creator_id uuid not null references auth.users(id) on delete cascade,
 actor_id uuid references auth.users(id) on delete set null, action text not null, reason text not null default '', created_at timestamptz not null default now()
);
create index cineo_creator_events_owner_idx on public.cineo_creator_events(creator_id,created_at desc);
create table public.cineo_view_sessions (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references auth.users(id) on delete cascade,
 episode_id bigint not null references public.cineo_episodes(id) on delete cascade,
 created_at timestamptz not null default now(), last_at timestamptz not null default now(),
 position_ms integer not null default 0, reported_ms integer not null default 0, watched_ms integer not null default 0, credited boolean not null default false
);
create index cineo_view_session_actor_idx on public.cineo_view_sessions(user_id,created_at desc);
create table public.cineo_qualified_views (
 user_id uuid not null references auth.users(id) on delete cascade,
 episode_id bigint not null references public.cineo_episodes(id) on delete cascade,
 show_id bigint not null references public.cineo_shows(id) on delete cascade,
 creator_id uuid not null references auth.users(id) on delete cascade,
 day date not null default (now() at time zone 'America/Sao_Paulo')::date,
 rate_cents_per_thousand integer not null default 0, created_at timestamptz not null default now(),
 primary key(user_id,episode_id,day)
);
create index cineo_qualified_creator_idx on public.cineo_qualified_views(creator_id,created_at desc);
create index cineo_qualified_show_idx on public.cineo_qualified_views(show_id);
alter table public.cineo_creator_accounts enable row level security;
alter table public.cineo_creator_events enable row level security;
alter table public.cineo_view_sessions enable row level security;
alter table public.cineo_qualified_views enable row level security;
revoke all on public.cineo_creator_accounts,public.cineo_creator_events,public.cineo_view_sessions,public.cineo_qualified_views from public,anon,authenticated;
grant all on public.cineo_creator_accounts,public.cineo_creator_events,public.cineo_view_sessions,public.cineo_qualified_views to service_role;
grant usage,select on sequence public.cineo_creator_events_id_seq to service_role;
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('cineo-creator-private','cineo-creator-private',false,1048576,array['image/jpeg']) on conflict(id) do nothing;

create function public.cineo_creator_transition(target uuid,actor uuid,decision text,note text default '') returns jsonb language plpgsql security invoker set search_path='' as $$
declare r public.cineo_creator_accounts;begin
 select * into r from public.cineo_creator_accounts where user_id=target for update;
 if not found then return null;end if;
 if decision='auto' then
  if r.status<>'pending' or r.eligible_at>now() then return to_jsonb(r)-'selfie_path';end if;
  update public.cineo_creator_accounts set status='approved',approved_at=now(),updated_at=now() where user_id=target;
 elsif decision in ('ban','restore') then
  if not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Acesso restrito';end if;
  if decision='ban' and length(trim(note))<5 then raise exception 'Informe o motivo';end if;
  update public.cineo_creator_accounts set status=case when decision='ban' then 'banned' else 'approved' end,reason=left(note,1000),approved_at=case when decision='restore' then now() else approved_at end,updated_at=now() where user_id=target;
 else raise exception 'Ação inválida';end if;
 insert into public.cineo_creator_events(creator_id,actor_id,action,reason) values(target,actor,decision,left(note,1000));
 return (select to_jsonb(c)-'selfie_path' from public.cineo_creator_accounts c where user_id=target);
end $$;

create function public.cineo_view_heartbeat(actor uuid,session uuid,pos integer,active_ms integer) returns jsonb language plpgsql security invoker set search_path='' as $$
declare r public.cineo_view_sessions;e public.cineo_episodes;s public.cineo_shows;delta integer;threshold integer;rate integer:=0;added integer;begin
 select * into r from public.cineo_view_sessions where id=session and user_id=actor for update;
 if not found or r.created_at<now()-interval '2 hours' then raise exception 'Sessão de vídeo indisponível';end if;
 select * into e from public.cineo_episodes where id=r.episode_id;
 select * into s from public.cineo_shows where id=e.show_id;
 if s.status<>'approved' or s.hidden or e.hidden or e.review_status<>'approved' or e.media_state='failed' or s.premiere_at>now() or e.release_at>now() or s.owner_id=actor then return jsonb_build_object('credited',false);end if;
 if pos<0 or pos>14400000 or active_ms<0 or active_ms>14400000 then raise exception 'Posição inválida';end if;
 delta:=greatest(0,least(15000,(extract(epoch from now()-r.last_at)*1000)::integer,pos-r.position_ms,active_ms-r.reported_ms));
 threshold:=case when e.duration_seconds>0 then least(10000,greatest(1000,e.duration_seconds*800)) else 10000 end;
 update public.cineo_view_sessions set watched_ms=watched_ms+delta,position_ms=pos,reported_ms=greatest(reported_ms,active_ms),last_at=now() where id=session;
 if not r.credited and r.watched_ms+delta>=threshold then
  if exists(select 1 from public.cineo_creator_accounts where user_id=s.owner_id and status='approved') then rate:=40;end if;
  insert into public.cineo_qualified_views(user_id,episode_id,show_id,creator_id,rate_cents_per_thousand) values(actor,e.id,s.id,s.owner_id,rate) on conflict do nothing;
  get diagnostics added=row_count;
  update public.cineo_view_sessions set credited=true where id=session;
  return jsonb_build_object('credited',true,'new_view',added=1);
 end if;
 return jsonb_build_object('credited',r.credited);
end $$;

create function public.cineo_creator_metrics(actor uuid) returns jsonb language sql stable security invoker set search_path='' as $$
select jsonb_build_object('views',(select count(*) from public.cineo_qualified_views where creator_id=actor),'followers',(select count(*) from public.cineo_follows where kind='creator' and target=actor::text and user_id<>actor),'estimated_cents',(select coalesce(sum(rate_cents_per_thousand),0)/1000.0 from public.cineo_qualified_views where creator_id=actor),'rate_cents_per_thousand',40,'items',(select coalesce(jsonb_agg(x),'[]') from (select s.id,s.title,s.status,count(v.episode_id) as views,coalesce(sum(v.rate_cents_per_thousand),0)/1000.0 as estimated_cents from public.cineo_shows s left join public.cineo_qualified_views v on v.show_id=s.id where s.owner_id=actor group by s.id order by count(v.episode_id) desc)x));$$;
create function public.cineo_public_views(ids bigint[]) returns jsonb language sql stable security invoker set search_path='' as $$select coalesce(jsonb_agg(x),'[]') from (select show_id,count(*) as views from public.cineo_qualified_views where show_id=any(ids) group by show_id)x;$$;
revoke all on function public.cineo_creator_transition(uuid,uuid,text,text),public.cineo_view_heartbeat(uuid,uuid,integer,integer),public.cineo_creator_metrics(uuid),public.cineo_public_views(bigint[]) from public,anon,authenticated;
grant execute on function public.cineo_creator_transition(uuid,uuid,text,text),public.cineo_view_heartbeat(uuid,uuid,integer,integer),public.cineo_creator_metrics(uuid),public.cineo_public_views(bigint[]) to service_role;
