-- Publication draft identity and creator-selected format, separate from genre.
alter table public.cineo_shows add column format text not null default 'series' check(format in('series','novela','mini','drama'));
alter table public.cineo_shows add column client_draft_id uuid;
create unique index cineo_show_draft_identity_idx on public.cineo_shows(owner_id,client_draft_id) where client_draft_id is not null;
create function public.cineo_chapter_capacity() returns trigger language plpgsql security invoker set search_path='' as $$begin
 perform 1 from public.cineo_shows where id=new.show_id for update;
 if new.episode_number<1 or new.episode_number>1000 then raise exception 'Use capítulos de 1 a 1000';end if;
 if (select count(*) from public.cineo_episodes where show_id=new.show_id)>=1000 then raise exception 'Esta produção atingiu o limite de 1000 capítulos';end if;
 return new;end$$;
create trigger cineo_episode_capacity before insert on public.cineo_episodes for each row execute function public.cineo_chapter_capacity();
create function public.cineo_save_production(actor uuid,target bigint,draft_id uuid,fields jsonb,cover text) returns jsonb language plpgsql security invoker set search_path='' as $$declare s public.cineo_shows;begin
 perform 1 from public.cineo_creator_accounts where user_id=actor and status='approved' for update;
 if not found and not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Conclua seu cadastro de criador';end if;
 if length(trim(fields->>'title')) not between 1 and 100 or length(trim(fields->>'synopsis')) not between 1 and 3000 or fields->>'format' not in('series','novela','mini','drama') or fields->>'genre' not in('Drama','Romance','Suspense','Ação','Comédia','Novela') or fields->>'rating' not in('Livre','10','12','14','16','18') then raise exception 'Confira os dados da produção';end if;
 if target is null then
  if draft_id is null then raise exception 'Identificador de rascunho inválido';end if;
  select * into s from public.cineo_shows where owner_id=actor and client_draft_id=draft_id for update;
 else select * into s from public.cineo_shows where id=target and owner_id=actor for update;if not found then raise exception 'Produção indisponível';end if;end if;
 if s.id is not null and s.status not in('draft','rejected') then raise exception 'A ficha está bloqueada durante análise ou após publicação';end if;
 if coalesce(cover,s.cover_path,'')='' or coalesce(cover,s.cover_path) not like actor::text||'/%' then raise exception 'Escolha a capa da produção';end if;
 if s.id is null then
 insert into public.cineo_shows(owner_id,title,synopsis,genre,rating,format,cover_path,client_draft_id) values(actor,trim(fields->>'title'),trim(fields->>'synopsis'),fields->>'genre',fields->>'rating',fields->>'format',cover,draft_id) returning * into s;
 else update public.cineo_shows set title=trim(fields->>'title'),synopsis=trim(fields->>'synopsis'),genre=fields->>'genre',rating=fields->>'rating',format=fields->>'format',cover_path=coalesce(cover,cover_path),status='draft',reason='' where id=s.id returning * into s;end if;
 return to_jsonb(s);
end$$;
create function public.cineo_publishing_check(sid bigint) returns jsonb language sql stable security invoker set search_path='' as $$select jsonb_build_object('total',count(*),'ready',count(*) filter(where media_state='ready'),'waiting',count(*) filter(where media_state<>'ready'),'failed',count(*) filter(where media_state='failed'),'pending_uploads',(select count(*) from public.cineo_uploads where show_id=sid and episode_id is null and not cancelled),'max_chapters',1000,'drafts',count(*) filter(where review_status in('draft','rejected')),'pending_reviews',count(*) filter(where review_status='pending'),'next_chapter',coalesce(max(episode_number) filter(where season=1),0)+1) from public.cineo_episodes where show_id=sid$$;
create function public.cineo_submit_production(actor uuid,sid bigint,rights boolean) returns jsonb language plpgsql security invoker set search_path='' as $$declare s public.cineo_shows;checks jsonb;begin
 select * into s from public.cineo_shows where id=sid for update;
 if s.owner_id is distinct from actor then raise exception 'Somente o titular envia a produção';end if;
 if not exists(select 1 from public.cineo_creator_accounts where user_id=actor and status='approved') and not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Seu acesso de criador precisa estar ativo';end if;
 if s.status='pending' then return jsonb_build_object('ok',true,'already_pending',true);end if;
 if s.status not in('draft','rejected') or rights is distinct from true then raise exception 'Confirme os direitos e confira a situação da produção';end if;
 checks:=public.cineo_publishing_check(sid);
 if s.cover_path is null or s.cover_path='' or length(trim(s.title))=0 or length(trim(s.synopsis))=0 then raise exception 'Preencha título, capa e descrição';end if;
 if (checks->>'total')::integer not between 1 and 1000 or (checks->>'waiting')::integer>0 or (checks->>'pending_uploads')::integer>0 then raise exception 'Conclua os envios e a validação técnica de todos os capítulos';end if;
 if exists(select 1 from public.cineo_media_jobs j join public.cineo_episodes e on e.id=j.episode_id where e.show_id=sid and j.status<>'ready') then raise exception 'Há validações técnicas pendentes';end if;
 perform public.cineo_transition(actor,sid,'pending','');
 return jsonb_build_object('ok',true);
