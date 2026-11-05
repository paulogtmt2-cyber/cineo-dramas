create or replace function public.cineo_sync_playback(actor uuid,viewer uuid,eid bigint,pos integer,duration integer,done boolean,observed timestamptz) returns jsonb language plpgsql security invoker set search_path='' as $$declare k text:=coalesce(viewer::text,'account');stored_observed timestamptz;begin
 if duration not between 1 and 14400000 or pos not between 0 and duration or observed>now()+interval '1 minute' or observed<now()-interval '90 days' then raise exception 'Progresso ou horário inválido';end if;
 if viewer is not null and not exists(select 1 from public.cineo_viewers where id=viewer and user_id=actor) then raise exception 'Perfil indisponível';end if;
 insert into public.cineo_playback_clock(user_id,viewer_key,episode_id,observed_at) values(actor,k,eid,observed) on conflict do nothing;
 select observed_at into stored_observed from public.cineo_playback_clock where user_id=actor and viewer_key=k and episode_id=eid for update;
 if stored_observed>observed then return jsonb_build_object('ok',true,'applied',false,'reason','Há um progresso mais recente em outro aparelho.');end if;
 update public.cineo_playback_clock set observed_at=observed where user_id=actor and viewer_key=k and episode_id=eid;
 if viewer is null then insert into public.cineo_progress(user_id,episode_id,position_ms,duration_ms,completed,updated_at) values(actor,eid,pos,duration,done,now()) on conflict(user_id,episode_id) do update set position_ms=excluded.position_ms,duration_ms=excluded.duration_ms,completed=excluded.completed,updated_at=excluded.updated_at;
 else insert into public.cineo_viewer_progress(viewer_id,episode_id,position_ms,duration_ms,completed,updated_at) values(viewer,eid,pos,duration,done,now()) on conflict(viewer_id,episode_id) do update set position_ms=excluded.position_ms,duration_ms=excluded.duration_ms,completed=excluded.completed,updated_at=excluded.updated_at;end if;
 return jsonb_build_object('ok',true,'applied',true);end$$;
