-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- 1. PROFILES TABLE SETUP & FIXES
-- Ensure profiles table has correct defaults and constraints
do $$ 
begin
  -- Check if column exists, if not add it (idempotent approach)
  if not exists (select 1 from information_schema.columns where table_name = 'profiles' and column_name = 'role') then
    alter table public.profiles add column role text default 'user';
  -- else
    -- keep existing default or update it? Let's ensure it's text.
  end if;

  if not exists (select 1 from information_schema.columns where table_name = 'profiles' and column_name = 'username') then
    alter table public.profiles add column username text;
  end if;
  
   if not exists (select 1 from information_schema.columns where table_name = 'profiles' and column_name = 'created_at') then
    alter table public.profiles add column created_at timestamp with time zone default now() not null;
  end if;
end $$;

-- Enable RLS
alter table public.profiles enable row level security;


-- 2. REPORTS TABLE SETUP
create table if not exists public.reports (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  description text not null,
  image_url text,
  status text default 'pending',
  created_at timestamp with time zone default now() not null
);

-- status check constraint (add if not exists logic is tricky in one line, so separate alter)
do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'reports_status_check') then
    alter table public.reports add constraint reports_status_check check (status in ('pending', 'in_progress', 'resolved'));
  end if;
end $$;


-- Enable RLS
alter table public.reports enable row level security;


-- 3. HELPER FUNCTIONS
create or replace function public.is_admin()
returns boolean
language sql
security definer
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
    and role = 'admin'
  );
$$;


-- 4. RLS POLICIES

-- PROFILES POLICIES
-- Drop existing policies to ensure clean state
drop policy if exists "Users can view own profile" on public.profiles;
drop policy if exists "Users can update own profile" on public.profiles;
drop policy if exists "Admins can view all profiles" on public.profiles;
drop policy if exists "Admins can update all profiles" on public.profiles;
drop policy if exists "Admins can delete all profiles" on public.profiles;
drop policy if exists "Public profiles are viewable by everyone." on public.profiles;
drop policy if exists "Users can insert their own profile." on public.profiles;
drop policy if exists "Users can insert own profile" on public.profiles;

-- Users can view their own profile
create policy "Users can view own profile"
on public.profiles for select
to authenticated
using ( auth.uid() = id );

-- Users can update their own profile
create policy "Users can update own profile"
on public.profiles for update
to authenticated
using ( auth.uid() = id );

-- Admins can view all profiles
create policy "Admins can view all profiles"
on public.profiles for select
to authenticated
using ( public.is_admin() );

-- REPORTS POLICIES
-- Drop existing policies
drop policy if exists "Reports are viewable by everyone." on public.reports;
drop policy if exists "Users can view own reports" on public.reports;
drop policy if exists "Users can create reports" on public.reports;
drop policy if exists "Users can update own reports" on public.reports;
drop policy if exists "Users can update own pending reports" on public.reports;
drop policy if exists "Admins can view all reports" on public.reports;
drop policy if exists "Admins can update all reports" on public.reports;
drop policy if exists "Admins can delete all reports" on public.reports;

-- Users can view their own reports
create policy "Users can view own reports"
on public.reports for select
to authenticated
using ( auth.uid() = user_id );

-- Users can create reports
create policy "Users can create reports"
on public.reports for insert
to authenticated
with check ( auth.uid() = user_id );

-- Users can update their own reports ONLY if status is 'pending'
create policy "Users can update own pending reports"
on public.reports for update
to authenticated
using ( auth.uid() = user_id )
with check ( auth.uid() = user_id and status = 'pending' );

-- ADMIN POLICIES FOR REPORTS
-- Admins can view all reports
create policy "Admins can view all reports"
on public.reports for select
to authenticated
using ( public.is_admin() );

-- Admins can update any report (e.g. change status)
create policy "Admins can update all reports"
on public.reports for update
to authenticated
using ( public.is_admin() );

-- Admins can delete reports
create policy "Admins can delete all reports"
on public.reports for delete
to authenticated
using ( public.is_admin() );


-- 5. STORAGE SETUP
-- Create the storage bucket 'report-images' if it doesn't exist
insert into storage.buckets (id, name, public)
values ('report-images', 'report-images', true)
on conflict (id) do nothing;

-- STORAGE POLICIES
-- Clean up old policies for this bucket
drop policy if exists "Report Images are publicly accessible" on storage.objects;
drop policy if exists "Users can upload report images" on storage.objects;
drop policy if exists "Users can upload their own report images" on storage.objects;
drop policy if exists "Users can update their own report images" on storage.objects;
drop policy if exists "Users can delete their own report images" on storage.objects;


-- Allow public read access to report images
create policy "Report Images are publicly accessible"
on storage.objects for select
to public
using ( bucket_id = 'report-images' );

-- Allow users to upload images to the bucket (Strict: {uid}/{filename})
create policy "Users can upload their own report images"
on storage.objects for insert
to authenticated
with check ( 
  bucket_id = 'report-images' 
  and (split_part(name, '/', 1) = auth.uid()::text)
);

-- Allow users to delete their own report images
create policy "Users can delete their own report images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'report-images'
  and (split_part(name, '/', 1) = auth.uid()::text)
);

-- 6. USER SIGNUP TRIGGER (Fixes RLS issues on Signup)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, username, role, created_at)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'username', split_part(new.email, '@', 1)),
    'user',
    now()
  );
  return new;
end;
$$;

-- Trigger
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- 7. ANNOUNCEMENTS TABLE SETUP
create table if not exists public.announcements (
  id uuid default gen_random_uuid() primary key,
  admin_id uuid references public.profiles(id) not null,
  title text not null,
  content text not null,
  department text not null,
  created_at timestamp with time zone default now() not null
);

-- Enable RLS
alter table public.announcements enable row level security;

-- Drop existing policies to prevent conflicts
drop policy if exists "Announcements are viewable by everyone" on public.announcements;
drop policy if exists "Admins can insert announcements" on public.announcements;
drop policy if exists "Admins can update announcements" on public.announcements;
drop policy if exists "Admins can delete announcements" on public.announcements;

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
