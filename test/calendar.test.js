import test from 'node:test';
import assert from 'node:assert/strict';
import {monthDays,shiftMonth,calendarView,attendancePanel,statusCode,meetingLabel,selectedStatus} from '../calendar.js';
const esc=v=>String(v??'').replaceAll('<','&lt;').replaceAll('>','&gt;');
test('calendar handles leap years and month/year boundaries',()=>{
 assert.deepEqual(monthDays('2024-02'),{offset:4,count:29});
 assert.equal(monthDays('2025-02').count,28);
 assert.equal(shiftMonth('2026-12',1),'2027-01');
 assert.equal(shiftMonth('2026-01',-1),'2025-12');
 const html=calendarView({month:'2024-02',selectedDate:'2024-02-29',meetings:[{date:'2024-02-29',title:'',meeting_type:'Kickoff'}],esc});
 assert.match(html,/data-date="2024-02-29" class="calendar-day selected"/);
 assert.doesNotMatch(html,/data-date="2024-02-30"/);
 assert.match(html,/<small>Kickoff<\/small>/);
});
test('status codes preserve legacy records and reject conflicting choices',()=>{
 assert.equal(statusCode('Present'),'P');assert.equal(statusCode('E'),'EA');assert.equal(statusCode('UE'),'UA');assert.equal(statusCode(undefined),'Unmarked');
 assert.equal(selectedStatus([]),'');assert.equal(selectedStatus(['E']),'E');assert.throws(()=>selectedStatus(['E','Present']),/only one/);
 assert.equal(meetingLabel({title:'  ',meeting_type:'Gameday'}),'Gameday');
});
test('new meeting allows no title, all event types, and explicit checkboxes',()=>{
 const html=attendancePanel({month:'2026-10',selectedDate:'2026-10-29',meeting:'',meetings:[],students:[{id:'student',name:'A child'}],attendance:[],season:'season',esc,options:()=>''});
 assert.match(html,/Meeting title \(optional\)/);assert.doesNotMatch(html,/name="title"[^>]*required/);
 for(const type of ['Gameday','Kickoff','Mandatory meeting'])assert.ok(html.includes(type));
 assert.equal((html.match(/type="checkbox"/g)||[]).length,3);
 assert.match(html,/Excused Absence/);assert.match(html,/Unexcused Absence/);
 assert.doesNotMatch(html,/type="checkbox"[^>]*checked/);
});
