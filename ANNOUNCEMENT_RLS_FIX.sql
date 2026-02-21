-- Admin Announcement Policies Update

-- Ensure RLS is enabled
alter table public.announcements enable row level security;

-- Drop existing policies to prevent conflicts
drop policy if exists "Announcements are viewable by everyone" on public.announcements;
drop policy if exists "Admins can insert announcements" on public.announcements;
drop policy if exists "Admins can update their announcements" on public.announcements;
drop policy if exists "Admins can delete their announcements" on public.announcements;

-- 1. View Policy: Everyone can view announcements
create policy "Announcements are viewable by everyone"
  on public.announcements for select
  using ( true );

-- 2. Insert Policy: Admins can insert announcements
-- This checks if the user has the 'admin' or 'worker' role in their profile
create policy "Admins can insert announcements"
  on public.announcements for insert
  to authenticated
  with check (
    exists (
      select 1 from public.profiles
      where id = auth.uid()
      and (lower(role) = 'admin' or lower(role) = 'worker')
    )
  );

-- 3. Update Policy: Admins can update announcements
-- Super Admins ('SUPER') can update ALL.
-- Department Admins can update announcements belonging to their department.
create policy "Admins can update announcements"
  on public.announcements for update
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid()
      and (
        -- Check if Super Admin
        lower(department) = 'super'
        OR
        -- Check if Admin's department matches Announcement's department (Case-insensitive)
        lower(department) = lower(announcements.department)
      )
    )
  );

-- 4. Delete Policy: Admins can delete announcements
-- Same logic as update
create policy "Admins can delete announcements"
  on public.announcements for delete
  to authenticated
  using (
    exists (
      select 1 from public.profiles
      where id = auth.uid()
      and (
        -- Check if Super Admin
        lower(department) = 'super'
        OR
        -- Check if Admin's department matches Announcement's department (Case-insensitive)
        lower(department) = lower(announcements.department)
      )
    )
  );
