import test from 'node:test';
import assert from 'node:assert/strict';
import {parentPortal,requestQueue} from '../parent.js';
const esc=v=>String(v??'').replaceAll('<','&lt;').replaceAll('>','&gt;');
const options=rows=>rows.map(r=>`<option value="${r.id}">${esc(r.name)}</option>`).join('');
test('parent portal has child information and requests without administrator controls',()=>{
 const elements=new Map();const previous=globalThis.document;
 globalThis.document={querySelector:id=>{if(!elements.has(id))elements.set(id,{});return elements.get(id);}};
 try{parentPortal({data:{students:[{id:'child',name:'Approved child',grade:'7'}],seasons:[{id:'season',name:'BEST 2026'}],rosters:[{student_id:'child',season_id:'season'}],meetings:[],attendance:[],discipline:[],parent_requests:[]},season:'season',esc,options,rate:()=> '75%',reload:async()=>{},notice:()=>{},selectSeason:()=>{}});const html=elements.get('#workspace').innerHTML;assert.match(html,/Approved child/);assert.match(html,/Request access to a child/);assert.doesNotMatch(html,/Create season|Schedule a meeting|Add a student|Export CSV|audit trail|Team attendance|data-review/);}finally{globalThis.document=previous;}
});
test('review queue escapes requester text and requires student matching control',()=>{const html=requestQueue({requests:[{id:'r',parent_name:'<script>',parent_email:'parent@example.invalid',child_name:'Child',relationship:'Parent',status:'pending',created_at:'2026-10-29T00:00:00Z'}],students:[{id:'child',name:'Correct child'}],esc,options});assert.match(html,/&lt;script&gt;/);assert.match(html,/Select the verified child/);assert.match(html,/value="approved"/);assert.doesNotMatch(html,/<script>/);});
