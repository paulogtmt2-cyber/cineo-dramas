-- Money is stored in integer centavos; rewards never create views or social accounts.
create table public.cineo_mission_program(id integer primary key check(id=1),enabled boolean not null default true,first_cents integer not null default 150 check(first_cents between 0 and 100000),episode_cents integer not null default 1 check(episode_cents between 0 and 10000),budget_cents bigint check(budget_cents>=0),revision integer not null default 1,updated_at timestamptz not null default now());
insert into public.cineo_mission_program(id) values(1);
create table public.cineo_mission_members(creator_id uuid primary key references auth.users(id) on delete cascade,joined_at timestamptz not null default now(),first_eligible boolean not null);
create table public.cineo_mission_entries(show_id bigint primary key references public.cineo_shows(id) on delete cascade,creator_id uuid not null references auth.users(id) on delete cascade,first_cents integer not null,episode_cents integer not null,joined_at timestamptz not null default now());
create index cineo_mission_entries_owner_idx on public.cineo_mission_entries(creator_id);
create table public.cineo_reward_ledger(id uuid primary key default gen_random_uuid(),creator_id uuid not null references auth.users(id) on delete cascade,kind text not null check(kind in('first_series','episode','bonus')),source_key text not null,show_id bigint,episode_id bigint,amount_cents bigint not null check(amount_cents>0),reason text not null,actor_id uuid references auth.users(id) on delete set null,created_at timestamptz not null default now(),unique(creator_id,kind,source_key));
create index cineo_rewards_owner_idx on public.cineo_reward_ledger(creator_id,created_at desc);
create table public.cineo_clip_controls(show_id bigint primary key references public.cineo_shows(id) on delete cascade,enabled boolean not null default true,position integer not null default 100 check(position between 0 and 10000),reason text not null default '',updated_at timestamptz not null default now());
create table public.cineo_admin_history(id bigint generated always as identity primary key,actor_id uuid references auth.users(id) on delete set null,action text not null,target text not null,detail jsonb not null default '{}',created_at timestamptz not null default now());
do $$declare t text;begin foreach t in array array['cineo_mission_program','cineo_mission_members','cineo_mission_entries','cineo_reward_ledger','cineo_clip_controls','cineo_admin_history'] loop execute format('alter table public.%I enable row level security',t);execute format('revoke all on public.%I from public,anon,authenticated',t);execute format('grant all on public.%I to service_role',t);end loop;end$$;
grant usage,select on sequence public.cineo_admin_history_id_seq to service_role;

create function public.cineo_join_missions(actor uuid) returns jsonb language plpgsql security invoker set search_path='' as $$declare rules public.cineo_mission_program;begin
 select * into rules from public.cineo_mission_program where id=1 for update;
 perform 1 from public.cineo_creator_accounts where user_id=actor and status='approved' for update;if not found then raise exception 'Conclua seu cadastro de criador';end if;
 if not rules.enabled then raise exception 'Novas participações estão pausadas';end if;
 insert into public.cineo_mission_members(creator_id,first_eligible) values(actor,not exists(select 1 from public.cineo_shows where owner_id=actor and status='approved')) on conflict do nothing;
 insert into public.cineo_mission_entries(show_id,creator_id,first_cents,episode_cents) select id,actor,rules.first_cents,rules.episode_cents from public.cineo_shows where owner_id=actor and status in('draft','rejected','pending') on conflict do nothing;
 return jsonb_build_object('ok',true);
end$$;
create function public.cineo_mission_new_show() returns trigger language plpgsql security invoker set search_path='' as $$begin
 if exists(select 1 from public.cineo_mission_program where id=1 and enabled) and exists(select 1 from public.cineo_mission_members where creator_id=new.owner_id) then
 insert into public.cineo_mission_entries(show_id,creator_id,first_cents,episode_cents) select new.id,new.owner_id,first_cents,episode_cents from public.cineo_mission_program where id=1 on conflict do nothing;end if;return new;
end$$;
create trigger cineo_mission_show_created after insert on public.cineo_shows for each row execute function public.cineo_mission_new_show();

