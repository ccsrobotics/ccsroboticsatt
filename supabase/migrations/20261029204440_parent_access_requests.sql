create table public.parent_requests (
 id uuid primary key default gen_random_uuid(),
 parent_user_id uuid not null default auth.uid() references auth.users(id),
 parent_email text not null default '',
 parent_name text not null check(length(trim(parent_name)) between 1 and 150),
 child_name text not null check(length(trim(child_name)) between 1 and 200),
 relationship text not null check(length(trim(relationship)) between 1 and 100),
 note text not null default '' check(length(note)<=1000),
 status text not null default 'pending' check(status in ('pending','approved','denied','revoked')),
 student_id uuid references public.students(id),
 admin_note text not null default '' check(length(admin_note)<=1000),
 created_at timestamptz not null default now(),
 reviewed_at timestamptz,
 reviewed_by uuid references auth.users(id),
 check(status<>'approved' or student_id is not null)
);
alter table public.parent_requests enable row level security;
create unique index parent_request_pending_unique on public.parent_requests(parent_user_id,lower(trim(child_name))) where status='pending';
create index parent_requests_parent_student on public.parent_requests(parent_user_id,student_id) where status='approved';
create index parent_requests_student on public.parent_requests(student_id);
create index parent_requests_reviewer on public.parent_requests(reviewed_by);
create index parent_requests_status on public.parent_requests(status,created_at);
create policy request_read on public.parent_requests for select to authenticated using(parent_user_id=(select auth.uid()) or (select private.is_admin()));
create policy request_submit on public.parent_requests for insert to authenticated with check(parent_user_id=(select auth.uid()) and status='pending' and student_id is null and reviewed_at is null and reviewed_by is null);
create policy request_review on public.parent_requests for update to authenticated using((select private.is_admin())) with check((select private.is_admin()));
grant select on public.parent_requests to authenticated;
grant insert(parent_name,child_name,relationship,note) on public.parent_requests to authenticated;
grant update(status,student_id,admin_note) on public.parent_requests to authenticated;
create function private.prepare_parent_request() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Sign in required'; end if;
 if TG_OP='INSERT' then
   select email into new.parent_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
   if new.parent_email is null then raise exception 'Verify your email before requesting access'; end if;
   if (select count(*) from public.parent_requests where parent_user_id=auth.uid() and status='pending')>=5 then raise exception 'You already have five pending requests. Please wait for review.'; end if;
 else
   if not private.is_admin() then raise exception 'Administrator approval required'; end if;
   new.reviewed_at=now(); new.reviewed_by=auth.uid();
 end if;
 return new;
end $$;
revoke all on function private.prepare_parent_request() from public;
create trigger prepare_parent_request before insert or update on public.parent_requests for each row execute function private.prepare_parent_request();
create trigger audit_parent_request after insert or update on public.parent_requests for each row execute function private.audit_change();
create function private.can_view_student(target uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.parent_requests where parent_user_id=auth.uid() and student_id=target and status='approved')
$$;
revoke all on function private.can_view_student(uuid) from public;
grant execute on function private.can_view_student(uuid) to authenticated;
create policy parent_read on public.students for select to authenticated using(private.can_view_student(id));
create policy parent_read on public.rosters for select to authenticated using(private.can_view_student(student_id));
create policy parent_read on public.attendance for select to authenticated using(private.can_view_student(student_id));
create policy parent_read on public.discipline for select to authenticated using(private.can_view_student(student_id));
create policy parent_read on public.seasons for select to authenticated using(exists(select 1 from public.rosters r where r.season_id=seasons.id and private.can_view_student(r.student_id)));
create policy parent_read on public.meetings for select to authenticated using(exists(select 1 from public.rosters r where r.season_id=meetings.season_id and private.can_view_student(r.student_id)));
