-- Transactional integration check; leaves no test accounts or student records.
begin;
insert into auth.users(id,email) values ('11111111-2222-4333-8444-555555555555','robotics-verification@example.invalid');
insert into public.administrators(user_id) values ('11111111-2222-4333-8444-555555555555');
set local role authenticated;
select set_config('request.jwt.claim.sub','11111111-2222-4333-8444-555555555555',true);
insert into public.students(id,name) values ('21111111-2222-4333-8444-555555555555','Verification only');
insert into public.seasons(id,name,program,start_date,end_date) values ('31111111-2222-4333-8444-555555555555','Verification','BEST Robotics','2026-01-01','2026-12-31');
insert into public.rosters values ('31111111-2222-4333-8444-555555555555','21111111-2222-4333-8444-555555555555');
insert into public.meetings(id,season_id,date,title) values ('41111111-2222-4333-8444-555555555555','31111111-2222-4333-8444-555555555555','2026-10-29','Verification');
insert into public.attendance(season_id,student_id,meeting_id,status) values ('31111111-2222-4333-8444-555555555555','21111111-2222-4333-8444-555555555555','41111111-2222-4333-8444-555555555555','Present');
do $$ begin
 if (select count(*) from public.attendance where meeting_id='41111111-2222-4333-8444-555555555555' and status='Present')<>1 then raise exception 'Save/read failed'; end if;
 begin
 update public.attendance set status='UE' where meeting_id='41111111-2222-4333-8444-555555555555';
 raise exception 'Expected correction validation failure';
 exception when others then if SQLERRM <> 'A correction reason is required' then raise; end if;
 end;
end $$;
update public.attendance set status='E',reason='Verified correction' where meeting_id='41111111-2222-4333-8444-555555555555';
do $$ begin
 if not exists(select 1 from public.audit_logs where actor='11111111-2222-4333-8444-555555555555' and table_name='attendance' and operation='UPDATE' and old_data->>'status'='Present' and new_data->>'status'='E') then raise exception 'Audit verification failed'; end if;
end $$;
select set_config('request.jwt.claim.sub','',true);
do $$ begin
 if exists(select 1 from public.students) then raise exception 'RLS isolation failed'; end if;
 begin
 insert into public.students(name) values ('Unauthorized');
 raise exception 'Expected write denial';
 exception when insufficient_privilege then null;
 end;
end $$;
rollback;
select 'PASS: administrator save/read, correction validation, audit old/new values, unauthorized read/write isolation; test data rolled back' as result;