create function public.cineo_sync_missions(owner uuid) returns jsonb language plpgsql security invoker set search_path='' as $$declare budget bigint;spent bigint;r record;e record;amount bigint;inserted uuid;added bigint:=0;begin
 select budget_cents into budget from public.cineo_mission_program where id=1 for update;
 perform 1 from public.cineo_creator_accounts where user_id=owner and status='approved' for update;if not found then return jsonb_build_object('added_cents',0);end if;
 if exists(select 1 from public.cineo_copyright_cases where creator_id=owner and status='reviewing') then return jsonb_build_object('added_cents',0);end if;
 select coalesce(sum(amount_cents),0) into spent from public.cineo_reward_ledger where kind in('first_series','episode');
 for r in select s.id,m.first_cents,m.episode_cents,m.joined_at from public.cineo_mission_entries m join public.cineo_shows s on s.id=m.show_id where m.creator_id=owner and s.owner_id=owner and s.status='approved' and not s.hidden and (s.premiere_at is null or s.premiere_at<=now()) order by s.created_at,s.id loop
  if not exists(select 1 from public.cineo_episodes where show_id=r.id and review_status='approved' and not hidden and media_state='ready' and (release_at is null or release_at<=now())) then continue;end if;
  amount:=r.first_cents;
  if amount>0 and exists(select 1 from public.cineo_mission_members where creator_id=owner and first_eligible) and (budget is null or spent+amount<=budget) then
   inserted:=null;insert into public.cineo_reward_ledger(creator_id,kind,source_key,show_id,amount_cents,reason) values(owner,'first_series','first-series',r.id,amount,'Missão: primeira série aprovada e publicada') on conflict do nothing returning id into inserted;
   if inserted is not null then spent:=spent+amount;added:=added+amount;end if;
  end if;
  for e in select id,storage_path from public.cineo_episodes where show_id=r.id and review_status='approved' and not hidden and media_state='ready' and (release_at is null or release_at<=now()) order by season,episode_number,id loop
   amount:=r.episode_cents;if amount<=0 then continue;end if;
   if budget is null or spent+amount<=budget then
    inserted:=null;insert into public.cineo_reward_ledger(creator_id,kind,source_key,show_id,episode_id,amount_cents,reason) values(owner,'episode',md5(e.storage_path),r.id,e.id,amount,'Missão: episódio aprovado e publicado') on conflict do nothing returning id into inserted;
    if inserted is not null then spent:=spent+amount;added:=added+amount;end if;
   end if;
  end loop;
 end loop;
 if added>0 then insert into public.cineo_studio_audit(creator_id,actor_id,action,detail) values(owner,null,'missions_released',jsonb_build_object('amount_cents',added,'reason','Série e episódios aprovados, publicados e tecnicamente prontos'));end if;
 return jsonb_build_object('added_cents',added);
end$$;
create function public.cineo_mission_publication() returns trigger language plpgsql security invoker set search_path='' as $$declare owner uuid;begin
 if tg_table_name='cineo_shows' then owner:=new.owner_id;else select owner_id into owner from public.cineo_shows where id=new.show_id;end if;
 if exists(select 1 from public.cineo_mission_entries where creator_id=owner) then perform public.cineo_sync_missions(owner);end if;return new;
end$$;
create trigger cineo_mission_show_published after update of status,hidden,premiere_at on public.cineo_shows for each row execute function public.cineo_mission_publication();
create trigger cineo_mission_episode_published after insert or update of review_status,hidden,release_at,media_state on public.cineo_episodes for each row execute function public.cineo_mission_publication();

