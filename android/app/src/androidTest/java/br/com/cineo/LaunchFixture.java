package br.com.cineo;
import org.json.*;
/** Synthetic preview data: never included in the installed application. */
class LaunchFixture {
 final MainActivity a;final JSONObject show;final String video;boolean joined=false;int missionPosts=0;LaunchFixture(MainActivity a,JSONObject show,String video){this.a=a;this.show=show;this.video=video;}
 JSONObject request(String method,String path,JSONObject data)throws Exception{
 if(path.startsWith("/v12/clips")){JSONArray rows=new JSONArray();for(int i=0;i<2;i++)rows.put(a.obj("show",new JSONObject(show.toString()).put("id",i+1).put("owner_id","clip-fixture").put("title",i==0?"Asfalto e Segredos":"Uma nova história"),"episode",a.obj("id",i==0?11:21,"title","Primeiro episódio","season",1,"episode_number",1,"review_status","approved","media_state","ready","duration_seconds",20,"url",video)));return a.obj("items",rows,"next_offset",JSONObject.NULL);}
 if(path.equals("/v12/missions")){if(method.equals("POST")){joined=true;missionPosts++;}return a.obj("joined",joined,"first_eligible",true,"reward_cents",joined?151:0,"balance_cents",joined?151:0,"program",a.obj("enabled",true,"first_cents",150,"episode_cents",1,"budget_cents",JSONObject.NULL),"items",joined?new JSONArray().put(a.obj("show",show,"episodes",2,"paid_episodes",1,"released_cents",151,"pending_episode_cents",1,"first_possible",false)):new JSONArray(),"ledger",joined?new JSONArray().put(a.obj("kind","first_series","amount_cents",150,"reason","Missão: primeira série publicada · DADO SIMULADO","created_at","2026-11-05T12:00:00Z")):new JSONArray(),"note","Dados sintéticos somente para testes. Bônus separados de views. Entre antes de publicar.");}
 if(path.startsWith("/v12/admin/program"))return a.obj("enabled",true,"revision",1,"first_cents",150,"episode_cents",1,"budget_cents",10000,"spent_cents",151,"bonus_cents",500);
 if(path.startsWith("/v12/admin/search"))return a.obj("profiles",new JSONArray().put(a.obj("user_id","11111111-1111-1111-1111-111111111111","name","Criador de teste","verified",true)),"shows",new JSONArray().put(show));
 if(path.startsWith("/v12/admin/clips"))return a.obj("items",new JSONArray().put(a.obj("show_id",1,"enabled",true,"position",10,"reason","Curadoria de teste")));
 if(path.startsWith("/v12/admin/history"))return a.obj("items",new JSONArray().put(a.obj("action","launch_clip","target","1","detail",a.obj("reason","Escolha editorial de teste"),"created_at","2026-11-05T12:00:00Z")));
 if(path.startsWith("/v12/admin/health"))return a.obj("sessions",200,"qualified_views",40,"clip_sessions",100,"clip_views",20,"high_repeat_accounts",0);
 return a.obj("ok",true);
 }
}
