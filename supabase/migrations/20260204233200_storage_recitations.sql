-- Storage bucket policies for recitations.

-- Ensure storage schema is available.
create extension if not exists "pgcrypto";

-- RLS is enabled by default on storage.objects in Supabase.
-- Allow authenticated users to manage their own uploads in the recitations bucket.

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'recitations_insert_own'
  ) then
    create policy recitations_insert_own on storage.objects
      for insert to authenticated
      with check (bucket_id = 'recitations' and auth.uid() = owner);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'recitations_select_own'
  ) then
    create policy recitations_select_own on storage.objects
      for select to authenticated
      using (bucket_id = 'recitations' and auth.uid() = owner);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'storage' and tablename = 'objects' and policyname = 'recitations_delete_own'
  ) then
    create policy recitations_delete_own on storage.objects
      for delete to authenticated
      using (bucket_id = 'recitations' and auth.uid() = owner);
  end if;
end $$;
