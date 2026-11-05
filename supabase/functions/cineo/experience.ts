import {context} from './experience-core.ts';
import {viewerApi} from './experience-viewer.ts';
import {studioApi} from './experience-studio.ts';
import {deskApi} from './experience-desk.ts';
import {opsApi} from './experience-ops.ts';
export async function experienceApi(input:any){const c=await context({...input,path:input.path.replace(/^\/v8/,'')});if(c.viewer?.kids){const path=c.path;const read=/^\/(bootstrap|preferences|progress|library|recommendations|search|bookmarks|calendar|inbox|surveys|news|version|episode\/\d+\/recap|polls\/\d+)$/.test(path);const write=/^\/(preferences|progress|library-choice|reset-recommendations|bookmarks|inbox|surveys|polls\/\d+|quality)$/.test(path);c.check(c.req.method==='GET'?read:write,'Esta área precisa do perfil do responsável.');}for(const handle of [viewerApi,studioApi,deskApi,opsApi]){const response=await handle(c);if(response)return response;}return c.response({error:'Ferramenta não encontrada.'},404);}
