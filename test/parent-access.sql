begin;
insert into auth.users(id,email,email_confirmed_at) values
('a1111111-2222-4333-8444-555555555555','parent-test@example.invalid',now()),
('a2111111-2222-4333-8444-555555555555','other-parent-test@example.invalid',now());
insert into public.students(id,name) values
('b1111111-2222-4333-8444-555555555555','Parent test child'),
('b2111111-2222-4333-8444-555555555555','Other test child');
insert into public.seasons(id,name,program,start_date,end_date) values ('c1111111-2222-4333-8444-555555555555','Parent test season','BEST Robotics','2026-01-01','2026-12-31');
insert into public.rosters values ('c1111111-2222-4333-8444-555555555555','b1111111-2222-4333-8444-555555555555'),('c1111111-2222-4333-8444-555555555555','b2111111-2222-4333-8444-555555555555');
insert into public.meetings(id,season_id,date,title) values ('d1111111-2222-4333-8444-555555555555','c1111111-2222-4333-8444-555555555555','2026-10-29','Parent test meeting');
insert into public.attendance(season_id,student_id,meeting_id,status) values
('c1111111-2222-4333-8444-555555555555','b1111111-2222-4333-8444-555555555555','d1111111-2222-4333-8444-555555555555','Present'),
('c1111111-2222-4333-8444-555555555555','b2111111-2222-4333-8444-555555555555','d1111111-2222-4333-8444-555555555555','UE');
insert into public.discipline(season_id,student_id,kind,reason,start_date) values
('c1111111-2222-4333-8444-555555555555','b1111111-2222-4333-8444-555555555555','Formal warning','Test','2026-10-29'),
('c1111111-2222-4333-8444-555555555555','b2111111-2222-4333-8444-555555555555','Suspension','Test','2026-10-29');
set local role authenticated;
select set_config('request.jwt.claim.sub','a1111111-2222-4333-8444-555555555555',true);
insert into public.parent_requests(parent_name,child_name,relationship,note) values ('Test parent','Parent test child','Parent','Please verify');
do $$ begin
 if exists(select 1 from public.students) or exists(select 1 from public.attendance) or exists(select 1 from public.seasons) or exists(select 1 from public.meetings) or exists(select 1 from public.discipline) then raise exception 'Pending parent can access student information'; end if;
 if not exists(select 1 from public.parent_requests where parent_email='parent-test@example.invalid' and status='pending') then raise exception 'Request submission failed'; end if;
 if exists(select 1 from public.administrators) or exists(select 1 from public.audit_logs) then raise exception 'Parent can access administrator information'; end if;
 update public.parent_requests set status='approved',student_id='b1111111-2222-4333-8444-555555555555';
 if found then raise exception 'Parent self-approval allowed'; end if;
 begin
 insert into public.parent_requests(parent_name,child_name,relationship,status,student_id) values('Attacker','Other child','Parent','approved','b2111111-2222-4333-8444-555555555555');
 raise exception 'Parent forged approval';
 exception when insufficient_privilege then null;
 end;
end $$;
select set_config('request.jwt.claim.sub','7be72505-ff23-4f9b-ae6f-9d263d2d62bb',true);
update public.parent_requests set status='approved',student_id='b1111111-2222-4333-8444-555555555555' where parent_user_id='a1111111-2222-4333-8444-555555555555';
do $$ begin
 if not exists(select 1 from public.parent_requests where parent_user_id='a1111111-2222-4333-8444-555555555555' and reviewed_by=auth.uid() and reviewed_at is not null) then raise exception 'Review attribution missing'; end if;
end $$;
select set_config('request.jwt.claim.sub','a1111111-2222-4333-8444-555555555555',true);
do $$ begin
 if (select count(*) from public.students)<>1 or (select count(*) from public.rosters)<>1 or (select count(*) from public.attendance)<>1 or (select count(*) from public.discipline)<>1 then raise exception 'Child isolation failed'; end if;
 if not exists(select 1 from public.students where id='b1111111-2222-4333-8444-555555555555') then raise exception 'Wrong child visible'; end if;
 if (select count(*) from public.seasons)<>1 or (select count(*) from public.meetings)<>1 then raise exception 'Approved season information missing'; end if;
 update public.attendance set status='UE',reason='Unauthorized parent correction';
 if found then raise exception 'Parent can modify attendance'; end if;
 update public.students set name='Unauthorized parent rename';
 if found then raise exception 'Parent can modify student'; end if;
 update public.discipline set reason='Unauthorized change';
 if found then raise exception 'Parent can modify discipline'; end if;
end $$;
select set_config('request.jwt.claim.sub','a2111111-2222-4333-8444-555555555555',true);
do $$ begin
 if exists(select 1 from public.students) or exists(select 1 from public.parent_requests) or exists(select 1 from public.attendance) then raise exception 'Another parent can see data'; end if;
end $$;
select set_config('request.jwt.claim.sub','7be72505-ff23-4f9b-ae6f-9d263d2d62bb',true);
update public.parent_requests set status='revoked' where parent_user_id='a1111111-2222-4333-8444-555555555555';
select set_config('request.jwt.claim.sub','a1111111-2222-4333-8444-555555555555',true);
do $$ begin
 if exists(select 1 from public.students) or exists(select 1 from public.attendance) or exists(select 1 from public.seasons) or exists(select 1 from public.meetings) or exists(select 1 from public.discipline) then raise exception 'Revocation failed'; end if;
end $$;
rollback;
select 'PASS: pending isolation, request ownership, self-approval denial, administrator review, child-only read access, parent write denial, unrelated parent isolation, immediate revocation; fixtures rolled back' as result;
