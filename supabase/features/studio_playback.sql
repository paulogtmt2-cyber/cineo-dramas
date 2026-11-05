create or replace function public.cineo_view_heartbeat(actor uuid,session uuid,pos integer,active_ms integer) returns jsonb language plpgsql security invoker set search_path='' as $$
declare r public.cineo_view_sessions;e public.cineo_episodes;s public.cineo_shows;delta integer;threshold integer;rate integer:=0;added integer;begin
 select * into r from public.cineo_view_sessions where id=session and user_id=actor for update;
 if not found or r.created_at<now()-interval '2 hours' then raise exception 'Sessão de vídeo indisponível';end if;
 select * into e from public.cineo_episodes where id=r.episode_id;
 select * into s from public.cineo_shows where id=e.show_id;
 if s.status<>'approved' or s.hidden or e.hidden or e.review_status<>'approved' or e.media_state='failed' or s.premiere_at>now() or e.release_at>now() or s.owner_id=actor then return jsonb_build_object('credited',false);end if;
 if pos<0 or pos>14400000 or active_ms<0 or active_ms>14400000 then raise exception 'Posição inválida';end if;
 delta:=greatest(0,least(15000,(extract(epoch from now()-r.last_at)*1000)::integer,pos-r.position_ms,active_ms-r.reported_ms));
 threshold:=case when e.duration_seconds>0 then least(10000,greatest(1000,e.duration_seconds*800)) else 10000 end;
 if delta>0 and pos-r.position_ms<=greatest(3000,(extract(epoch from now()-r.last_at)*3000)::integer) then insert into public.cineo_watch_spans(session_id,seq,from_ms,to_ms) values(session,active_ms,r.position_ms,pos) on conflict do nothing;end if;
 update public.cineo_view_sessions set finished=finished or (e.duration_seconds>0 and pos>=e.duration_seconds*950),watched_ms=watched_ms+delta,position_ms=pos,reported_ms=greatest(reported_ms,active_ms),last_at=now() where id=session;
 if not r.credited and r.watched_ms+delta>=threshold then
  if exists(select 1 from public.cineo_creator_accounts where user_id=s.owner_id and status='approved') then rate:=40;end if;
  insert into public.cineo_qualified_views(user_id,episode_id,show_id,creator_id,rate_cents_per_thousand,source,experiments) values(actor,e.id,s.id,s.owner_id,rate,r.source,r.experiments) on conflict do nothing;
  get diagnostics added=row_count;
  update public.cineo_view_sessions set credited=true where id=session;
  if added=1 then update public.cineo_ab_exposures set qualified=true where user_id=actor and day=(now() at time zone 'America/Sao_Paulo')::date and test_id in(select (x->>'id')::uuid from jsonb_array_elements(r.experiments)x);end if;
  return jsonb_build_object('credited',true,'new_view',added=1);
 end if;
 return jsonb_build_object('credited',r.credited);
end $$;

