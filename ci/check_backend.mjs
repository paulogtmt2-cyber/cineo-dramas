import {readFile} from 'node:fs/promises';
import {stripTypeScriptTypes} from 'node:module';
import vm from 'node:vm';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';
import {fileURLToPath} from 'node:url';
const base=new URL('../supabase/functions/cineo/',import.meta.url),hashes={};
for(const name of ['index.ts','pro.ts','complete.ts','platform.ts']){const source=await readFile(new URL(name,base),'utf8');hashes[name]=createHash('sha256').update(source).digest('hex');const js=stripTypeScriptTypes(source,{mode:'strip'}).replace(/^import .*;\s*$/gm,'').replace(/^export /gm,'');new vm.Script(js,{filename:name});}
const pro=await import(new URL('pro.ts',base)),complete=await import(new URL('complete.ts',base)),platform=await import(new URL('platform.ts',base));
for(const fn of [pro.proApi,pro.notifyPublished,complete.completeApi,platform.platformApi,platform.mediaWorker,platform.viewerContext])assert.equal(typeof fn,'function');
console.log(JSON.stringify({syntax:'passed',module_exports:'passed',sha256:hashes}));
