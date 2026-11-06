package br.com.cineo;
import org.json.*;
/** Synthetic social data used only by the Android instrumentation package. */
class ProfileFixture {
 final MainActivity a;final JSONObject show;String avatar="";boolean following=false;int follows=0,posts=0;String handle="paulo.cineo",name="Paulo Oliveira",bio="Histórias independentes, bastidores e novos capítulos. Bem-vindo ao meu Cineo!",link="https://example.com/cineo";
 static final String OTHER="11111111-1111-1111-1111-111111111111",POST="22222222-2222-2222-2222-222222222222";
 ProfileFixture(MainActivity a,JSONObject show){this.a=a;this.show=show;}
 JSONObject identity(String id)throws Exception{return a.obj("user_id",id,"name",id.equals(a.uid)?name:"Lia Santos","username",id.equals(a.uid)?handle:"lia.historias","bio",bio,"bio_link",link,"avatar",avatar,"verified",true);}
 JSONObject samplePost()throws Exception{return a.obj("id",POST,"user_id",a.uid,"body","Os bastidores da próxima história já começaram. Que tipo de final você gostaria de assistir?","status","pending","show",JSONObject.NULL,"reason","","created_at","2026-11-06T12:00:00Z");}
 JSONObject request(String method,String path,JSONObject payload)throws Exception{
 if(path.equals("/v14/me")){if(method.equals("POST")){name=payload.optString("name");handle=payload.optString("username");bio=payload.optString("bio");link=payload.optString("bio_link");avatar=payload.optString("avatar");}return identity(a.uid);}
 if(path.equals("/v14/follow")){following=payload.optBoolean("following");follows++;return a.obj("following",following,"followers",following?9:8);}
 if(path.equals("/v14/posts")){posts++;return a.obj("ok",true);}
 if(path.startsWith("/v14/admin/posts"))return a.obj("items",new JSONArray().put(samplePost()),"next_offset",JSONObject.NULL);
 if(path.contains("/people?"))return a.obj("items",new JSONArray().put(identity(OTHER)),"next_offset",JSONObject.NULL);
 if(path.contains("/posts?"))return a.obj("items",new JSONArray().put(a.obj("id",POST,"body","Nossa nova história estreia em breve. Obrigado por acompanhar cada capítulo!","status","approved","reason","","show",show,"created_at","2026-11-06T11:00:00Z")).put(samplePost()),"next_offset",JSONObject.NULL);
 if(path.contains("/series?"))return a.obj("items",new JSONArray().put(show),"next_offset",JSONObject.NULL);
 if(path.startsWith("/v14/profile/")){String id=path.substring("/v14/profile/".length()).split("[/?]",2)[0];boolean own=id.equals(a.uid);return a.obj("profile",identity(id),"followers",8+(following?1:0),"following_count",12,"posts_count",1,"series_count",1,"following",following,"own",own,"can_post",own,"kids",false,"items",new JSONArray().put(show),"next_offset",JSONObject.NULL);}
 return a.obj("ok",true);
 }
}
