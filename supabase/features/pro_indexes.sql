create index cineo_episode_review_idx on public.cineo_episodes(review_status,id);
create unique index cineo_episode_chapter_idx on public.cineo_episodes(show_id,season,episode_number);
