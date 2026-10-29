import test from 'node:test';
import assert from 'node:assert/strict';
import {stats,csv,xml} from '../domain.js';
test('excused absences are excluded and empty attendance has no rate',()=>{assert.equal(stats([]).rate,null);assert.equal(stats([{status:'E'}]).rate,null);assert.equal(stats([{status:'Present'},{status:'UE'},{status:'E'}]).rate,50);});
test('minimum and target counts include future meetings in denominator',()=>{const s=stats([...Array(6)].map(()=>({status:'Present'})).concat([...Array(4)].map(()=>({status:'UE'}))));assert.equal(s.minimum,4);assert.equal(s.target,6);assert.ok(stats([...Array(10)].map(()=>({status:'Present'})).concat([...Array(4)].map(()=>({status:'UE'})))).rate>=70);});
test('CSV quotes delimiters and neutralizes spreadsheet formulas',()=>{assert.ok(csv([['=1+1','a,"b']]).includes('"\'=1+1","a,""b"'));});
test('Excel XML escapes untrusted values and uses strings',()=>{const out=xml([['<script>&"','=1+1']]);assert.ok(out.includes('&lt;script&gt;&amp;&quot;'));assert.ok(out.includes('ss:Type="String">=1+1'));});
