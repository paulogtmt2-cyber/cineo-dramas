import {proApi,notifyPublished} from './pro.ts';
import {completeApi} from './complete.ts';
import {createClient} from 'npm:@supabase/supabase-js@2.57.4';
const url=Deno.env.get('SUPABASE_URL')!;
const opts={auth:{persistSession:false,autoRefreshToken:false}};
const response=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
function check(ok:unknown,message:string){if(!ok)throw new Error(message)}
function result(r:any){if(r.error)throw new Error(r.error.message);return r.data}
function friendly(message:string){if(message.includes('cineo_episode_chapter_idx'))return 'Este número de episódio já existe nesta temporada. Escolha outro.';if(message.includes('Email not confirmed'))return 'Confirme seu email antes de entrar. Confira também a pasta de spam.';if(message.includes('Invalid login credentials'))return 'Email ou senha incorretos.';if(message.includes('rate limit'))return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';return message;}
Deno.serve(async req=>{
 try{
 const route=new URL(req.url), path=route.pathname.split('/cineo')[1]||'/';
 if(path==='/health')return response({ok:true,version:'0.6.0'});
 const db=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,opts);
 if(path==='/version'&&req.method==='GET'){const r=await db.from('cineo_release').select('version_code,version_name,notes,download_url').eq('id',1).single();return response(result(r));}
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
 const admin=!!result(await db.from('cineo_admins').select('user_id').eq('user_id',uid).maybeSingle());
 if(path==='/logout'&&req.method==='POST'){const r=await db.auth.admin.signOut(token,'local');if(r.error)throw r.error;return response({ok:true});}
 if(path==='/password'&&req.method==='POST'){
 check(String(data.password||'').length>=8,'Use pelo menos 8 caracteres.');
 const verify=await auth.auth.signInWithPassword({email:identity.user.email!,password:String(data.current||'')});if(verify.error)throw new Error('Senha atual incorreta.');
 const changed=await auth.auth.updateUser({password:String(data.password)});if(changed.error)throw changed.error;await auth.auth.signOut();return response({ok:true});
 }
 async function covers(rows:any[]){if(!rows.length)return [];const meta=result(await db.rpc('cineo_show_metadata',{ids:rows.map(s=>s.id)}));return await Promise.all(rows.map(async s=>{let cover_url='',banner_url='',cover_error='';if(s.cover_path){const r=await db.storage.from('cineo-covers').createSignedUrl(s.cover_path,3600);cover_url=r.data?.signedUrl||'';cover_error=r.error?.message||'';}if(s.banner_path){const r=await db.storage.from('cineo-covers').createSignedUrl(s.banner_path,3600);banner_url=r.data?.signedUrl||'';}return {...s,...meta.find((x:any)=>x.id===s.id),cover_url,banner_url,cover_error};}));}
 if(path.startsWith('/v6/'))return await completeApi({db,uid,admin,req,data,route,covers,check,result,response,path});
 if(path.startsWith('/v4/'))return await proApi({db,uid,admin,req,data,route,covers,check,result,response,path});
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
 if(op==='save'){
 if(req.method==='POST'){check(typeof data.saved==='boolean','Estado inválido.');if(data.saved)result(await db.from('cineo_saved').upsert({user_id:uid,show_id:sid},{onConflict:'user_id,show_id'}));else result(await db.from('cineo_saved').delete().eq('user_id',uid).eq('show_id',sid));}
 else check(req.method==='GET','Método inválido.');
 const saved=!!result(await db.from('cineo_saved').select('show_id').eq('user_id',uid).eq('show_id',sid).maybeSingle());return response({saved});
 }
 const eid=Number(req.method==='GET'?route.searchParams.get('episode_id'):data.episode_id);
 check(Number.isSafeInteger(eid)&&eid>0,'Episódio inválido.');
 check(result(await db.from('cineo_episodes').select('id').eq('id',eid).eq('show_id',sid).eq('review_status','approved').eq('hidden',false).maybeSingle()),'Episódio indisponível.');
 if(op==='comments'){
 if(req.method==='POST'){
 const body=String(data.body||'').trim(),name=String(data.name||'Criador').trim();check(body.length>0&&body.length<=1000&&name.length>0&&name.length<=60,'Comentário inválido. Use até 1.000 caracteres e nome de até 60.');
 const recent=result(await db.from('cineo_comments').select('id').eq('user_id',uid).gte('created_at',new Date(Date.now()-10000).toISOString()).limit(1));check(!recent.length,'Aguarde alguns segundos antes de comentar novamente.');
 const parent=Number(data.parent_id)||null;if(parent)check(result(await db.from('cineo_comments').select('id').eq('id',parent).eq('episode_id',eid).eq('hidden',false).maybeSingle()),'Resposta inválida.');result(await db.from('cineo_comments').insert({episode_id:eid,user_id:uid,author_name:name,body,parent_id:parent,spoiler:data.spoiler===true}));return response({ok:true});
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
 const items=[];for(const e of rows){const signed=result(await db.storage.from('cineo-videos').createSignedUrl(e.storage_path,3600));const low=e.low_path?result(await db.storage.from('cineo-videos').createSignedUrl(e.low_path,3600)).signedUrl:'';items.push({id:e.id,title:e.title,url:signed.signedUrl,low_url:low,subtitles:e.subtitles,season:e.season,episode_number:e.episode_number,duration_seconds:e.duration_seconds,review_status:e.review_status,review_reason:e.review_reason,hidden:e.hidden});}return response({items});
 }
 if(op==='episodes'&&req.method==='POST'){
 check(owner&&['draft','rejected'].includes(show.status),'Edição não permitida.');
 check(typeof data.video==='string'&&data.video.length<35000000,'Vídeo excede 25 MB.');
 const raw=atob(data.video);check(raw.length>=12&&raw.length<=26214400&&raw.slice(4,8)==='ftyp','Escolha um vídeo MP4 de até 25 MB.');
 const objectPath=uid+'/'+crypto.randomUUID()+'.mp4';result(await db.storage.from('cineo-videos').upload(objectPath,Uint8Array.from(raw,c=>c.charCodeAt(0)),{contentType:'video/mp4',upsert:false}));
 const added=await db.rpc('cineo_add_episode',{actor:uid,sid,episode_title:String(data.title||'').trim(),object_path:objectPath});
 if(added.error){await db.storage.from('cineo-videos').remove([objectPath]);throw added.error;}return response({ok:true});
 }
 if(op==='submit'&&req.method==='POST'){check(data.rights===true,'Confirme os direitos de publicação.');result(await db.rpc('cineo_transition',{actor:uid,sid,decision:'pending',note:''}));return response({ok:true});}
 if(op==='review'&&req.method==='POST'){check(admin&&['approved','rejected'].includes(data.decision),'Acesso restrito.');result(await db.rpc('cineo_transition',{actor:uid,sid,decision:data.decision,note:String(data.reason||'')}));if(data.decision==='approved')await notifyPublished(db,show);return response({ok:true});}
 return response({error:'Rota não encontrada.'},404);
 }catch(e){return response({error:friendly(e instanceof Error?e.message:'Erro na solicitação.')},400);}
});
