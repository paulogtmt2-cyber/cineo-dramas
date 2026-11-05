import {launchApi} from './launch.ts';
import {studioApi,decorateExperiments} from './studio.ts';
import {creatorsApi,creatorGate} from './creators.ts';
import {fastApi,signedPaths} from './fast.ts';
import {experienceApi} from './experience.ts';
import {platformApi,viewerContext,allowed,aired,mediaWorker} from './platform.ts';
import {proApi,notifyPublished} from './pro.ts';
import {completeApi} from './complete.ts';
import {createClient} from 'npm:@supabase/supabase-js@2.57.4';
const url=Deno.env.get('SUPABASE_URL')!;
const opts={auth:{persistSession:false,autoRefreshToken:false}};
const baseResponse=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
function check(ok:unknown,message:string){if(!ok)throw new Error(message)}
function result(r:any){if(r.error)throw new Error(r.error.message);return r.data}
function friendly(message:string){if(message.includes('cineo_monthly_settlements_creator_id_month_key'))return 'Este mês já foi fechado.';if(message.includes('cineo_payment_reference_idx'))return 'Esta referência já foi registrada.';if(message.includes('cineo_ab_one_active_idx'))return 'Já existe um teste ativo deste tipo.';if(message.includes('cineo_episode_chapter_idx'))return 'Este número de episódio já existe nesta temporada. Escolha outro.';if(message.includes('Email not confirmed'))return 'Confirme seu email antes de entrar. Confira também a pasta de spam.';if(message.includes('Invalid login credentials'))return 'Email ou senha incorretos.';if(message.includes('rate limit'))return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';return message;}
Deno.serve(async req=>{
 const receivedAt=Date.now();
 const db=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,opts);
 const response=(data:unknown,status=200)=>{const task=db.rpc('cineo_count_traffic',{incoming:Math.min(36000000,Math.max(0,Number(req.headers.get('content-length'))||0)),outgoing:new TextEncoder().encode(JSON.stringify(data)).length}).then(()=>{},()=>{});const runtime=(globalThis as any).EdgeRuntime;if(runtime)runtime.waitUntil(task);return baseResponse(data,status);};
 try{
 const route=new URL(req.url), parts=route.pathname.split('/'), fn=parts.findIndex(s=>s==='cineo'||s==='cineo-preview'), path=fn>=0?('/'+parts.slice(fn+1).join('/')):'/';
 if(path==='/health')return response({ok:true,version:'0.8.0'});

 if(path==='/version'&&req.method==='GET'){const r=await db.from('cineo_release').select('version_code,version_name,notes,download_url').eq('id',1).single();return response(result(r));}
 if(path.startsWith('/v7/worker/'))return await mediaWorker(req,db,path,response,result);
 if(path==='/guest'&&req.method==='GET'){const rows=result(await db.from('cineo_shows').select('id,title,synopsis,genre,rating,cover_path,banner_path,status,hidden,premiere_at,finished,created_at').eq('status','approved').eq('hidden',false).or('premiere_at.is.null,premiere_at.lte.'+new Date().toISOString()).order('id',{ascending:false}).limit(30));const items=await Promise.all(rows.map(async(s:any)=>({...s,cover_url:s.cover_path?(await db.storage.from('cineo-covers').createSignedUrl(s.cover_path,3600)).data?.signedUrl:''})));return response({items});}
 if(path==='/open'&&req.method==='GET'){const id=Number(route.searchParams.get('id')),episode=Number(route.searchParams.get('episode'))||0;check(Number.isSafeInteger(id)&&id>0,'Série inválida.');const r=result(await db.from('cineo_release').select('download_url').eq('id',1).single());const link='cineo://show/'+id+(episode?'?episode='+episode:'');const html='<!doctype html><html lang="pt-BR"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Cineo / Dramas</title><body style="background:#090d14;color:white;font-family:sans-serif;padding:32px"><h1>CINEO / DRAMAS</h1><p>Sua próxima história espera por você.</p><p><a style="color:#ff4778" href="'+link+'">Abrir no Cineo</a></p><p><a style="color:#69d49b" href="'+r.download_url.replaceAll('"','&quot;')+'">Baixar o aplicativo Android</a></p></body></html>';return new Response(html,{headers:{'Content-Type':'text/html; charset=utf-8','Content-Security-Policy':"default-src 'none'; style-src 'unsafe-inline'"}});}
 const auth=createClient(url,Deno.env.get('SUPABASE_ANON_KEY')!,opts);
 const token=(req.headers.get('Authorization')||'').replace(/^Bearer /,'');
 const data=req.method==='POST'?await req.json():{};
 if(['/register','/login','/refresh','/resend'].includes(path)){
 check(req.method==='POST','Método inválido');
 const credentials={email:String(data.email||'').trim().toLowerCase(),password:String(data.password||'')};
 if(path==='/resend'){const r=await auth.auth.resend({type:'signup',email:credentials.email});if(r.error)throw r.error;return response({ok:true,message:'Confira seu email e a pasta de spam.'});}
 if(path!=='/refresh')check(credentials.password.length>=8,'Use uma senha de pelo menos 8 caracteres.');
 const r=path==='/register'?await auth.auth.signUp(credentials):path==='/refresh'?await auth.auth.refreshSession({refresh_token:String(data.refresh_token||'')}):await auth.auth.signInWithPassword(credentials);
 if(r.error)throw new Error(r.error.message);
 if(!r.data.session)return response({confirmation_required:true,message:'Confira seu email e confirme o cadastro antes de entrar.'});
 const admin=result(await db.from('cineo_admins').select('user_id').eq('user_id',r.data.user!.id).maybeSingle());
 return response({token:r.data.session.access_token,refresh_token:r.data.session.refresh_token,expires_at:r.data.session.expires_at,uid:r.data.user!.id,email:r.data.user!.email,role:admin?'admin':'creator'});
 }
 const {data:identity,error}=await auth.auth.getUser(token);
 if(error||!identity.user)return response({error:'Sessão expirada. Entre novamente.'},401);
 const uid=identity.user.id;
 let sessionId='';try{sessionId=JSON.parse(atob(token.split('.')[1].replaceAll('-','+').replaceAll('_','/'))).session_id||'';}catch{}check(/^[a-f0-9-]{36}$/.test(sessionId),'Sessão inválida.');
 const checks=await Promise.all([db.from('cineo_devices').select('revoked,last_seen').eq('session_id',sessionId).eq('user_id',uid).maybeSingle(),db.from('cineo_erasure').select('user_id').eq('user_id',uid).maybeSingle(),db.from('cineo_admins').select('user_id').eq('user_id',uid).maybeSingle(),viewerContext(db,uid,req,sessionId).then(viewer=>({viewer})).catch(error=>({viewer:null,error}))]);
 const device=result(checks[0]),erasure=result(checks[1]),adminRow=result(checks[2]),selected=checks[3] as any;if(device?.revoked)return response({error:'Acesso encerrado neste aparelho.'},401);if(erasure)return response({error:'Conta em processo de exclusão. Fale com o suporte se precisar de ajuda.'},401);
 if(!device||Date.parse(device.last_seen)<Date.now()-300000)result(await db.from('cineo_devices').upsert({session_id:sessionId,user_id:uid,name:String(req.headers.get('X-Cineo-Device')||'Android').slice(0,80),last_seen:new Date().toISOString()}));
 let viewer=selected.viewer;if(selected.error&&!((path==='/v7/viewers'&&req.method==='GET')||path==='/v7/viewer-switch'||path==='/logout'))return response({error:'Escolha um perfil para continuar.',viewer_required:true},423);
 if(viewer?.kids&&!path.startsWith('/v8/')&&!path.startsWith('/v9/')&&!path.startsWith('/v10/view/')&&path!=='/v11/audience/impression'&&path!=='/v12/clips'){const forbidden=['/mine','/admin','/queue','/stats','/shows','/password','/v4/analytics','/v4/editorial','/v4/reports','/v4/episode-queue','/v7/shared','/v7/health','/v7/queue','/v7/appeals'];if(forbidden.includes(path)||(req.method==='POST'&&!/^\/(v4\/(progress|follow)|v6\/(rating|preferences|watched|history|lists)|v7\/(progress|saved|retention|viewer-switch|fault)|logout|shows\/\d+\/save)$/.test(path)))return response({error:'Esta ação precisa do perfil do responsável.'},403);}
 if(viewer?.kids&&!path.startsWith('/v8/')&&!path.startsWith('/v9/')&&!path.startsWith('/v10/view/')&&path!=='/v12/clips'&&!/^\/v10\/public-creator\/[a-f0-9-]{36}$/.test(path)&&req.method==='GET'&&!/^(\/catalog|\/saved|\/v4\/(profile|home|notifications|following|follow|creator\/[a-f0-9-]+|show\/\d+\/extras)|\/shows\/\d+(?:\/(episodes|social|save|comments))?|\/v6\/(preferences|categories|recommend|rating|history|lists|list\/\d+|art\/\d+|show\/\d+\/related)|\/v7\/(home|viewers|bulletins|thread\/\d+|episode\/\d+\/download))$/.test(path))return response({error:'Esta área precisa do perfil do responsável.'},403);
 const target=path.match(/^\/(?:shows|v4\/show|v6\/show|v7\/show|v6\/art)\/(\d+)/);if(viewer?.kids&&target){const s=result(await db.from('cineo_shows').select('*').eq('id',Number(target[1])).maybeSingle());if(!s||!allowed(s,viewer))return response({error:'Produção indisponível neste perfil.'},403);}

 const admin=!viewer?.kids&&!!adminRow;
 if(path==='/logout'&&req.method==='POST'){const r=await db.auth.admin.signOut(token,'local');if(r.error)throw r.error;return response({ok:true});}
 if(path==='/password'&&req.method==='POST'){
 check(String(data.password||'').length>=8,'Use pelo menos 8 caracteres.');
 const verify=await auth.auth.signInWithPassword({email:identity.user.email!,password:String(data.current||'')});if(verify.error)throw new Error('Senha atual incorreta.');
 const changed=await auth.auth.updateUser({password:String(data.password)});if(changed.error)throw changed.error;await auth.auth.signOut();return response({ok:true});
 }
 async function covers(rows:any[]){rows=rows.filter(s=>allowed(s,viewer));rows=await decorateExperiments({db,uid,result},rows);if(!rows.length)return [];const [metaResult,infoResult,urls,viewsResult]=await Promise.all([db.rpc('cineo_show_metadata',{ids:rows.map(s=>s.id)}),db.from('cineo_show_info').select('*').in('show_id',rows.map(s=>s.id)),signedPaths(db,'cineo-covers',rows.flatMap(s=>[s.cover_path,s.banner_path]).filter(Boolean)),db.rpc('cineo_public_views',{ids:rows.map(s=>s.id)})]);const viewCounts=result(viewsResult);const meta=result(metaResult),info=result(infoResult);return rows.map(s=>({...s,views:viewCounts.find((v:any)=>v.show_id===s.id)?.views||0,...meta.find((x:any)=>x.id===s.id),...info.find((x:any)=>x.show_id===s.id),cover_url:urls.get(s.cover_path)||'',banner_url:urls.get(s.banner_path)||'',cover_error:s.cover_path&&!urls.has(s.cover_path)?'Imagem indisponível':''}));}
 const ctx={db,uid,admin,req,data,route,receivedAt,covers,check,result,response,path,viewer,sid:sessionId,auth,email:identity.user.email};
 if(req.method==='POST'&&!['/logout'].includes(path)){const scope=path==='/v11/audience/impression'?'impressions':path.startsWith('/v10/view/')?'playback':path.startsWith('/v8/quality')?'quality':/\/(comments|report|support|polls|disputes)/.test(path)?'community':/uploads/.test(path)?'uploads':'actions';const limit=scope==='community'?30:scope==='quality'?30:scope==='uploads'?200:120;const ok=result(await db.rpc('cineo_request_budget',{actor:uid,bucket:scope,maximum:limit}));if(!ok)return response({error:'Muitas ações em pouco tempo. Aguarde um minuto.'},429);}
 if(path.startsWith('/v12/'))return await launchApi(ctx);
 if(path.startsWith('/v11/'))return await studioApi(ctx);
 if(path.startsWith('/v10/'))return await creatorsApi(ctx);
 await creatorGate(ctx);
 if(path.startsWith('/v9/')){const out=await fastApi(ctx);return out||response({error:'Rota não encontrada.'},404);}
 if(path.startsWith('/v8/'))return await experienceApi(ctx);
 const revisedArt=path.match(/^\/v6\/show\/(\d+)\/art$/);if(revisedArt&&req.method==='POST'){const s=result(await db.from('cineo_shows').select('status').eq('id',Number(revisedArt[1])).single());if(s.status==='approved')return await experienceApi({...ctx,path:'/v8/show/'+revisedArt[1]+'/proposals'});}
 if(path.startsWith('/v7/')){const out=await platformApi(ctx);if(out)return out;}
 if(viewer&&['/v6/history','/v6/watched'].includes(path)){const out=await platformApi({...ctx,path:path.replace('/v6/','/v7/')});if(out)return out;}
 if(['/v4/episode-submit','/v4/episode-review'].includes(path)&&req.method==='POST'&&(path.endsWith('submit')||data.decision==='approved')){const job=result(await db.from('cineo_media_jobs').select('status').eq('episode_id',Number(data.id)).maybeSingle());check(!job||job.status==='ready','Aguarde a validação técnica do capítulo.');}
 if(viewer&&path==='/v4/progress'){const out=await platformApi({...ctx,path:'/v7/progress'});if(out)return out;}
 if(viewer&&path==='/saved'){const out=await platformApi({...ctx,path:'/v7/saved'});if(out)return out;}
 if(path==='/v4/profile'&&req.method==='GET'){const p=result(await db.from('cineo_profiles').select('*').eq('user_id',uid).maybeSingle())||{name:'Criador',bio:'',avatar:''};return response({...p,viewer});}
 if(viewer&&path==='/v6/preferences'){if(req.method==='POST'){check(Array.isArray(data.genres)&&data.genres.length<=12&&data.genres.every((x:any)=>typeof x==='string'&&x.length<=40),'Gêneros inválidos.');result(await db.from('cineo_viewers').update({genres:data.genres}).eq('id',viewer.id));return response({genres:data.genres,onboarded:true});}return response({genres:viewer.genres,onboarded:true});}
 if(path.startsWith('/v6/'))return await completeApi({db,uid,admin,req,data,route,covers,check,result,response,path,viewer});
 if(path.startsWith('/v4/'))return await proApi({db,uid,admin,req,data,route,covers,check,result,response,path,viewer});
 if(path==='/saved'&&req.method==='GET'){
 const offset=Math.max(0,Number(route.searchParams.get('offset'))||0);
 const r=await db.from('cineo_saved').select('show:cineo_shows!inner(*)',{count:'exact'}).eq('user_id',uid).eq('show.status','approved').eq('show.hidden',false).or('premiere_at.is.null,premiere_at.lte.'+new Date().toISOString(),{referencedTable:'show'}).order('created_at',{ascending:false}).range(offset,offset+49);
 const rows=result(r);return response({items:await covers(rows.map((x:any)=>x.show)),next:offset+rows.length<(r.count||0)?offset+rows.length:null});
 }
 if(['/catalog','/mine','/queue','/admin'].includes(path)&&req.method==='GET'){
 const offset=Math.max(0,Number(route.searchParams.get('offset'))||0);
 let q=db.from('cineo_shows').select('*',{count:'exact'}).order('id',{ascending:false}).range(offset,offset+49);
 if(path==='/catalog')q=q.eq('status','approved').eq('hidden',false).or('premiere_at.is.null,premiere_at.lte.'+new Date().toISOString());
 if(path==='/mine')q=q.eq('owner_id',uid);
 if(path==='/queue'||path==='/admin'){check(admin,'Acesso exclusivo do administrador.');const filter=path==='/queue'?'pending':route.searchParams.get('status');if(filter&&['pending','approved','rejected','draft'].includes(filter))q=q.eq('status',filter);}
 const r=await q;const rows=result(r);return response({items:await covers(rows),total:r.count,next:offset+rows.length<(r.count||0)?offset+rows.length:null});
 }
 if(path==='/stats'&&req.method==='GET'){check(admin,'Acesso restrito.');const out:any={};for(const status of ['pending','approved','rejected','draft']){const r=await db.from('cineo_shows').select('id',{count:'exact',head:true}).eq('status',status);result(r);out[status]=r.count||0;}return response(out);}
 if(path==='/shows'&&req.method==='POST'){
 const inserted=result(await db.from('cineo_shows').insert({owner_id:uid,title:String(data.title||'').trim(),synopsis:String(data.synopsis||'').trim(),genre:String(data.genre||'Drama'),rating:String(data.rating||'Livre')}).select('*').single());return response(inserted);
 }
 const m=path.match(/^\/shows\/(\d+)(?:\/(episodes|submit|review|edit|social|save|comments))?$/);check(m,'Rota não encontrada.');
 const sid=Number(m![1]),op=m![2]||'detail';
 const show=result(await db.from('cineo_shows').select('*').eq('id',sid).maybeSingle());check(show,'Produção não encontrada.');
 const owner=show.owner_id===uid;
 const visible=show.status==='approved'&&!show.hidden&&(!show.premiere_at||show.premiere_at<=new Date().toISOString());
 if(['social','save','comments'].includes(op)){
 check(visible,'As interações ficam disponíveis após a publicação.');
 if(op==='save'&&viewer){const out=await platformApi({...ctx,path:'/v7/saved',data:{...data,show_id:sid}});if(req.method==='POST')return out;const saved=!!result(await db.from('cineo_viewer_saved').select('show_id').eq('viewer_id',viewer.id).eq('show_id',sid).maybeSingle());return response({saved});}
 if(op==='save'){
 if(req.method==='POST'){check(typeof data.saved==='boolean','Estado inválido.');if(data.saved)result(await db.from('cineo_saved').upsert({user_id:uid,show_id:sid},{onConflict:'user_id,show_id'}));else result(await db.from('cineo_saved').delete().eq('user_id',uid).eq('show_id',sid));}
 else check(req.method==='GET','Método inválido.');
 const saved=!!result(await db.from('cineo_saved').select('show_id').eq('user_id',uid).eq('show_id',sid).maybeSingle());return response({saved});
 }
 const eid=Number(req.method==='GET'?route.searchParams.get('episode_id'):data.episode_id);
 check(Number.isSafeInteger(eid)&&eid>0,'Episódio inválido.');
 check(result(await db.from('cineo_episodes').select('id').eq('id',eid).eq('show_id',sid).eq('review_status','approved').eq('hidden',false).or('release_at.is.null,release_at.lte.'+new Date().toISOString()).neq('media_state','failed').maybeSingle()),'Episódio indisponível.');
 if(op==='comments'){
 if(req.method==='POST'){
 const body=String(data.body||'').trim(),name=String(data.name||'Criador').trim();check(body.length>0&&body.length<=1000&&name.length>0&&name.length<=60,'Comentário inválido. Use até 1.000 caracteres e nome de até 60.');
 const recent=result(await db.from('cineo_comments').select('id').eq('user_id',uid).gte('created_at',new Date(Date.now()-10000).toISOString()).limit(1));check(!recent.length,'Aguarde alguns segundos antes de comentar novamente.');
 const duplicate=result(await db.from('cineo_comments').select('id').eq('user_id',uid).eq('body',body).gte('created_at',new Date(Date.now()-300000).toISOString()).limit(1));check(!duplicate.length,'Você já enviou este comentário.');const minute=await db.from('cineo_comments').select('id',{head:true,count:'exact'}).eq('user_id',uid).gte('created_at',new Date(Date.now()-60000).toISOString());result(minute);check(minute.count<5,'Limite de comentários por minuto atingido.');const parent=Number(data.parent_id)||null;if(parent)check(result(await db.from('cineo_comments').select('id').eq('id',parent).eq('episode_id',eid).eq('hidden',false).maybeSingle()),'Resposta inválida.');result(await db.from('cineo_comments').insert({episode_id:eid,user_id:uid,author_name:name,body,parent_id:parent,spoiler:data.spoiler===true}));return response({ok:true});
 }
 check(req.method==='GET','Método inválido.');
 const before=Number(route.searchParams.get('before'))||0;
 let query=db.from('cineo_comments').select('id,author_name,body,created_at,parent_id,spoiler,pinned,user_id').eq('episode_id',eid).eq('hidden',false).eq('pinned',false).order('id',{ascending:false}).limit(31);if(before>0)query=query.lt('id',before);
 const rows=result(await query);const blocked=result(await db.from('cineo_blocks').select('target_id').eq('user_id',uid)).map((x:any)=>x.target_id);const hasMore=rows.length>30;const pins=before===0?result(await db.from('cineo_comments').select('id,author_name,body,created_at,parent_id,spoiler,pinned,user_id').eq('episode_id',eid).eq('hidden',false).eq('pinned',true).order('id',{ascending:false}).limit(3)):[];const items=[...pins,...rows.slice(0,30)].filter((x:any)=>!blocked.includes(x.user_id));const enhanced=await Promise.all(items.map(async(c:any)=>{const likes=await db.from('cineo_comment_likes').select('*',{count:'exact',head:true}).eq('comment_id',c.id);result(likes);const liked=!!result(await db.from('cineo_comment_likes').select('comment_id').eq('comment_id',c.id).eq('user_id',uid).maybeSingle());const {user_id,...publicComment}=c;return {...publicComment,author_id:user_id,likes:likes.count||0,liked};}));return response({items:enhanced,next:hasMore?rows[29].id:null});
 }
 if(req.method==='POST'){check(typeof data.liked==='boolean','Estado inválido.');if(data.liked)result(await db.from('cineo_likes').upsert({episode_id:eid,user_id:uid},{onConflict:'episode_id,user_id'}));else result(await db.from('cineo_likes').delete().eq('episode_id',eid).eq('user_id',uid));}else check(req.method==='GET','Método inválido.');
 const likes=await db.from('cineo_likes').select('episode_id',{count:'exact',head:true}).eq('episode_id',eid);result(likes);
 const comments=await db.from('cineo_comments').select('id',{count:'exact',head:true}).eq('episode_id',eid).eq('hidden',false);result(comments);
 const liked=!!result(await db.from('cineo_likes').select('episode_id').eq('episode_id',eid).eq('user_id',uid).maybeSingle());
 const saved=!!result(await db.from('cineo_saved').select('show_id').eq('show_id',sid).eq('user_id',uid).maybeSingle());
 return response({likes:likes.count,comments:comments.count,liked,saved});
 }
 if(op==='detail'&&req.method==='GET'){check(owner||admin||visible,'Conteúdo indisponível.');return response((await covers([show]))[0]);}
 if(op==='edit'&&req.method==='POST'){
 check(owner&&['draft','rejected'].includes(show.status),'Edição não permitida.');let newCover:string|null=null;
 if(data.cover){check(typeof data.cover==='string'&&data.cover.length<=2800000,'Capa excede 2 MB.');const raw=atob(data.cover);check(raw.length>3&&raw.length<=2097152&&raw.charCodeAt(0)===255&&raw.charCodeAt(1)===216,'Escolha uma imagem JPEG.');newCover=uid+'/'+crypto.randomUUID()+'.jpg';result(await db.storage.from('cineo-covers').upload(newCover,Uint8Array.from(raw,c=>c.charCodeAt(0)),{contentType:'image/jpeg',upsert:false}));}
 const changed=await db.rpc('cineo_edit_show',{actor:uid,sid,new_title:String(data.title||show.title).trim(),new_synopsis:String(data.synopsis||show.synopsis).trim(),new_genre:String(data.genre||show.genre),new_rating:String(data.rating||show.rating),new_cover:newCover});
 if(changed.error){if(newCover)await db.storage.from('cineo-covers').remove([newCover]);throw changed.error;}
 if(newCover&&changed.data)await db.storage.from('cineo-covers').remove([changed.data]);return response({ok:true});
 }
 if(op==='episodes'&&req.method==='GET'){
 check(owner||admin||visible,'Conteúdo indisponível.');
 let query=db.from('cineo_episodes').select('*').eq('show_id',sid).order('season').order('episode_number').order('id');if(!owner&&!admin)query=query.eq('review_status','approved').eq('hidden',false);const rows=result(await query);
 const visible=rows.filter((e:any)=>(owner||admin)&&!viewer?.kids?true:aired(e));const [videoUrls,thumbUrls]=await Promise.all([signedPaths(db,'cineo-videos',visible.flatMap((e:any)=>[e.storage_path,e.low_path,e.medium_path,...(e.audio_tracks||[]).map((t:any)=>t.path)])),signedPaths(db,'cineo-covers',visible.map((e:any)=>e.thumb_path))]);const items=visible.map((e:any)=>({id:e.id,title:e.title,url:videoUrls.get(e.storage_path)||'',low_url:videoUrls.get(e.low_path)||'',subtitles:e.subtitles,season:e.season,episode_number:e.episode_number,duration_seconds:e.duration_seconds,review_status:e.review_status,review_reason:e.review_reason,hidden:e.hidden,release_at:e.release_at,intro_start:e.intro_start,intro_end:e.intro_end,credits_start:e.credits_start,media_state:e.media_state,medium_url:videoUrls.get(e.medium_path)||'',thumb_url:thumbUrls.get(e.thumb_path)||'',audio_tracks:(e.audio_tracks||[]).map((t:any)=>({label:t.label,kind:t.kind,url:videoUrls.get(t.path)||''}))}));return response({items});
 }
 if(op==='episodes'&&req.method==='POST'){
 check(owner&&['draft','rejected'].includes(show.status),'Edição não permitida.');
 check(typeof data.video==='string'&&data.video.length<35000000,'Vídeo excede 25 MB.');
 const raw=atob(data.video);check(raw.length>=12&&raw.length<=26214400&&raw.slice(4,8)==='ftyp','Escolha um vídeo MP4 de até 25 MB.');
 const objectPath=uid+'/'+crypto.randomUUID()+'.mp4';result(await db.storage.from('cineo-videos').upload(objectPath,Uint8Array.from(raw,c=>c.charCodeAt(0)),{contentType:'video/mp4',upsert:false}));
 const added=await db.rpc('cineo_add_episode',{actor:uid,sid,episode_title:String(data.title||'').trim(),object_path:objectPath});
 if(added.error){await db.storage.from('cineo-videos').remove([objectPath]);throw added.error;}return response({ok:true});
 }
 if((op==='submit'||(op==='review'&&data.decision==='approved'))&&req.method==='POST'){const eps=result(await db.from('cineo_episodes').select('id').eq('show_id',sid));if(eps.length){const jobs=result(await db.from('cineo_media_jobs').select('status').in('episode_id',eps.map((x:any)=>x.id)));check(jobs.every((j:any)=>j.status==='ready'),'Aguarde a validação técnica dos vídeos antes de publicar.');}}
 if(op==='submit'&&req.method==='POST'){check(data.rights===true,'Confirme os direitos de publicação.');result(await db.rpc('cineo_transition',{actor:uid,sid,decision:'pending',note:''}));return response({ok:true});}
 if(op==='review'&&req.method==='POST'){check(admin&&['approved','rejected'].includes(data.decision),'Acesso restrito.');result(await db.rpc('cineo_transition',{actor:uid,sid,decision:data.decision,note:String(data.reason||'')}));if(data.decision==='approved')await notifyPublished(db,show);return response({ok:true});}
 return response({error:'Rota não encontrada.'},404);
 }catch(e){return response({error:friendly(e instanceof Error?e.message:'Erro na solicitação.')},400);}
});
