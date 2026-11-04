alter policy cineo_shows_read on public.cineo_shows using ((status='approved' and not hidden and (premiere_at is null or premiere_at<=now())) or owner_id=(select auth.uid()) or exists(select 1 from public.cineo_admins where user_id=(select auth.uid())));
alter policy cineo_episodes_read on public.cineo_episodes using (exists(select 1 from public.cineo_shows s where s.id=show_id and (s.owner_id=(select auth.uid()) or exists(select 1 from public.cineo_admins where user_id=(select auth.uid())) or (s.status='approved' and not s.hidden and (s.premiere_at is null or s.premiere_at<=now()) and review_status='approved' and not cineo_episodes.hidden))));
create function public.cineo_notify(sid bigint,eid bigint default null) returns void language sql security invoker set search_path='' as $$
insert into public.cineo_notifications(user_id,episode_id)
select distinct f.user_id,e.id from public.cineo_shows s join public.cineo_episodes e on e.show_id=s.id join public.cineo_follows f on (f.kind='show' and f.target=s.id::text) or (f.kind='creator' and f.target=s.owner_id::text)
where s.id=sid and s.status='approved' and e.review_status='approved' and (eid is null or e.id=eid) on conflict(user_id,episode_id) do nothing;
$$;
create function public.cineo_review_episode(actor uuid,eid bigint,decision text,note text default '') returns void language plpgsql security invoker set search_path='' as $$
declare e public.cineo_episodes;s public.cineo_shows;
begin if not exists(select 1 from public.cineo_admins where user_id=actor) then raise exception 'Acesso restrito.';end if;
select * into e from public.cineo_episodes where id=eid for update;select * into s from public.cineo_shows where id=e.show_id for update;
if e.id is null or e.review_status<>'pending' or s.status<>'approved' then raise exception 'Episódio não está em análise.';end if;
if decision not in ('approved','rejected') or (decision='rejected' and char_length(btrim(note))<3) then raise exception 'Decisão ou motivo inválidos.';end if;
update public.cineo_episodes set review_status=decision,review_reason=case when decision='rejected' then note else '' end where id=eid;
if decision='approved' then perform public.cineo_notify(s.id,eid);end if;end $$;
create function public.cineo_analytics(actor uuid) returns jsonb language sql stable security invoker set search_path='' as $$
select jsonb_build_object('followers',(select count(*) from public.cineo_follows where kind='creator' and target=actor::text),'items',coalesce(jsonb_agg(jsonb_build_object('id',s.id,'title',s.title,'viewers',(select count(distinct p.user_id) from public.cineo_progress p join public.cineo_episodes e on p.episode_id=e.id where e.show_id=s.id),'completed',(select count(*) from public.cineo_progress p join public.cineo_episodes e on p.episode_id=e.id where e.show_id=s.id and p.completed),'likes',(select count(*) from public.cineo_likes l join public.cineo_episodes e on l.episode_id=e.id where e.show_id=s.id))),'[]'::jsonb)) from public.cineo_shows s where s.owner_id=actor;
$$;
revoke all on function public.cineo_notify(bigint,bigint),public.cineo_review_episode(uuid,bigint,text,text),public.cineo_analytics(uuid) from public,anon,authenticated;
grant execute on function public.cineo_notify(bigint,bigint),public.cineo_review_episode(uuid,bigint,text,text),public.cineo_analytics(uuid) to service_role;
