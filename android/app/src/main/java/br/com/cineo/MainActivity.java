package br.com.cineo;

import android.app.*;
import android.os.*;
import android.content.*;
import android.net.Uri;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.view.*;
import android.widget.*;
import org.json.*;
import java.net.*;
import java.io.*;
import java.util.*;
import java.util.concurrent.*;

public class MainActivity extends Activity {
 LinearLayout body; String token="", role="", base=""; int selectedId; String episodeTitle;
 ExecutorService io=Executors.newSingleThreadExecutor(); TextView message;
 interface Done { void run(JSONObject result) throws Exception; }
 JSONObject obj(Object... pairs) throws Exception { JSONObject o=new JSONObject(); for(int i=0;i<pairs.length;i+=2)o.put((String)pairs[i],pairs[i+1]); return o; }
 @Override public void onCreate(Bundle b){super.onCreate(b); base=getPreferences(0).getString("server",""); if(base.isEmpty())settings();else login();}
 void page(String title,String subtitle){
  ScrollView scroll=new ScrollView(this); scroll.setFillViewport(true); scroll.setBackgroundColor(Color.rgb(13,14,21));
  body=new LinearLayout(this);body.setOrientation(1);body.setPadding(24,40,24,32);scroll.addView(body);setContentView(scroll);
  text("CINEO  /  DRAMAS",14,Color.rgb(255,80,108));text(title,30,Color.WHITE);text(subtitle,15,Color.LTGRAY);
  message=text("",14,Color.rgb(255,143,157));
 }
 TextView text(String s,int size,int color){ TextView v=new TextView(this);v.setText(s);v.setTextSize(size);v.setTextColor(color);v.setPadding(0,8,0,12);body.addView(v);return v; }
 EditText field(String hint,boolean secret){EditText e=new EditText(this);e.setHint(hint);e.setTextColor(Color.WHITE);e.setHintTextColor(Color.GRAY);e.setSingleLine(true);if(secret)e.setInputType(129);body.addView(e);return e;}
 void button(String label,Runnable action){Button b=new Button(this);b.setText(label);b.setAllCaps(false);b.setTextColor(Color.WHITE);GradientDrawable bg=new GradientDrawable();bg.setColor(Color.rgb(170,35,72));bg.setCornerRadius(24);b.setBackground(bg);LinearLayout.LayoutParams lp=new LinearLayout.LayoutParams(-1,56);lp.setMargins(0,8,0,8);body.addView(b,lp);b.setOnClickListener(v->action.run());}
 void safe(Throwing r){try{r.run();}catch(Exception e){message.setText("Não foi possível concluir. "+e.getMessage());}}
 interface Throwing {void run() throws Exception;}
 void call(String method,String path,JSONObject payload,Done done){
  TextView status=message;status.setText("Carregando…");io.execute(()->{try{
   HttpURLConnection c=(HttpURLConnection)new URL(base+path).openConnection();c.setRequestMethod(method);c.setConnectTimeout(15000);c.setReadTimeout(120000);c.setInstanceFollowRedirects(false);
   if(!token.isEmpty())c.setRequestProperty("Authorization","Bearer "+token);
   if(payload!=null){c.setDoOutput(true);c.setRequestProperty("Content-Type","application/json");try(OutputStream out=c.getOutputStream()){out.write(payload.toString().getBytes("UTF-8"));}}
   int code=c.getResponseCode();InputStream stream=code<400?c.getInputStream():c.getErrorStream();ByteArrayOutputStream bytes=new ByteArrayOutputStream();if(stream!=null){byte[] buf=new byte[8192];int n;while((n=stream.read(buf))!=-1)bytes.write(buf,0,n);stream.close();}c.disconnect();JSONObject result=new JSONObject(bytes.toString("UTF-8"));
   if(code>=400)throw new IOException(result.optString("error","Falha na solicitação."));
   runOnUiThread(()->{status.setText("");safe(()->done.run(result));});
  }catch(Exception e){runOnUiThread(()->status.setText(e instanceof IOException?e.getMessage():"Servidor indisponível ou resposta inválida."));}});
 }
 void settings(){page("Conectar plataforma","Informe o endereço HTTPS do servidor Cineo.");EditText server=field("https://seu-servidor",false);server.setText(base);button("Salvar conexão",()->{String v=server.getText().toString().trim().replaceAll("/+$","");try{URL u=new URL(v);if(!u.getProtocol().equals("https")||u.getHost().isEmpty()||u.getUserInfo()!=null||!u.getPath().isEmpty())throw new Exception();base=v;getPreferences(0).edit().putString("server",base).apply();token="";login();}catch(Exception e){message.setText("Use um endereço HTTPS válido sem caminho.");}});}
 void login(){page("Sua próxima história","Entre para assistir ou publicar suas produções.");EditText email=field("Email",false),pw=field("Senha (mínimo 10 caracteres)",true);
  for(String route:new String[]{"login","register"})button(route.equals("login")?"Entrar":"Criar conta",()->safe(()->call("POST","/"+route,obj("email",email.getText().toString(),"password",pw.getText().toString()),r->{token=r.getString("token");role=r.getString("role");list("/catalog");})));
  button("Configurar conexão",()->settings());
 }
 String state(String s){switch(s){case "pending":return "Em análise";case "approved":return "Aprovada";case "rejected":return "Reprovada";default:return "Rascunho";}}
 void list(String path){page(path.equals("/queue")?"Análise de publicações":path.equals("/mine")?"Minhas produções":"Descubra histórias","Novelas, séries e mini dramas independentes.");
  button("Explorar",()->list("/catalog"));button("Minhas produções",()->list("/mine"));button("Criar produção",()->create());if(role.equals("admin"))button("Painel de análise",()->list("/queue"));
  button("Sair",()->call("POST","/logout",new JSONObject(),r->{token="";role="";login();}));
  call("GET",path,null,r->{JSONArray a=r.getJSONArray("items");if(a.length()==0)text("Nenhuma produção por aqui ainda.",18,Color.LTGRAY);for(int i=0;i<a.length();i++){JSONObject s=a.getJSONObject(i);text(state(s.optString("status")),12,Color.rgb(255,116,140));button(s.getString("title"),()->details(s,path));}});
 }
 void create(){page("Conte sua história","Crie um rascunho e adicione os episódios.");EditText title=field("Título da produção",false),syn=field("Sinopse",false);syn.setSingleLine(false);syn.setMinLines(3);button("Criar rascunho",()->safe(()->call("POST","/shows",obj("title",title.getText().toString(),"synopsis",syn.getText().toString()),r->list("/mine"))));button("Voltar",()->list("/mine"));}
 void details(JSONObject s,String origin){safe(()->{
  int id=s.getInt("id");String status=s.getString("status");page(s.getString("title"),s.getString("synopsis"));text(state(status),16,Color.WHITE);if(!s.optString("reason").isEmpty())text("Motivo: "+s.getString("reason"),16,Color.rgb(255,143,157));
  if(origin.equals("/mine")&&(status.equals("draft")||status.equals("rejected"))){
   button("Adicionar episódio MP4",()->{EditText title=new EditText(this);title.setHint("Título do episódio");new AlertDialog.Builder(this).setTitle("Novo episódio • até 25 MB").setView(title).setNegativeButton("Cancelar",null).setPositiveButton("Escolher vídeo",(d,w)->{if(title.getText().toString().trim().isEmpty()){message.setText("Informe o título.");return;}selectedId=id;episodeTitle=title.getText().toString();Intent intent=new Intent(Intent.ACTION_OPEN_DOCUMENT);intent.addCategory(Intent.CATEGORY_OPENABLE);intent.setType("video/mp4");startActivityForResult(intent,7);}).show();});
   button("Enviar para análise",()->new AlertDialog.Builder(this).setTitle("Autorização de publicação").setMessage("Declaro que possuo os direitos ou autorização para distribuir todos os episódios desta produção.").setNegativeButton("Cancelar",null).setPositiveButton("Confirmar e enviar",(d,w)->safe(()->call("POST","/shows/"+id+"/submit",obj("rights",true),r->list("/mine")))).show());
  }
  if(origin.equals("/queue")&&role.equals("admin")){
   button("Aprovar publicação",()->new AlertDialog.Builder(this).setTitle("Publicar esta produção?").setMessage("Todos os episódios ficarão disponíveis ao público.").setNegativeButton("Cancelar",null).setPositiveButton("Aprovar",(d,w)->safe(()->call("POST","/shows/"+id+"/review",obj("decision","approved"),r->list("/queue")))).show());
   button("Reprovar",()->{EditText reason=new EditText(this);reason.setHint("Motivo da reprovação");new AlertDialog.Builder(this).setTitle("Orientação para o criador").setView(reason).setNegativeButton("Cancelar",null).setPositiveButton("Reprovar",(d,w)->safe(()->call("POST","/shows/"+id+"/review",obj("decision","rejected","reason",reason.getText().toString()),r->list("/queue")))).show();});
  }
  button("Voltar",()->list(origin));call("GET","/shows/"+id+"/episodes",null,r->{JSONArray a=r.getJSONArray("items");if(a.length()==0)text("Adicione seu primeiro episódio.",16,Color.LTGRAY);for(int i=0;i<a.length();i++){JSONObject e=a.getJSONObject(i);button(e.getString("title"),()->safe(()->play(e,s,origin)));}});
 });}
 void play(JSONObject e,JSONObject s,String origin)throws Exception{page(e.getString("title"),"Toque no vídeo para exibir os controles.");VideoView video=new VideoView(this);body.addView(video,new LinearLayout.LayoutParams(-1,650));MediaController controls=new MediaController(this);controls.setAnchorView(video);video.setMediaController(controls);Map<String,String> headers=new HashMap<>();headers.put("Authorization","Bearer "+token);video.setVideoURI(Uri.parse(base+e.getString("url")),headers);video.setOnPreparedListener(mp->video.start());video.setOnErrorListener((mp,a,b)->{message.setText("Não foi possível reproduzir este MP4.");return true;});button("Voltar aos episódios",()->{video.stopPlayback();details(s,origin);});}
 @Override protected void onActivityResult(int request,int result,Intent data){super.onActivityResult(request,result,data);if(request!=7||result!=RESULT_OK||data==null)return;Uri uri=data.getData();int sid=selectedId;String title=episodeTitle;message.setText("Preparando vídeo…");io.execute(()->{try(InputStream in=getContentResolver().openInputStream(uri)){ByteArrayOutputStream bytes=new ByteArrayOutputStream();byte[] buf=new byte[65536];int n;while((n=in.read(buf))!=-1){if(bytes.size()+n>25*1024*1024)throw new IOException("Escolha um MP4 de até 25 MB.");bytes.write(buf,0,n);}JSONObject payload=obj("title",title,"video",android.util.Base64.encodeToString(bytes.toByteArray(),android.util.Base64.NO_WRAP));runOnUiThread(()->call("POST","/shows/"+sid+"/episodes",payload,r->list("/mine")));}catch(Exception e){runOnUiThread(()->message.setText("Não foi possível ler o vídeo. "+e.getMessage()));}});}
 @Override protected void onDestroy(){super.onDestroy();io.shutdown();}
}

