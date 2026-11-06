alter table public.cineo_profiles add column username text;
alter table public.cineo_profiles add column bio_link text not null default '';
update public.cineo_profiles set username='cineo_'||substr(replace(user_id::text,'-',''),1,18);
alter table public.cineo_profiles add constraint cineo_username_format check(username ~ '^[a-z0-9_][a-z0-9_.]{2,23}$');
create unique index cineo_username_unique_idx on public.cineo_profiles(lower(username));
create function public.cineo_profile_username() returns trigger language plpgsql security invoker set search_path='' as $$begin if new.username is null then new.username:='cineo_'||substr(replace(new.user_id::text,'-',''),1,18);end if;return new;end$$;
create trigger cineo_profile_username before insert on public.cineo_profiles for each row execute function public.cineo_profile_username();
create table public.cineo_profile_posts(id uuid primary key default gen_random_uuid(),user_id uuid not null references auth.users(id) on delete cascade,client_id uuid not null,body text not null check(length(trim(body)) between 1 and 2000),show_id bigint references public.cineo_shows(id) on delete set null,status text not null default 'pending' check(status in('pending','approved','rejected','removed')),reason text not null default '',created_at timestamptz not null default now(),reviewed_at timestamptz,reviewed_by uuid references auth.users(id) on delete set null,unique(user_id,client_id));
create index cineo_posts_owner_idx on public.cineo_profile_posts(user_id,created_at desc);
create index cineo_posts_queue_idx on public.cineo_profile_posts(status,created_at);
alter table public.cineo_profile_posts enable row level security;
revoke all on public.cineo_profile_posts from public,anon,authenticated;
grant all on public.cineo_profile_posts to service_role;
create function public.cineo_profile_counts(owner uuid) returns jsonb language sql stable security invoker set search_path='' as $$select jsonb_build_object('followers',(select count(*) from public.cineo_follows where kind='creator' and target=owner::text and user_id<>owner),'following_count',(select count(*) from public.cineo_follows where kind='creator' and user_id=owner and target<>owner::text),'posts_count',(select count(*) from public.cineo_profile_posts where user_id=owner and status='approved'))$$;
create function public.cineo_profile_follow(actor uuid,target uuid,enabled boolean) returns jsonb language plpgsql security invoker set search_path='' as $$begin
 if actor=target then raise exception 'Você não pode seguir seu próprio perfil';end if;
 if enabled then
 if not exists(select 1 from public.cineo_profiles where user_id=target) and not exists(select 1 from public.cineo_shows where owner_id=target and status='approved' and not hidden and(premiere_at is null or premiere_at<=now())) then raise exception 'Perfil indisponível';end if;
 if exists(select 1 from public.cineo_blocks where (user_id=actor and target_id=target) or(user_id=target and target_id=actor)) then raise exception 'Perfil indisponível';end if;
 insert into public.cineo_follows(user_id,kind,target) values(actor,'creator',target::text) on conflict do nothing;
 else delete from public.cineo_follows where user_id=actor and kind='creator' and cineo_follows.target=cineo_profile_follow.target::text;end if;
 return public.cineo_profile_counts(target)||jsonb_build_object('following',exists(select 1 from public.cineo_follows where user_id=actor and kind='creator' and cineo_follows.target=cineo_profile_follow.target::text));
end$$;
create function public.cineo_profile_people(actor uuid,owner uuid,direction text,skip integer) returns jsonb language sql stable security invoker set search_path='' as $$with people as(select case when direction='followers' then f.user_id::text else f.target end as id,f.created_at from public.cineo_follows f where f.kind='creator' and f.target<>f.user_id::text and ((direction='followers' and f.target=owner::text)or(direction='following' and f.user_id=owner))) select coalesce(jsonb_agg(x),'[]') from(select p.user_id,p.name,p.username,p.avatar,p.verified from people x join public.cineo_profiles p on p.user_id::text=x.id where not exists(select 1 from public.cineo_blocks b where(b.user_id=actor and b.target_id=p.user_id)or(b.user_id=p.user_id and b.target_id=actor)) order by x.created_at desc,p.user_id offset greatest(0,skip) limit 21)x$$;
create function public.cineo_profile_post(actor uuid,client uuid,content text,series bigint) returns jsonb language plpgsql security invoker set search_path='' as $$declare out_id uuid;begin
 if not exists(select 1 from public.cineo_creator_accounts where user_id=actor and status='approved') and not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Ative seu cadastro de criador para publicar posts';end if;
 if length(trim(content)) not between 1 and 2000 or client is null then raise exception 'Escreva um post de até 2000 caracteres';end if;
 if series is not null and not exists(select 1 from public.cineo_shows where id=series and owner_id=actor and status='approved' and not hidden and(premiere_at is null or premiere_at<=now())) then raise exception 'Escolha uma série sua já publicada';end if;
 insert into public.cineo_profile_posts(user_id,client_id,body,show_id) values(actor,client,trim(content),series) on conflict(user_id,client_id) do nothing returning id into out_id;
 if out_id is null then select id into out_id from public.cineo_profile_posts where user_id=actor and client_id=client;end if;
 return jsonb_build_object('ok',true,'id',out_id,'message','Post enviado para análise');
end$$;
create function public.cineo_review_profile_post(actor uuid,post uuid,decision text,note text) returns jsonb language plpgsql security invoker set search_path='' as $$declare owner uuid;begin
 if not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Acesso restrito';end if;
 if decision not in('approved','rejected') or(decision='rejected' and coalesce(length(trim(note)),0)<3) then raise exception 'Informe a decisão e o motivo';end if;
 update public.cineo_profile_posts set status=decision,reason=left(coalesce(note,''),2000),reviewed_by=actor,reviewed_at=now() where id=post and status='pending' returning user_id into owner;
 if owner is null then raise exception 'Este post já recebeu uma decisão';end if;
 insert into public.cineo_admin_history(actor_id,action,target,detail) values(actor,'profile_post_'||decision,post::text,jsonb_build_object('reason',left(coalesce(note,''),2000)));
 return jsonb_build_object('ok',true);
end$$;
do $$declare p record;begin for p in select oid::regprocedure signature from pg_proc where pronamespace='public'::regnamespace and proname in('cineo_profile_username','cineo_profile_counts','cineo_profile_follow','cineo_profile_people','cineo_profile_post','cineo_review_profile_post') loop execute format('revoke all on function %s from public,anon,authenticated',p.signature);execute format('grant execute on function %s to service_role',p.signature);end loop;end$$;
