alter table public.cineo_shows add column if not exists genre text not null default 'Drama' check (genre in ('Drama','Romance','Suspense','Ação','Comédia','Novela'));
alter table public.cineo_shows add column if not exists rating text not null default 'Livre' check (rating in ('Livre','10','12','14','16','18'));
alter table public.cineo_shows add column if not exists cover_path text not null default '';
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('cineo-covers','cineo-covers',false,2097152,array['image/jpeg']) on conflict(id) do nothing;
create or replace function public.cineo_edit_show(actor uuid,sid bigint,new_title text,new_synopsis text,new_genre text,new_rating text,new_cover text default null)
returns text language plpgsql security invoker set search_path='' as $$
declare s public.cineo_shows;
begin
 select * into s from public.cineo_shows where id=sid for update;
 if s.owner_id is distinct from actor or s.status not in ('draft','rejected') then raise exception 'Edição não permitida'; end if;
 update public.cineo_shows set title=new_title,synopsis=new_synopsis,genre=new_genre,rating=new_rating,cover_path=coalesce(new_cover,cover_path),status='draft',reason='' where id=sid;
 return s.cover_path;
end;$$;
revoke all on function public.cineo_edit_show(uuid,bigint,text,text,text,text,text) from public,anon,authenticated;
grant execute on function public.cineo_edit_show(uuid,bigint,text,text,text,text,text) to service_role;
-- This event trigger has no client API purpose. Preserve its DDL behavior.
revoke execute on function public.rls_auto_enable() from public,anon,authenticated;
