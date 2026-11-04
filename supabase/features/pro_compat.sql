create or replace function public.cineo_add_episode(actor uuid,sid bigint,episode_title text,object_path text) returns void language plpgsql security invoker set search_path='' as $$
declare s public.cineo_shows;chapter integer;
begin select * into s from public.cineo_shows where id=sid for update;
if s.owner_id is distinct from actor or s.status not in ('draft','rejected') then raise exception 'Edição não permitida';end if;
select coalesce(max(episode_number),0)+1 into chapter from public.cineo_episodes where show_id=sid and season=1;
insert into public.cineo_episodes(show_id,title,storage_path,season,episode_number) values(sid,episode_title,object_path,1,chapter);
update public.cineo_shows set status='draft',reason='' where id=sid;end $$;
revoke all on function public.cineo_add_episode(uuid,bigint,text,text) from public,anon,authenticated;
grant execute on function public.cineo_add_episode(uuid,bigint,text,text) to service_role;
