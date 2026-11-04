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
 MainActivity current(){final MainActivity[] found={null};Runnable resolve=()->{for(android.app.Activity activity:androidx.test.runner.lifecycle.ActivityLifecycleMonitorRegistry.getInstance().getActivitiesInStage(androidx.test.runner.lifecycle.Stage.RESUMED))if(activity instanceof MainActivity)found[0]=(MainActivity)activity;if(found[0]==null)found[0]=rule.getActivity();};if(android.os.Looper.myLooper()==android.os.Looper.getMainLooper())resolve.run();else InstrumentationRegistry.getInstrumentation().runOnMainSync(resolve);return found[0];}
 void ui(Runnable r){InstrumentationRegistry.getInstrumentation().runOnMainSync(r);InstrumentationRegistry.getInstrumentation().waitForIdleSync();}
 void settled()throws Exception{for(int i=0;i<100;i++){final boolean[] running={true};ui(()->running[0]=current().busy);if(!running[0])return;Thread.sleep(100);}fail("Screen request did not finish");}
 void capture(String name)throws Exception{settled();Thread.sleep(name.equals("01-login")?1500:400);Bitmap image=InstrumentationRegistry.getInstrumentation().getUiAutomation().takeScreenshot();assertNotNull(image);File dir=new File(current().getExternalFilesDir(null),"screens");assertTrue(dir.exists()||dir.mkdirs());try(FileOutputStream out=new FileOutputStream(new File(dir,name+".png"))){image.compress(Bitmap.CompressFormat.PNG,100,out);}image.recycle();ui(()->assertTrue("Top system inset must be retained on every screen",current().playerFullscreen||current().root.getPaddingTop()>0));}
 android.view.View find(android.view.View v,String text){if(v instanceof TextView){TextView t=(TextView)v;if(text.contentEquals(t.getText())||(t.getHint()!=null&&text.contentEquals(t.getHint())))return v;}if(v instanceof android.view.ViewGroup){android.view.ViewGroup g=(android.view.ViewGroup)v;for(int i=0;i<g.getChildCount();i++){android.view.View found=find(g.getChildAt(i),text);if(found!=null)return found;}}return null;}
 void ready(MainActivity a)throws Exception{for(int i=0;i<100;i++){final boolean[] ok={false};ui(()->ok[0]=a.video!=null&&a.media!=null&&a.video.getDuration()>0);if(ok[0])return;Thread.sleep(100);}fail("Video did not prepare");}
 void swipe(MainActivity a,float x1,float y1,float x2,float y2){ui(()->{long start=android.os.SystemClock.uptimeMillis();for(int i=0;i<=7;i++){int action=i==0?android.view.MotionEvent.ACTION_DOWN:i==7?android.view.MotionEvent.ACTION_UP:android.view.MotionEvent.ACTION_MOVE;android.view.MotionEvent e=android.view.MotionEvent.obtain(start,start+i*40,action,x1+(x2-x1)*i/7,y1+(y2-y1)*i/7,0);a.playerFrame.dispatchTouchEvent(e);e.recycle();}});}
 void vertical(MainActivity a,boolean up){float w=a.playerFrame.getWidth(),h=a.playerFrame.getHeight();swipe(a,w*.4f,h*(up?.65f:.30f),w*.4f,h*(up?.30f:.65f));}
 @Test public void screenLayoutsAndValidation()throws Exception{
  Thread.sleep(2000);capture("01-login");assertEquals("login",current().screen);
  ui(()->current().login(true));capture("02-register");
  final MainActivity a=current();
  JSONObject show=new JSONObject().put("id",1).put("title","Asfalto e Segredos").put("synopsis","Uma história de escolhas, encontros e novos caminhos.").put("genre","Drama").put("rating","14").put("status","approved").put("owner_id","ui-fixture").put("cover_url","android.resource://br.com.cineo/"+R.drawable.cinema_login);
  JSONObject draft=new JSONObject(show.toString()).put("id",2).put("title","Entre dois mundos").put("status","draft");
  JSONObject pending=new JSONObject(show.toString()).put("id",3).put("title","Céu de Agosto").put("status","pending");
  JSONArray episodes=new JSONArray().put(new JSONObject().put("id",11).put("title","O primeiro encontro").put("season",1).put("episode_number",1).put("review_status","draft").put("duration_seconds",20).put("url","https://example.test/video.mp4"));
  java.util.concurrent.atomic.AtomicInteger posted=new java.util.concurrent.atomic.AtomicInteger();
  ui(()->{a.token="test-ui-only";a.uid="ui-fixture";a.email="criador@example.test";a.role="admin";a.expires=Long.MAX_VALUE;a.transport=(method,path,payload,bearer)->{
   if(path.equals("/v4/progress"))return method.equals("POST")?a.obj("ok",true):a.obj("items",new JSONArray().put(a.obj("episode_id",11,"position_ms",7000,"duration_ms",20000,"completed",false,"episode",a.obj("show_id",1))));
   if(path.equals("/v4/home"))return a.obj("featured_id",1,"collections",new JSONArray().put(a.obj("title","Escolhas do Cineo","items",new JSONArray().put(show))),"upcoming",new JSONArray().put(new JSONObject(show.toString()).put("premiere_at","2026-12-01T22:00:00Z")));
   if(path.startsWith("/v4/show/")&&path.endsWith("/extras"))return a.obj("premiere_at",JSONObject.NULL,"trailer_url","","owner_id","ui-fixture");
   if(path.equals("/v4/profile"))return method.equals("POST")?payload:a.obj("name","Criador de histórias","bio","Histórias independentes.","avatar","");
   if(path.startsWith("/v4/creator/"))return a.obj("name","Criador de histórias","bio","Histórias independentes.","avatar","","followers",8,"items",new JSONArray().put(show));
   if(path.startsWith("/v4/follow?"))return a.obj("following",false);
   if(path.equals("/v4/follow"))return a.obj("following",payload.optBoolean("following"));
   if(path.equals("/v4/following"))return a.obj("items",new JSONArray().put(show));
   if(path.equals("/v4/notifications"))return a.obj("items",new JSONArray().put(a.obj("title","Novo episódio","show",show,"created_at","2026-11-04T12:00:00Z","read",false)));
   if(path.equals("/v4/analytics"))return a.obj("followers",8,"items",new JSONArray().put(a.obj("title","Asfalto e Segredos","viewers",12,"completed",9,"likes",6)));
   if(path.equals("/v4/editorial"))return a.obj("config",a.obj("featured_id",1),"items",new JSONArray().put(a.obj("id",1,"title","Histórias para maratonar","show_ids",new JSONArray().put(1),"position",1,"active",true)));
   if(path.equals("/v4/episode-queue"))return a.obj("items",new JSONArray().put(new JSONObject(episodes.getJSONObject(0).toString()).put("show_id",1).put("show",show).put("review_status","pending")));
   if(path.equals("/v4/reports"))return a.obj("items",new JSONArray().put(a.obj("id",1,"kind","comment","target_id",1,"reason","Comentário a revisar","status","open")));
   if(path.equals("/shows/1"))return show;
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
  };a.catalog(false);});capture("03-home");assertEquals("home",a.screen);assertEquals("Cloud resume imported",7000,a.prefs.getInt(a.local("episode_11"),0));
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
  JSONArray playable=new JSONArray().put(new JSONObject().put("id",99).put("title","Teste do player").put("subtitles","WEBVTT\n\n00:00:00.000 --> 00:00:05.000\nLegenda do Cineo\n").put("url",sample.toURI().toString()));
  ui(()->a.play(show,playable,0,"catalog"));
  final boolean[] prepared={false};for(int i=0;i<100&&!prepared[0];i++){ui(()->prepared[0]=a.video!=null&&a.video.getDuration()>0);Thread.sleep(100);}assertTrue("Player must decode H264 MP4",prepared[0]);capture("18-player");ui(()->{assertEquals(1,a.pro.cues.size());assertEquals(5000,a.pro.cues.get(0).end);a.pro.locked=true;a.controlsVisible(false);a.controlsVisible(true);assertEquals(android.view.View.GONE,a.playerControls.getVisibility());a.pro.locked=false;});
  ui(()->{long base=android.os.SystemClock.uptimeMillis();float x=a.playerFrame.getWidth()*.85f,y=a.playerFrame.getHeight()*.32f;for(int k=0;k<4;k++){android.view.MotionEvent event=android.view.MotionEvent.obtain(base,base+k*45,k%2==0?android.view.MotionEvent.ACTION_DOWN:android.view.MotionEvent.ACTION_UP,x,y,0);a.playerFrame.dispatchTouchEvent(event);event.recycle();}});Thread.sleep(600);
  ui(()->{assertTrue("Double tap gesture seeks forward",a.video.getCurrentPosition()>5000);a.video.seekTo(0);});Thread.sleep(500);
  ui(()->{assertNotNull(a.media);a.togglePlayback();assertFalse(a.video.isPlaying());a.seekBy(10000);});Thread.sleep(500);
  ui(()->{assertTrue("Seek must advance playback",a.video.getCurrentPosition()>5000);a.togglePlayback();a.fullscreenPlayer();});capture("19-fullscreen");
  ui(()->{assertTrue(a.playerFullscreen);a.fullscreenPlayer();});Thread.sleep(700);
  ui(()->{assertNotNull(a.video);assertTrue("Player survives fullscreen",a.video.getDuration()>0);assertTrue("Fullscreen retains position",a.video.getCurrentPosition()>5000);a.media.setPlaybackParams(a.media.getPlaybackParams().setSpeed(1.25f));assertEquals(1.25f,a.media.getPlaybackParams().getSpeed(),.01f);a.toggleLike();});Thread.sleep(600);ui(()->assertTrue("Like state returned by server",a.liked));
  ui(()->a.toggleSocialSave());Thread.sleep(600);ui(()->assertTrue("Save state returned by server",a.socialSaved));
  ui(()->a.comments());Thread.sleep(600);capture("20-comments");
  ui(()->{android.view.View content=a.commentsDialog.getWindow().getDecorView();((EditText)find(content,"Escreva um comentário…")).setText("Comentário de teste");find(content,"Publicar comentário").performClick();});Thread.sleep(700);assertEquals("Comment sent once to the current episode",1,posted.get());capture("22-comment-published");ui(()->a.commentsDialog.dismiss());
  JSONArray sequence=new JSONArray();for(int i=0;i<3;i++)sequence.put(new JSONObject(playable.getJSONObject(0).toString()).put("id",99+i).put("season",1).put("episode_number",i+1).put("title","Capítulo "+(i+1)));
  ui(()->{a.stopVideo();a.prefs.edit().putInt(a.local("episode_99"),0).apply();a.play(show,sequence,0,"catalog");});ready(a);
  ui(()->{assertEquals("Player fills the root",a.root.getHeight()-a.root.getPaddingTop()-a.root.getPaddingBottom(),a.playerFrame.getHeight());assertEquals("No scroll container beneath the player",1,a.root.getChildCount());a.video.seekTo(10000);});Thread.sleep(500);ui(()->a.video.pause());
  vertical(a,true);Thread.sleep(600);ready(a);ui(()->{assertEquals(100,a.playingEpisode);assertEquals(1,a.activeIndex);assertTrue("Previous chapter position saved",a.prefs.getInt(a.local("episode_99"),0)>5000);});capture("37-swipe-next");
  vertical(a,true);Thread.sleep(600);ready(a);ui(()->assertEquals(101,a.playingEpisode));android.widget.VideoView last=a.video;vertical(a,true);Thread.sleep(500);ui(()->{assertEquals("Last chapter cannot overflow",101,a.playingEpisode);assertSame("Boundary swipe cannot restart video",last,a.video);});
  vertical(a,false);Thread.sleep(600);ready(a);ui(()->assertEquals(100,a.playingEpisode));vertical(a,false);Thread.sleep(600);ready(a);Thread.sleep(300);ui(()->{assertEquals(99,a.playingEpisode);assertTrue("Return resumes chapter",a.video.getCurrentPosition()>5000);a.video.pause();});capture("38-swipe-previous");
  vertical(a,false);Thread.sleep(400);ui(()->assertEquals("First chapter cannot underflow",99,a.playingEpisode));
  ui(()->a.drama.setLocked(true));vertical(a,true);Thread.sleep(400);ui(()->{assertEquals("Locked swipe cannot navigate",99,a.playingEpisode);a.drama.setLocked(false);});
  swipe(a,a.playerFrame.getWidth()*.15f,a.playerFrame.getHeight()*.35f,a.playerFrame.getWidth()*.75f,a.playerFrame.getHeight()*.35f);Thread.sleep(350);ui(()->assertEquals("Horizontal drag does not change episode",99,a.playingEpisode));
  int[] seek=new int[2],rootPos=new int[2];ui(()->{a.timeline.getLocationOnScreen(seek);a.playerFrame.getLocationOnScreen(rootPos);});float sx=seek[0]-rootPos[0]+a.timeline.getWidth()*.5f,sy=seek[1]-rootPos[1]+a.timeline.getHeight()*.5f;swipe(a,sx,sy,sx,sy-a.dp(160));Thread.sleep(400);ui(()->assertEquals("Seek bar drag cannot change chapters",99,a.playingEpisode));
  ui(()->{a.stopVideo();a.prefs.edit().putInt(a.local("episode_99"),0).apply();a.play(show,playable,0,"catalog");});ready(a);vertical(a,true);Thread.sleep(400);ui(()->assertEquals("Single episode stays available",0,a.activeIndex));
  ui(()->a.episodeMenu());capture("21-episodes");InstrumentationRegistry.getInstrumentation().getUiAutomation().performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK);

  ui(()->a.pro.profileEditor());capture("23-public-profile-edit");
  ui(()->a.pro.creator("ui-fixture"));capture("24-creator");
  ui(()->a.pro.calendar());capture("25-premieres");
  ui(()->a.pro.following());capture("26-following");
  ui(()->a.pro.notifications());capture("27-notifications");
  ui(()->a.pro.studio(show));capture("28-studio");
  ui(()->a.pro.newEpisode(show));capture("29-new-episode");
  ui(()->a.pro.episodeAssets(show,episodes.optJSONObject(0)));capture("30-episode-assets");
  ui(()->a.pro.analytics());capture("31-analytics");
  ui(()->a.pro.editorial());capture("32-editorial");
  ui(()->a.pro.collection(null));capture("33-collection");
  ui(()->a.pro.episodeQueue());capture("34-episode-queue");
  ui(()->a.pro.reports());capture("35-reports");
  ui(()->a.pro.dataSettings());capture("36-data-settings");
  ui(()->{a.pro.captureLink(new android.content.Intent(android.content.Intent.ACTION_VIEW,android.net.Uri.parse("cineo://show/1")));assertTrue(a.pro.openLink());});settled();assertEquals("detail",a.screen);
  ui(()->{a.clearSession();a.login(false);});
 }
}
