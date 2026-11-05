package br.com.cineo;
import org.json.*;import android.os.SystemClock;
/** Server-observed heartbeats; paused video and local previews cannot generate views. */
class QualifiedPlayback {
 final MainActivity a;String id="";int page;long last,ticked,played;boolean pending=false,done=false;QualifiedPlayback(MainActivity activity){a=activity;}
 void setup(){id="";page=a.generation;last=0;ticked=SystemClock.elapsedRealtime();played=0;done=false;pending=false;if(!a.drama.publicEpisode()||a.token.isEmpty()||a.uid.equals(a.activeShow.optString("owner_id"))){done=true;return;}}
 void tick(){long now=SystemClock.elapsedRealtime(),delta=Math.max(0,Math.min(1000,now-ticked));ticked=now;if(done||page!=a.generation||a.video==null||!a.video.isPlaying()||a.scrubbing)return;played+=delta;if(pending)return;if(now-last<5000)return;last=now;send(id.isEmpty(),a.video.getCurrentPosition());}
 void finish(){if(!done&&!pending&&!id.isEmpty()&&a.video!=null)send(false,a.video.getCurrentPosition());}
 void send(boolean start,int position){pending=true;final int g=page,eid=a.playingEpisode;final String account=a.uid,viewer=a.viewerToken,session=id;final int active=(int)played;a.reads.execute(()->{try{a.requestViewer.set(viewer);a.readFlow.ensureSession(account);JSONObject r=a.request("POST",start?"/v10/view/start":"/v10/view/heartbeat",start?a.obj("episode_id",eid,"position_ms",position,"active_ms",active):a.obj("id",session,"position_ms",position,"active_ms",active),a.token);a.runOnUiThread(()->{if(g!=a.generation||page!=g||!account.equals(a.uid))return;if(start){id=r.optString("id");done=r.optBoolean("excluded");}else done=r.optBoolean("credited");pending=false;});}catch(Exception ignored){a.runOnUiThread(()->{if(page==g)pending=false;});}finally{a.requestViewer.remove();}});}
}