end$$;
create function public.cineo_submit_new_chapters(actor uuid,sid bigint,rights boolean) returns jsonb language plpgsql security invoker set search_path='' as $$declare s public.cineo_shows;n integer;begin
 select * into s from public.cineo_shows where id=sid for update;
 if s.owner_id is distinct from actor or s.status<>'approved' or rights is distinct from true then raise exception 'Confirme a produção e os direitos de publicação';end if;
 if not exists(select 1 from public.cineo_creator_accounts where user_id=actor and status='approved') and not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Acesso de criador inativo';end if;
 select count(*) into n from public.cineo_episodes where show_id=sid and review_status in('draft','rejected');if n=0 then raise exception 'Não há novos capítulos para enviar';end if;
 if exists(select 1 from public.cineo_episodes where show_id=sid and review_status in('draft','rejected') and media_state<>'ready') or exists(select 1 from public.cineo_uploads where show_id=sid and episode_id is null and not cancelled) then raise exception 'Conclua os envios e a validação técnica dos novos capítulos';end if;
 update public.cineo_episodes set review_status='pending',review_reason='' where show_id=sid and review_status in('draft','rejected');
 return jsonb_build_object('ok',true,'chapters_pending',n);
end$$;
create function public.cineo_admin_production_review(actor uuid,sid bigint,decision text,note text) returns jsonb language plpgsql security invoker set search_path='' as $$declare s public.cineo_shows;cid uuid;checks jsonb;begin
 if not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Acesso restrito';end if;
 select * into s from public.cineo_shows where id=sid for update;
 if not found or s.status<>'pending' or decision not in('approved','rejected') then raise exception 'Esta produção não está em análise';end if;
 if decision='approved' then
 checks:=public.cineo_publishing_check(sid);
 if coalesce(s.cover_path,'')='' or (checks->>'total')::integer not between 1 and 1000 or (checks->>'waiting')::integer>0 or (checks->>'pending_uploads')::integer>0 then raise exception 'Confira a capa, os capítulos e a validação técnica';end if;
 if not exists(select 1 from public.cineo_creator_accounts where user_id=s.owner_id and status='approved') and not exists(select 1 from public.cineo_admins where user_id=s.owner_id) then raise exception 'O acesso de criador está suspenso ou inativo';end if;end if;
 select id into cid from public.cineo_cases where kind='show' and target_id=sid::text and status='open';if cid is null then raise exception 'Caso de análise indisponível';end if;
 perform public.cineo_decide_case(actor,cid,decision,coalesce(note,''));return jsonb_build_object('ok',true);
end$$;
create function public.cineo_app_dashboard(days integer) returns jsonb language sql stable security invoker set search_path='' as $$with dates as(select generate_series((now() at time zone 'America/Sao_Paulo')::date-(greatest(7,least(90,days))-1),(now() at time zone 'America/Sao_Paulo')::date,interval '1 day')::date as day),views as(select day,count(*) views from public.cineo_qualified_views where day>=(now() at time zone 'America/Sao_Paulo')::date-(greatest(7,least(90,days))-1) group by 1),productions as(select (created_at at time zone 'America/Sao_Paulo')::date as day,count(*) publications from public.cineo_shows where created_at>=now()-make_interval(days=>greatest(7,least(90,days))) group by 1) select jsonb_build_object('counts',jsonb_build_object('profiles',(select count(*) from public.cineo_profiles),'creators',(select count(*) from public.cineo_creator_accounts where status='approved'),'productions',(select count(*) from public.cineo_shows),'published',(select count(*) from public.cineo_shows where status='approved' and not hidden),'pending',(select count(*) from public.cineo_shows where status='pending'),'chapters',(select count(*) from public.cineo_episodes),'episode_pending',(select count(*) from public.cineo_episodes where review_status='pending'),'reports',(select count(*) from public.cineo_reports where status='open'),'tickets',(select count(*) from public.cineo_tickets where status='open'),'views',(select coalesce(sum(views),0) from views)),'daily',(select jsonb_agg(jsonb_build_object('day',d.day,'views',coalesce(v.views,0),'productions',coalesce(p.publications,0)) order by d.day) from dates d left join views v using(day) left join productions p using(day)),'statuses',(select jsonb_agg(x) from(select status,count(*) total from public.cineo_shows group by status)x))$$;
do $$declare p record;begin for p in select oid::regprocedure signature from pg_proc where pronamespace='public'::regnamespace and proname in('cineo_chapter_capacity','cineo_save_production','cineo_publishing_check','cineo_submit_production','cineo_submit_new_chapters','cineo_admin_production_review','cineo_app_dashboard') loop execute format('revoke all on function %s from public,anon,authenticated',p.signature);execute format('grant execute on function %s to service_role',p.signature);end loop;end$$;
