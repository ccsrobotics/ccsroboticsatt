begin;
set local role authenticated;
select set_config('request.jwt.claim.sub','7be72505-ff23-4f9b-ae6f-9d263d2d62bb',true);
insert into public.seasons(id,name,program,start_date,end_date) values('e1111111-2222-4333-8444-555555555555','Calendar verification','BEST Robotics','2026-01-01','2026-12-31');
insert into public.meetings(id,season_id,date,meeting_type) values('f1111111-2222-4333-8444-555555555555','e1111111-2222-4333-8444-555555555555','2026-10-29','Kickoff');
do $$ begin
 if not exists(select 1 from public.meetings where id='f1111111-2222-4333-8444-555555555555' and title='' and meeting_type='Kickoff') then raise exception 'Optional title or event type not saved'; end if;
 begin
 insert into public.meetings(season_id,date,meeting_type) values('e1111111-2222-4333-8444-555555555555','2026-10-30','Invalid');
 raise exception 'Invalid type allowed';
 exception when check_violation then null;
 end;
end $$;
update public.meetings set title='Test event',meeting_type='Mandatory meeting' where id='f1111111-2222-4333-8444-555555555555';
do $$ begin
 if not exists(select 1 from public.audit_logs where table_name='meetings' and record_id='f1111111-2222-4333-8444-555555555555' and operation='UPDATE' and new_data->>'meeting_type'='Mandatory meeting') then raise exception 'Event update audit missing'; end if;
end $$;
rollback;
select 'PASS: calendar date and event type save/read, optional title default, event type validation, event-change audit; fixtures rolled back' as result;
