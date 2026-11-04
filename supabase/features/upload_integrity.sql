alter table public.cineo_uploads add column fingerprint text not null default '' check(length(fingerprint) in (0,64));
