import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
test('public files have valid UTF-8 and no corrupted punctuation',async()=>{
 for(const path of ['index.html','app.js','parent.js','calendar.js','style.css','theme.js']){
  const bytes=await readFile(new URL('../'+path,import.meta.url));
  const text=new TextDecoder('utf-8',{fatal:true}).decode(bytes);
  assert.doesNotMatch(text,/\u00e2\u20ac|\u00e2\u2020|\u00c2\u00b7|\ufffd/,path);
  assert.doesNotMatch(text,/Show up\. Build|Every meeting moves us forward|Your next milestone|BUILD TOGETHER/);
 }
 const html=await readFile(new URL('../index.html',import.meta.url),'utf8');
 assert.match(html,/Sign in to workspace &rarr;/);
 assert.match(html,/<title>CARSS Dashboard site<\/title>/);
});
