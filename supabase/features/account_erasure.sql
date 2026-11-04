-- Only the internal service can prepare an already due, user-confirmed erasure request.
create function public.cineo_prepare_erasure(actor uuid) returns void language plpgsql security invoker set search_path='' as $$begin
 if not exists(select 1 from public.cineo_erasure where user_id=actor and execute_after<=now()) then raise exception 'No due erasure request';end if;
 update public.cineo_editorial set featured_id=null where featured_id in(select id from public.cineo_shows where owner_id=actor);
 update public.cineo_comments set parent_id=null where parent_id in(select id from public.cineo_comments where user_id=actor);
end$$;
revoke all on function public.cineo_prepare_erasure(uuid) from public,anon,authenticated;
grant execute on function public.cineo_prepare_erasure(uuid) to service_role;
