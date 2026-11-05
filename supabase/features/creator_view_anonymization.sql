-- Account deletion removes spectator identity without retracting valid aggregate estimates.
alter table public.cineo_qualified_views drop constraint cineo_qualified_views_pkey;
alter table public.cineo_qualified_views add column id bigint generated always as identity primary key;
alter table public.cineo_qualified_views alter column user_id drop not null;
alter table public.cineo_qualified_views drop constraint cineo_qualified_views_user_id_fkey;
alter table public.cineo_qualified_views add constraint cineo_qualified_views_user_id_fkey foreign key(user_id) references auth.users(id) on delete set null;
alter table public.cineo_qualified_views add constraint cineo_qualified_views_daily_unique unique(user_id,episode_id,day);
grant usage,select on sequence public.cineo_qualified_views_id_seq to service_role;
