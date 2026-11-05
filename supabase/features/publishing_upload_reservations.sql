-- Reserve capacity under the same production lock used by publication and finalization.
create function public.cineo_upload_capacity() returns trigger language plpgsql security invoker set search_path='' as $$declare s public.cineo_shows;begin
 select * into s from public.cineo_shows where id=new.show_id for update;
 if s.id is null or s.status='pending' then raise exception 'Envio bloqueado durante análise';end if;
 if new.chapter>1000 then raise exception 'Use capítulos de 1 a 1000';end if;
 if (select count(*) from public.cineo_episodes where show_id=new.show_id)+(select count(*) from public.cineo_uploads where show_id=new.show_id and not cancelled and episode_id is null)>=1000 then raise exception 'Limite de 1000 capítulos, incluindo envios em andamento';end if;
 if exists(select 1 from public.cineo_episodes where show_id=new.show_id and season=new.season and episode_number=new.chapter) or exists(select 1 from public.cineo_uploads where show_id=new.show_id and season=new.season and chapter=new.chapter and not cancelled and episode_id is null) then raise exception 'Este número de capítulo já está cadastrado ou em envio';end if;
 return new;end$$;
create trigger cineo_upload_capacity before insert on public.cineo_uploads for each row execute function public.cineo_upload_capacity();
create or replace function public.cineo_queued_episode(actor uuid,sid bigint,episode_title text,object_path text,season_number integer,chapter_number integer,seconds integer,upload_id uuid) returns bigint language plpgsql security invoker set search_path='' as $$declare s public.cineo_shows;u public.cineo_uploads;eid bigint;begin
 select * into s from public.cineo_shows where id=sid for update;if s.id is null or s.owner_id is distinct from actor or s.status='pending' then raise exception 'Envio não permitido';end if;
 select * into u from public.cineo_uploads where id=upload_id for update;if found and u.cancelled then raise exception 'Este envio foi cancelado';end if;
 select id into eid from public.cineo_episodes where show_id=sid and client_upload_id=upload_id;
 if eid is null then insert into public.cineo_episodes(show_id,title,storage_path,season,episode_number,duration_seconds,review_status,client_upload_id) values(sid,episode_title,object_path,season_number,chapter_number,seconds,case when s.status='approved' then 'draft' else 'approved' end,upload_id) returning id into eid;end if;
 update public.cineo_uploads set episode_id=eid where id=upload_id;return eid;
end$$;
revoke all on function public.cineo_upload_capacity() from public,anon,authenticated;
grant execute on function public.cineo_upload_capacity() to service_role;
create index cineo_upload_pending_show_idx on public.cineo_uploads(show_id) where episode_id is null and not cancelled;
create or replace function public.cineo_chapter_capacity() returns trigger language plpgsql security invoker set search_path='' as $$begin
 perform 1 from public.cineo_shows where id=new.show_id for update;
 if new.episode_number<1 or new.episode_number>1000 then raise exception 'Use capítulos de 1 a 1000';end if;
 if (select count(*) from public.cineo_episodes where show_id=new.show_id)+(select count(*) from public.cineo_uploads where show_id=new.show_id and episode_id is null and not cancelled and id is distinct from new.client_upload_id)>=1000 then raise exception 'Esta produção atingiu o limite de 1000 capítulos, incluindo envios em andamento';end if;
 return new;end$$;
