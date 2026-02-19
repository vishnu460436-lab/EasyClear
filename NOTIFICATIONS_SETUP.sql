-- 1. Create Notifications Table
create table if not exists public.notifications (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  message text not null,
  is_read boolean default false not null,
  created_at timestamp with time zone default now() not null
);

-- Enable RLS
alter table public.notifications enable row level security;

-- notifications policies
drop policy if exists "Users can view own notifications" on public.notifications;
drop policy if exists "Users can update own notifications" on public.notifications;

create policy "Users can view own notifications"
on public.notifications for select
to authenticated
using ( auth.uid() = user_id );

create policy "Users can update own notifications"
on public.notifications for update
to authenticated
using ( auth.uid() = user_id );

-- 2. Create Trigger Function
create or replace function public.handle_report_status_notification()
returns trigger
language plpgsql
security definer
as $$
begin
  if (old.status is distinct from new.status) then
    insert into public.notifications (user_id, title, message)
    values (
      new.user_id,
      'Status Updated: ' || new.title,
      'Your report has been updated to: ' || upper(new.status)
    );
  end if;
  return new;
end;
$$;

-- 3. Attach Trigger
drop trigger if exists on_report_status_change on public.reports;
create trigger on_report_status_change
  after update on public.reports
  for each row
  execute procedure public.handle_report_status_notification();
