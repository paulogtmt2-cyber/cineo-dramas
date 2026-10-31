import {createClient} from 'npm:@supabase/supabase-js@2';
const url=Deno.env.get('SUPABASE_URL')!;
const opts={auth:{persistSession:false,autoRefreshToken:false}};
const response=(data:unknown,status=200)=>new Response(JSON.stringify(data),{status,headers:{'Content-Type':'application/json','Cache-Control':'no-store'}});
function check(ok:unknown,message:string){if(!ok)throw new Error(message)}
function result(r:any){if(r.error)throw new Error(r.error.message);return r.data}
Deno.serve(async req=>{
 try{
 const path=new URL(req.url).pathname.split('/cineo')[1]||'/';
 if(path==='/health')return response({ok:true});
 const db=createClient(url,Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,opts);
 const auth=createClient(url,Deno.env.get('SUPABASE_ANON_KEY')!,opts);
 const token=(req.headers.get('Authorization')||'').replace(/^Bearer /,'');
 const data=req.method==='POST'?await req.json():{};
 if(path==='/register'||path==='/login'){
 check(req.method==='POST','Método inválido');
 const credentials={email:String(data.email||'').trim().toLowerCase(),password:String(data.password||'')};
 check(credentials.password.length>=8,'Use uma senha de pelo menos 8 caracteres.');
 const r=path==='/register'?await auth.auth.signUp(credentials):await auth.auth.signInWithPassword(credentials);
 if(r.error)throw new Error(r.error.message);
 if(!r.data.session)return response({confirmation_required:true,message:'Confira seu email e confirme o cadastro antes de entrar.'});
 const admin=result(await db.from('cineo_admins').select('user_id').eq('user_id',r.data.user!.id).maybeSingle());
 return response({token:r.data.session.access_token,role:admin?'admin':'creator'});
 }
 const {data:identity,error}=await auth.auth.getUser(token);
 if(error||!identity.user)return response({error:'Sessão expirada. Entre novamente.'},401);
 const uid=identity.user.id;
 const admin=!!result(await db.from('cineo_admins').select('user_id').eq('user_id',uid).maybeSingle());
 if(path==='/logout'){await auth.auth.admin.signOut(token);return response({ok:true});}
 if(['/catalog','/mine','/queue'].includes(path)&&req.method==='GET'){
 let q=db.from('cineo_shows').select('*').order('id',{ascending:false}).limit(100);
 if(path==='/catalog')q=q.eq('status','approved');
 if(path==='/mine')q=q.eq('owner_id',uid);
 if(path==='/queue'){check(admin,'Acesso exclusivo do administrador.');q=q.eq('status','pending');}
 return response({items:result(await q)});
 }
 if(path==='/shows'&&req.method==='POST'){
 const inserted=result(await db.from('cineo_shows').insert({owner_id:uid,title:String(data.title||'').trim(),synopsis:String(data.synopsis||'').trim()}).select('id').single());return response(inserted);
 }
 const m=path.match(/^\/shows\/(\d+)\/(episodes|submit|review)$/);check(m,'Rota não encontrada.');
 const sid=Number(m![1]),op=m![2];
 const show=result(await db.from('cineo_shows').select('*').eq('id',sid).maybeSingle());check(show,'Produção não encontrada.');
 const owner=show.owner_id===uid;
 if(op==='episodes'&&req.method==='GET'){
 check(owner||admin||show.status==='approved','Conteúdo indisponível.');
 const rows=result(await db.from('cineo_episodes').select('*').eq('show_id',sid).order('id'));
 const items=[];
 for(const e of rows){const signed=result(await db.storage.from('cineo-videos').createSignedUrl(e.storage_path,3600));items.push({id:e.id,title:e.title,url:signed.signedUrl});}
 return response({items});
 }
 if(op==='episodes'&&req.method==='POST'){
 check(owner&&['draft','rejected'].includes(show.status),'Edição não permitida.');
 check(typeof data.video==='string'&&data.video.length<35000000,'Vídeo excede 25 MB.');
 const raw=atob(data.video);check(raw.length>=12&&raw.length<=26214400&&raw.slice(4,8)==='ftyp','Escolha um vídeo MP4 de até 25 MB.');
 const bytes=Uint8Array.from(raw,c=>c.charCodeAt(0));const objectPath=uid+'/'+crypto.randomUUID()+'.mp4';
 result(await db.storage.from('cineo-videos').upload(objectPath,bytes,{contentType:'video/mp4',upsert:false}));
 const added=await db.rpc('cineo_add_episode',{actor:uid,sid,episode_title:String(data.title||'').trim(),object_path:objectPath});
 if(added.error){await db.storage.from('cineo-videos').remove([objectPath]);throw new Error(added.error.message);}
 return response({ok:true});
 }
 if(op==='submit'&&req.method==='POST'){
 check(data.rights===true,'Confirme os direitos de publicação.');
 result(await db.rpc('cineo_transition',{actor:uid,sid,decision:'pending',note:''}));return response({ok:true});
 }
 if(op==='review'&&req.method==='POST'){
 check(admin&&['approved','rejected'].includes(data.decision),'Acesso restrito.');
 result(await db.rpc('cineo_transition',{actor:uid,sid,decision:data.decision,note:String(data.reason||'')}));return response({ok:true});
 }
 return response({error:'Rota não encontrada.'},404);
 }catch(e){return response({error:e instanceof Error?e.message:'Erro na solicitação.'},400);}
});