create function public.cineo_reward_balance(owner uuid) returns bigint language sql stable security invoker set search_path='' as $$select coalesce((select sum(approved_cents) from public.cineo_monthly_settlements where creator_id=owner),0)+coalesce((select sum(amount_cents) from public.cineo_reward_ledger where creator_id=owner),0)-coalesce((select sum(amount_cents) from public.cineo_withdrawals where creator_id=owner and status in('requested','approved','paid')),0)$$;
create function public.cineo_grant_bonus(actor uuid,owner uuid,amount bigint,request_id uuid,note text) returns jsonb language plpgsql security invoker set search_path='' as $$declare row public.cineo_reward_ledger;begin
 if not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Acesso restrito';end if;
 perform 1 from public.cineo_creator_accounts where user_id=owner and status='approved' for update;if not found then raise exception 'Criador inativo';end if;
 if amount<1 or amount>100000000 or length(trim(note))<5 or request_id is null then raise exception 'Informe valor, referência e motivo válidos';end if;
 insert into public.cineo_reward_ledger(creator_id,kind,source_key,amount_cents,reason,actor_id) values(owner,'bonus',request_id::text,amount,left(note,2000),actor) on conflict do nothing returning * into row;
 if row.id is null then select * into row from public.cineo_reward_ledger where creator_id=owner and kind='bonus' and source_key=request_id::text;if row.amount_cents<>amount or row.reason<>left(note,2000) then raise exception 'Referência já usada com outro valor ou motivo';end if;else
 insert into public.cineo_studio_audit(creator_id,actor_id,action,detail) values(owner,actor,'bonus_granted',jsonb_build_object('id',row.id,'amount_cents',amount,'reason',left(note,2000)));end if;
 return jsonb_build_object('id',row.id,'amount_cents',row.amount_cents);
end$$;

create or replace function public.cineo_request_withdrawal(actor uuid,amount bigint,envelope jsonb,hint text,terms integer) returns jsonb language plpgsql security invoker set search_path='' as $$declare rules public.cineo_payout_rules;available bigint;out_id uuid;begin
 perform 1 from public.cineo_creator_accounts where user_id=actor and status='approved' for update;if not found then raise exception 'Cadastro de criador não está ativo';end if;
 select * into rules from public.cineo_payout_rules where id=1;
 if not rules.enabled or rules.minimum_cents is null or length(rules.terms)<10 then raise exception 'Saques ainda não habilitados pelo administrador';end if;
 if terms<>rules.revision then raise exception 'As regras mudaram. Leia e aceite novamente';end if;
 select public.cineo_reward_balance(actor) into available;
 if amount<rules.minimum_cents or amount>available then raise exception 'Valor fora do mínimo ou do saldo revisado disponível';end if;
 if not (envelope ? 'ciphertext' and envelope ? 'iv') or length(hint)>100 then raise exception 'Destino de pagamento inválido';end if;
 insert into public.cineo_withdrawals(creator_id,amount_cents,pix_envelope,pix_hint,terms_revision) values(actor,amount,envelope,hint,terms) returning id into out_id;
 insert into public.cineo_studio_audit(creator_id,actor_id,action,detail) values(actor,actor,'withdrawal_requested',jsonb_build_object('id',out_id,'amount_cents',amount));return jsonb_build_object('id',out_id);
end$$;

create or replace function public.cineo_studio_finance(owner uuid) returns jsonb language sql stable security invoker set search_path='' as $$with totals as(select date_trunc('month',day)::date as month,count(*) views,sum(rate_cents_per_thousand) units from public.cineo_qualified_views where creator_id=owner group by 1),monthly as(select month,views,floor(sum(units) over(order by month)/1000.0)-floor((sum(units) over(order by month)-units)/1000.0) gross_cents from totals) select jsonb_build_object('rules',(select to_jsonb(r) from public.cineo_payout_rules r where id=1),'available_cents',public.cineo_reward_balance(owner),'reward_cents',coalesce((select sum(amount_cents) from public.cineo_reward_ledger where creator_id=owner),0),'rewards',(select coalesce(jsonb_agg(x order by created_at desc),'[]') from(select kind,amount_cents,reason,show_id,episode_id,created_at from public.cineo_reward_ledger where creator_id=owner order by created_at desc limit 100)x),'months',(select coalesce(jsonb_agg(x order by month desc),'[]') from monthly x),'settlements',(select coalesce(jsonb_agg(s order by month desc),'[]') from public.cineo_monthly_settlements s where creator_id=owner),'withdrawals',(select coalesce(jsonb_agg(x order by created_at desc),'[]') from(select id,amount_cents,pix_hint,status,note,payment_reference,created_at from public.cineo_withdrawals where creator_id=owner order by created_at desc limit 100)x))$$;


