package br.com.cineo;
import androidx.test.rule.ActivityTestRule;
import androidx.test.platform.app.InstrumentationRegistry;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import org.junit.*;
import org.junit.runner.RunWith;
import org.json.*;
import android.graphics.Bitmap;
import android.widget.*;
import java.io.*;
import static org.junit.Assert.*;
@RunWith(AndroidJUnit4.class)
public class ScreenTest {
 @Rule public ActivityTestRule<MainActivity> rule=new ActivityTestRule<>(MainActivity.class);
 void ui(Runnable r){InstrumentationRegistry.getInstrumentation().runOnMainSync(r);InstrumentationRegistry.getInstrumentation().waitForIdleSync();}
 void settled()throws Exception{for(int i=0;i<100;i++){final boolean[] running={true};ui(()->running[0]=rule.getActivity().busy);if(!running[0])return;Thread.sleep(100);}fail("Screen request did not finish");}
 void capture(String name)throws Exception{settled();Thread.sleep(name.equals("01-login")?1500:400);Bitmap image=InstrumentationRegistry.getInstrumentation().getUiAutomation().takeScreenshot();assertNotNull(image);File dir=new File(rule.getActivity().getExternalFilesDir(null),"screens");assertTrue(dir.exists()||dir.mkdirs());try(FileOutputStream out=new FileOutputStream(new File(dir,name+".png"))){image.compress(Bitmap.CompressFormat.PNG,100,out);}image.recycle();ui(()->assertTrue("Top system inset must be retained on every screen",rule.getActivity().root.getPaddingTop()>0));}
 android.view.View find(android.view.View v,String text){if(v instanceof TextView){TextView t=(TextView)v;if(text.contentEquals(t.getText())||(t.getHint()!=null&&text.contentEquals(t.getHint())))return v;}if(v instanceof android.view.ViewGroup){android.view.ViewGroup g=(android.view.ViewGroup)v;for(int i=0;i<g.getChildCount();i++){android.view.View found=find(g.getChildAt(i),text);if(found!=null)return found;}}return null;}
 @Test public void screenLayoutsAndValidation()throws Exception{
  MainActivity a=rule.getActivity();capture("01-login");assertEquals("login",a.screen);
  ui(()->a.login(true));capture("02-register");
  JSONObject show=new JSONObject().put("id",1).put("title","Asfalto e Segredos").put("synopsis","Uma história de escolhas, encontros e novos caminhos.").put("genre","Drama").put("rating","14").put("status","approved").put("cover_url","android.resource://br.com.cineo/"+R.drawable.cinema_login);
  JSONObject draft=new JSONObject(show.toString()).put("id",2).put("title","Entre dois mundos").put("status","draft");
  JSONObject pending=new JSONObject(show.toString()).put("id",3).put("title","Céu de Agosto").put("status","pending");
  JSONArray episodes=new JSONArray().put(new JSONObject().put("id",11).put("title","O primeiro encontro").put("url","https://example.test/video.mp4"));
  java.util.concurrent.atomic.AtomicInteger posted=new java.util.concurrent.atomic.AtomicInteger();
  ui(()->{a.token="test-ui-only";a.uid="ui-fixture";a.email="criador@example.test";a.role="admin";a.expires=Long.MAX_VALUE;a.transport=(method,path,payload,bearer)->{
   if(path.equals("/stats"))return a.obj("pending",1,"approved",1,"rejected",0,"draft",1);
   if(path.endsWith("/episodes"))return a.obj("items",episodes);
   if(path.startsWith("/admin"))return a.obj("items",new JSONArray().put(pending),"next",JSONObject.NULL);
   if(path.equals("/mine"))return a.obj("items",new JSONArray().put(draft).put(pending),"next",JSONObject.NULL);
   if(path.contains("/social"))return a.obj("likes",payload!=null&&payload.optBoolean("liked")?1:0,"liked",payload!=null&&payload.optBoolean("liked"),"saved",false,"comments",1);
   if(path.endsWith("/save"))return a.obj("saved",payload==null||payload.optBoolean("saved"));
   if(path.contains("/comments")&&method.equals("POST")){assertEquals("Comentário de teste",payload.getString("body"));assertEquals(99,payload.getInt("episode_id"));posted.incrementAndGet();return a.obj("ok",true);}
   if(path.contains("/comments"))return a.obj("items",new JSONArray().put(a.obj("id",1,"author_name","Espectador","body","Gostei desta história!","created_at","2026-10-31T12:00:00Z")),"next",JSONObject.NULL);
   if(path.equals("/saved"))return a.obj("items",new JSONArray().put(show),"next",JSONObject.NULL);
   if(path.equals("/catalog"))return a.obj("items",new JSONArray().put(show),"next",JSONObject.NULL);
   throw new IOException("Unexpected test request: "+path);
  };a.catalog(false);});capture("03-home");assertEquals("home",a.screen);
  ui(()->a.catalog(true));capture("04-search");
  ui(()->a.details(show,"catalog"));capture("05-details");
  ui(()->{a.prefs.edit().putBoolean(a.local("saved_1"),true).apply();a.saved();});capture("06-favorites");
  ui(()->a.profile());capture("07-profile");
  ui(()->a.mine());capture("08-productions");
  ui(()->a.edit(null));capture("09-create");assertEquals("edit",a.screen);
  ui(()->{a.currentShow=draft;a.addEpisode(2);});capture("10-upload");
  ui(()->a.admin());capture("11-admin");
  ui(()->a.adminFilter("pending"));capture("12-review-queue");
  ui(()->a.details(pending,"admin"));capture("13-review");
  ui(()->a.reject(pending));capture("14-review-rejection");
  ui(()->a.settings());capture("15-settings");
  ui(()->a.password());capture("16-password");
  ui(()->{a.page("home","Explore o Cineo","",0,null);a.renderCatalog(a.body,new JSONArray(),"","Todos",false);});capture("17-empty-state");
  File sample=new File(a.getCacheDir(),"sample.mp4");try(InputStream in=InstrumentationRegistry.getInstrumentation().getContext().getAssets().open("sample.mp4");FileOutputStream out=new FileOutputStream(sample)){byte[] b=new byte[8192];int n;while((n=in.read(b))!=-1)out.write(b,0,n);}
  JSONArray playable=new JSONArray().put(new JSONObject().put("id",99).put("title","Teste do player").put("url",sample.toURI().toString()));
  ui(()->a.play(show,playable,0,"catalog"));
  final boolean[] prepared={false};for(int i=0;i<100&&!prepared[0];i++){ui(()->prepared[0]=a.video!=null&&a.video.getDuration()>0);Thread.sleep(100);}assertTrue("Player must decode H264 MP4",prepared[0]);capture("18-player");
  ui(()->{assertNotNull(a.media);a.togglePlayback();assertFalse(a.video.isPlaying());a.seekBy(10000);});Thread.sleep(500);
  ui(()->{assertTrue("Seek must advance playback",a.video.getCurrentPosition()>5000);a.togglePlayback();a.fullscreenPlayer();});capture("19-fullscreen");
  ui(()->{assertNotNull(a.fullDialog);a.fullDialog.dismiss();});Thread.sleep(700);
  ui(()->{assertNotNull(a.video);assertTrue("Player survives fullscreen",a.video.getDuration()>0);assertTrue("Fullscreen retains position",a.video.getCurrentPosition()>5000);a.media.setPlaybackParams(a.media.getPlaybackParams().setSpeed(1.25f));assertEquals(1.25f,a.media.getPlaybackParams().getSpeed(),.01f);a.toggleLike();});Thread.sleep(600);ui(()->assertTrue("Like state returned by server",a.liked));
  ui(()->a.toggleSocialSave());Thread.sleep(600);ui(()->assertTrue("Save state returned by server",a.socialSaved));
  ui(()->a.comments());Thread.sleep(600);capture("20-comments");
  ui(()->{android.view.View content=a.commentsDialog.getWindow().getDecorView();((EditText)find(content,"Escreva um comentário…")).setText("Comentário de teste");find(content,"Publicar comentário").performClick();});Thread.sleep(700);assertEquals("Comment sent once to the current episode",1,posted.get());capture("22-comment-published");ui(()->a.commentsDialog.dismiss());
  ui(()->a.episodeMenu());capture("21-episodes");InstrumentationRegistry.getInstrumentation().getUiAutomation().performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK);

  ui(()->{a.clearSession();a.login(false);});
 }
}
