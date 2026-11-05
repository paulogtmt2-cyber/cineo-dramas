package br.com.cineo;
import org.json.*;
/** Isolated workflow and global-dashboard fixtures; never packaged in the user APK. */
class PublishingFixture {
 final MainActivity a;JSONObject story;int saves=0,submits=0,reviews=0;boolean ready=true;PublishingFixture(MainActivity a,JSONObject source)throws Exception{this.a=a;story=new JSONObject(source.toString()).put("format","mini").put("status","draft").put("cover_path","ui-fixture/cover.jpg").put("client_draft_id","11111111-1111-1111-1111-111111111111");}
 JSONObject checks()throws Exception{return a.obj("total",2,"ready",ready?2:1,"waiting",ready?0:1,"failed",0,"pending_uploads",0,"next_chapter",3,"drafts",1,"pending_reviews",0);}
 JSONObject chapter(int n)throws Exception{return a.obj("id",10+n,"show_id",1,"title",n==1?"O primeiro encontro":"Uma nova escolha","season",1,"episode_number",n,"media_state","ready","review_status","approved","url",new java.io.File(a.getCacheDir(),"sample.mp4").toURI().toString());}
 JSONObject request(String method,String path,JSONObject data)throws Exception{
 if(path.startsWith("/v13/admin/dashboard"))return a.obj("counts",a.obj("profiles",12,"creators",3,"productions",4,"chapters",10,"pending",1,"episode_pending",2,"views",240),"daily",new JSONArray().put(a.obj("day","2026-11-03","views",40)).put(a.obj("day","2026-11-04","views",80)).put(a.obj("day","2026-11-05","views",120)),"statuses",new JSONArray());
 if(path.startsWith("/v13/admin/queue"))return a.obj("items",new JSONArray().put(new JSONObject(story.toString()).put("status","pending").put("creator_name","Criador de teste")),"total",1,"next_offset",JSONObject.NULL);
 if(path.endsWith("/review")){reviews++;story.put("status",data.optString("decision")).put("reason",data.optString("reason"));return a.obj("ok",true);}
 if(path.startsWith("/v13/admin/show/")||path.startsWith("/v13/admin/episode/"))return a.obj("show",new JSONObject(story.toString()).put("status","pending"),"checks",checks(),"items",new JSONArray().put(chapter(1)).put(chapter(2)),"total",2,"offset",0,"next_offset",JSONObject.NULL);
 if(path.startsWith("/v13/publishing/home"))return a.obj("items",new JSONArray().put(story),"total",1,"next_offset",JSONObject.NULL);
 if(path.equals("/v13/publishing/save")){saves++;story.put("title",data.optString("title")).put("synopsis",data.optString("synopsis")).put("format",data.optString("format")).put("status","draft");return story;}
 if(path.endsWith("/submit")){submits++;story.put("status","pending");return a.obj("ok",true);}
 if(path.startsWith("/v13/publishing/show/"))return a.obj("show",story,"checks",checks(),"items",path.contains("summary=1")?new JSONArray():new JSONArray().put(chapter(1)).put(chapter(2)),"total",2,"next_offset",JSONObject.NULL,"offset",0);
 return a.obj("ok",true);
 }
}
