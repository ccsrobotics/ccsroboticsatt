import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
import {stats,csv,xml} from '../domain.js';
import {statusCode,meetingLabel} from '../calendar.js';
const source=await readFile(new URL('../app.js',import.meta.url),'utf8');
test('real CSV and Excel downloads contain P, AE, EU and meeting types',async()=>{
 const ms=[{id:'m1',date:'2026-10-01',title:'',meeting_type:'Gameday'},{id:'m2',date:'2026-10-02',title:'Kickoff session',meeting_type:'Kickoff'},{id:'m3',date:'2026-10-03',title:'',meeting_type:'Mandatory meeting'}];
 const attendance=['Present','E','UE'].map((status,i)=>({meeting_id:ms[i].id,status}));
 const downloads=[];const urls=new Map();
 const context={data:{seasons:[{id:'season',name:'BEST 2026'}],discipline:[]},season:'season',student:'',tab:'Dashboard',roster:()=>[{id:'s',name:'Child',grade:'7'}],meetings:()=>ms,records:()=>attendance,stats,csv,xml,statusCode,meetingLabel,rate:s=>s.rate.toFixed(1)+'%',Blob,window:{URL:{createObjectURL:blob=>{const id=String(urls.size);urls.set(id,blob);return id;},revokeObjectURL:()=>{}}},document:{createElement:()=>({click(){downloads.push({name:this.download,blob:urls.get(this.href)});}})},setTimeout:()=>{}};
 vm.createContext(context);vm.runInContext(source.slice(source.indexOf('function download(format)')),context);
 vm.runInContext("download('csv');download('xml');",context);
 const csvText=await downloads[0].blob.text(),excelText=await downloads[1].blob.text();
 assert.equal(downloads[0].name,'ccs-attendance.csv');
 for(const code of ['P','AE','EU']){assert.ok(csvText.includes('"'+code+'"'));assert.ok(excelText.includes('>'+code+'</Data>'));}
 for(const type of ['Gameday','Kickoff','Mandatory meeting'])assert.ok(csvText.includes(type));
 assert.ok(csvText.includes('"Meeting type"'));
});
