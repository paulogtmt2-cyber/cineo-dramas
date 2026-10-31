package br.com.cineo;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.rule.ActivityTestRule;
import androidx.test.platform.app.InstrumentationRegistry;
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
 void capture(String name)throws Exception{Thread.sleep(400);Bitmap image=InstrumentationRegistry.getInstrumentation().getUiAutomation().takeScreenshot();assertNotNull(image);File dir=new File(rule.getActivity().getExternalFilesDir(null),"screens");dir.mkdirs();try(FileOutputStream out=new FileOutputStream(new File(dir,name+".png"))){image.compress(Bitmap.CompressFormat.PNG,100,out);}image.recycle();}
 @Test public void screenLayoutsAndValidation()throws Exception{
  MainActivity a=rule.getActivity();capture("01-login");assertEquals("login",a.screen);
  ui(()->a.login(true));capture("02-register");
  ui(()->{a.token="test-ui-only";a.uid="ui-fixture";a.email="criador@example.test";a.role="admin";a.profile();});capture("03-profile");
  ui(()->a.settings());capture("04-settings");
  ui(()->a.edit(null));capture("05-create");assertEquals("edit",a.screen);
  JSONObject show=new JSONObject().put("id",1).put("title","Asfalto e Segredos").put("synopsis","Uma história de escolhas, encontros e novos caminhos.").put("genre","Drama").put("rating","14").put("status","pending").put("cover_url","");
  ui(()->a.reject(show));capture("06-review-rejection");
  ui(()->{a.page("home","Explore o Cineo","Novas histórias. Novos criadores.",0,null);a.renderCatalog(a.body,new JSONArray().put(show),"","Todos",false);});capture("07-catalog-fixture");
  ui(()->{a.page("search","Encontre sua história","",1,null);a.renderCatalog(a.body,new JSONArray().put(show),"inexistente","Todos",true);});capture("08-search-empty");
  ui(()->{a.page("home","Explore o Cineo","",0,null);a.renderCatalog(a.body,new JSONArray(),"","Todos",false);});capture("09-real-empty-state");
  ui(()->{a.currentShow=show;a.addEpisode(1);});capture("10-upload");
  ui(()->a.password());capture("11-password");
  ui(()->{a.clearSession();a.login(false);});
 }
}
