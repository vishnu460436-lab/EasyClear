-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- PROFILES TABLE
create table public.profiles (
  id uuid references auth.users not null primary key,
  username text,
  full_name text,
  avatar_url text,
  location text default 'Kochi, Kerala',
  role text default 'user', -- 'user', 'admin', 'official'
  department text, -- For officials (e.g., 'KSEB', 'Water Authority')
  total_reports int default 0,
  resolved_reports int default 0,
  impact_points int default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Profiles
alter table public.profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );

-- REPORTS TABLE
create table public.reports (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references public.profiles(id) not null,
  title text not null,
  description text not null,
  category text not null, -- 'pwd', 'water', 'kseb', 'police', 'other'
  location_address text,
  latitude double precision,
  longitude double precision,
  image_url text,
  status text default 'pending', -- 'pending', 'in_progress', 'resolved', 'rejected'
  admin_notes text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for Reports
alter table public.reports enable row level security;

create policy "Reports are viewable by everyone."
  on reports for select
  using ( true );

create policy "Users can create reports."
  on reports for insert
  with check ( auth.uid() = user_id );

create policy "Users can update their own reports."
  on reports for update
  using ( auth.uid() = user_id );

-- STORAGE BUCKETS (for images)
-- Note: You'll need to create a bucket named 'report-images' and 'avatars' in the Supabase Dashboard > Storage

-- FUNCTIONS & TRIGGERS

-- Function to handle new user signup (Optional: if you want DB to handle profile creation instead of App)
-- currently the App handles it, but this is a failsafe.
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, username, full_name, role)
  values (new.id, new.raw_user_meta_data->>'name', new.raw_user_meta_data->>'full_name', 'user');
  return new;
end;
$$ language plpgsql security definer;

-- trigger the function every time a user is created
-- create trigger on_auth_user_created
--   after insert on auth.users
--   for each row execute procedure public.handle_new_user();