do $$declare p record;begin for p in select oid::regprocedure signature from pg_proc where pronamespace='public'::regnamespace and proname in('cineo_join_missions','cineo_mission_new_show','cineo_sync_missions','cineo_mission_publication','cineo_reward_balance','cineo_grant_bonus','cineo_request_withdrawal','cineo_studio_finance') loop execute format('revoke all on function %s from public,anon,authenticated',p.signature);execute format('grant execute on function %s to service_role',p.signature);end loop;end$$;
create function public.cineo_clip_candidates(skip integer) returns jsonb language sql stable security invoker set search_path='' as $$select coalesce(jsonb_agg(x),'[]') from(select to_jsonb(s) as show,to_jsonb(e) as episode,coalesce(c.position,100) as position from public.cineo_shows s cross join lateral(select * from public.cineo_episodes where show_id=s.id order by season,episode_number,id limit 1)e left join public.cineo_clip_controls c on c.show_id=s.id where s.status='approved' and not s.hidden and (s.premiere_at is null or s.premiere_at<=now()) and e.review_status='approved' and not e.hidden and e.media_state='ready' and (e.release_at is null or e.release_at<=now()) and coalesce(c.enabled,true) and not exists(select 1 from public.cineo_creator_accounts a where a.user_id=s.owner_id and a.status='banned') order by coalesce(c.position,100),s.id desc offset greatest(0,skip) limit 12)x$$;
create function public.cineo_launch_admin(actor uuid,command text,payload jsonb) returns jsonb language plpgsql security invoker set search_path='' as $$declare target text;changed integer;begin
 if not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Acesso restrito';end if;
 if length(trim(payload->>'reason'))<5 or payload->>'reason' is null then raise exception 'Informe o motivo da alteração';end if;
 if command='program' then
  if (payload->>'first_cents')::integer not between 0 and 100000 or (payload->>'episode_cents')::integer not between 0 and 10000 or (payload->>'budget_cents')::bigint<0 then raise exception 'Valor inválido';end if;
  update public.cineo_mission_program set enabled=(payload->>'enabled')::boolean,first_cents=(payload->>'first_cents')::integer,episode_cents=(payload->>'episode_cents')::integer,budget_cents=(payload->>'budget_cents')::bigint,revision=revision+1,updated_at=now() where id=1 and revision=(payload->>'revision')::integer;
  get diagnostics changed=row_count;if changed=0 then raise exception 'As regras mudaram. Atualize a tela';end if;target:='mission-program';
 elsif command='verify' then
  target:=payload->>'user_id';update public.cineo_profiles set verified=(payload->>'verified')::boolean where user_id=target::uuid;get diagnostics changed=row_count;if changed=0 then raise exception 'Perfil inexistente';end if;
 elsif command='clip' then
  target:=payload->>'show_id';if not exists(select 1 from public.cineo_shows where id=target::bigint) then raise exception 'Série inexistente';end if;
  insert into public.cineo_clip_controls(show_id,enabled,position,reason) values(target::bigint,(payload->>'enabled')::boolean,(payload->>'position')::integer,left(payload->>'reason',2000)) on conflict(show_id) do update set enabled=excluded.enabled,position=excluded.position,reason=excluded.reason,updated_at=now();
 else raise exception 'Comando inválido';end if;
 insert into public.cineo_admin_history(actor_id,action,target,detail) values(actor,'launch_'||command,target,payload-'user_id');return jsonb_build_object('ok',true);
end$$;
create function public.cineo_clip_health() returns jsonb language sql stable security invoker set search_path='' as $$select jsonb_build_object('sessions',(select count(*) from public.cineo_view_sessions where created_at>now()-interval '7 days'),'qualified_views',(select count(*) from public.cineo_qualified_views where day>=current_date-6),'clip_sessions',(select count(*) from public.cineo_view_sessions where created_at>now()-interval '7 days' and source='clips'),'clip_views',(select count(*) from public.cineo_qualified_views where day>=current_date-6 and source='clips'),'high_repeat_accounts',(select count(*) from(select user_id,count(*) from public.cineo_view_sessions where created_at>now()-interval '1 day' group by user_id having count(*)>100)x))$$;
do $$declare p record;begin for p in select oid::regprocedure signature from pg_proc where pronamespace='public'::regnamespace and proname in('cineo_clip_candidates','cineo_launch_admin','cineo_clip_health') loop execute format('revoke all on function %s from public,anon,authenticated',p.signature);execute format('grant execute on function %s to service_role',p.signature);end loop;end$$;
