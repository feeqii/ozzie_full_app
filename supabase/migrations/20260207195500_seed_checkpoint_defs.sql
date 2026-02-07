-- Seed checkpoint verse ranges for currently playable surahs.
-- These ranges are used for "Memorization Checkpoints (Pop-Quiz)" recitation prompts.

insert into public.surah_checkpoint_defs (surah_id, checkpoint_index, from_ayah, to_ayah, order_index)
values
  (1, 1, 1, 2, 1),
  (1, 2, 1, 4, 2),
  (112, 1, 1, 2, 1),
  (112, 2, 1, 4, 2)
on conflict (surah_id, checkpoint_index) do nothing;

