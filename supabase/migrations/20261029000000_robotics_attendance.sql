create schema if not exists private;
revoke all on schema private from public;
create table public.administrators (user_id uuid primary key references auth.users(id), created_at timestamptz not null default now());
alter table public.administrators enable row level security;
create policy own_admin on public.administrators for select to authenticated using (user_id=(select auth.uid()));
grant select on public.administrators to authenticated;
create function private.is_admin() returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.administrators where user_id=auth.uid())
$$;
revoke all on function private.is_admin() from public;
grant usage on schema private to authenticated;
grant execute on function private.is_admin() to authenticated;
create table public.students(id uuid primary key default gen_random_uuid(), name text not null check(length(trim(name))>0), grade text not null default '', active boolean not null default true, created_at timestamptz not null default now());
create table public.seasons(id uuid primary key default gen_random_uuid(),name text not null, program text not null check(program in ('BEST Robotics','BattleBots / Rocketry')),start_date date not null,end_date date not null,check(end_date>=start_date));
create table public.rosters(season_id uuid references public.seasons(id),student_id uuid references public.students(id),primary key(season_id,student_id));
create table public.meetings(id uuid primary key default gen_random_uuid(),season_id uuid not null references public.seasons(id),date date not null,title text not null,unique(id,season_id));
create table public.attendance(id uuid primary key default gen_random_uuid(),season_id uuid not null,student_id uuid not null,meeting_id uuid not null,status text not null check(status in ('Present','E','UE')),reason text not null default '',updated_at timestamptz not null default now(),foreign key(season_id,student_id) references public.rosters(season_id,student_id),foreign key(meeting_id,season_id) references public.meetings(id,season_id),unique(meeting_id,student_id));
create table public.discipline(id uuid primary key default gen_random_uuid(),season_id uuid not null,student_id uuid not null,kind text not null check(kind in ('Formal warning','Suspension')),reason text not null check(length(trim(reason))>0),start_date date not null,end_date date,created_at timestamptz not null default now(),foreign key(season_id,student_id) references public.rosters(season_id,student_id),check(end_date is null or end_date>=start_date));
create table public.audit_logs(id bigint generated always as identity primary key,actor uuid references auth.users(id),table_name text not null,record_id text,operation text not null,old_data jsonb,new_data jsonb,created_at timestamptz not null default now());
create function private.audit_change() returns trigger language plpgsql security definer set search_path='' as $$
begin
 if TG_TABLE_NAME='attendance' and TG_OP='UPDATE' then
  if new.status is distinct from old.status and length(trim(new.reason))=0 then raise exception 'A correction reason is required'; end if;
  new.updated_at=now();
 end if;
 insert into public.audit_logs(actor,table_name,record_id,operation,old_data,new_data)
 values(auth.uid(),TG_TABLE_NAME,coalesce(to_jsonb(new)->>'id',to_jsonb(old)->>'id',to_jsonb(new)->>'student_id',to_jsonb(old)->>'student_id'),TG_OP,case when TG_OP<>'INSERT' then to_jsonb(old) end,case when TG_OP<>'DELETE' then to_jsonb(new) end);
 if TG_OP='DELETE' then return old; end if; return new;
end $$;
revoke all on function private.audit_change() from public;
do $$ declare t text; begin
 foreach t in array array['students','seasons','rosters','meetings','attendance','discipline'] loop
 execute format('alter table public.%I enable row level security',t);
 execute format('create policy admin_access on public.%I for all to authenticated using ((select private.is_admin())) with check ((select private.is_admin()))',t);
 execute format('grant select,insert,update on public.%I to authenticated',t);
 execute format('create trigger audit_change before insert or update or delete on public.%I for each row execute function private.audit_change()',t);
 end loop;
end $$;
alter table public.audit_logs enable row level security;
create policy admin_read on public.audit_logs for select to authenticated using ((select private.is_admin()));
grant select on public.audit_logs to authenticated;
create index on public.rosters(student_id);
create index on public.meetings(season_id);
create index on public.attendance(season_id,student_id);
create index on public.discipline(season_id,student_id);
create index on public.audit_logs(created_at desc);
