import test from 'node:test';
import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import vm from 'node:vm';
const script=await readFile(new URL('../theme.js',import.meta.url),'utf8');
function run(saved,systemDark,blocked=false){let click;const attrs={};const button={textContent:'',setAttribute:(k,v)=>attrs[k]=v,addEventListener:(event,fn)=>click=fn};const root={dataset:{}};const values=new Map(saved?[['carss-theme',saved]]:[]);vm.runInNewContext(script,{document:{querySelector:()=>button,documentElement:root},window:{matchMedia:()=>({matches:systemDark})},localStorage:{getItem:k=>{if(blocked)throw Error('blocked');return values.get(k);},setItem:(k,v)=>values.set(k,v)}});return {button,root,attrs,values,click:()=>click()};}
test('theme follows system then stores explicit choice',()=>{const t=run(null,true);assert.equal(t.root.dataset.theme,'dark');assert.equal(t.button.textContent,'Light mode');t.click();assert.equal(t.root.dataset.theme,'light');assert.equal(t.values.get('carss-theme'),'light');assert.equal(t.attrs['aria-pressed'],'false');});
test('saved theme takes precedence and blocked storage does not break UI',()=>{assert.equal(run('light',true).root.dataset.theme,'light');assert.equal(run('dark',false).root.dataset.theme,'dark');const t=run(null,false,true);t.click();assert.equal(t.root.dataset.theme,'dark');});
