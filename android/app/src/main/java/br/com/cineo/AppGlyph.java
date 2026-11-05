package br.com.cineo;
import android.content.Context;import android.graphics.*;import android.view.View;
/** One consistent, scalable outline icon family for the workspace. */
class AppGlyph extends View {
 final String kind;final int color;Paint p=new Paint(3);AppGlyph(Context c,String name,int tint){super(c);kind=name;color=tint;setImportantForAccessibility(IMPORTANT_FOR_ACCESSIBILITY_NO);}
 void line(Canvas c,float...v){for(int i=0;i+3<v.length;i+=2)c.drawLine(v[i],v[i+1],v[i+2],v[i+3],p);}void box(Canvas c,float l,float t,float r,float b,float radius){c.drawRoundRect(l,t,r,b,radius,radius,p);}
 protected void onDraw(Canvas c){super.onDraw(c);c.save();c.scale(getWidth()/24f,getHeight()/24f);p.setColor(color);p.setStyle(Paint.Style.STROKE);p.setStrokeWidth(1.7f);p.setStrokeCap(Paint.Cap.ROUND);p.setStrokeJoin(Paint.Join.ROUND);switch(kind){
 case "save":line(c,6,21,6,3,18,3,18,21,12,17,6,21);break;
 case "download":line(c,12,2,12,15);line(c,6,9,12,15,18,9);line(c,3,16,3,21,21,21,21,16);break;
 case "upload":line(c,12,17,12,3);line(c,6,9,12,3,18,9);line(c,3,16,3,21,21,21,21,16);break;
 case "history":c.drawArc(3,3,21,21,-120,315,false,p);line(c,3,3,3,9,8,9);line(c,12,7,12,12,16,14);break;
 case "layers":line(c,2,7,12,2,22,7,12,12,2,7);line(c,2,12,12,17,22,12);line(c,2,17,12,22,22,17);break;
 case "team":c.drawCircle(8,6,3,p);c.drawCircle(18,7,2.6f,p);c.drawArc(2,12,14,26,180,180,false,p);c.drawArc(13,13,23,24,180,160,false,p);break;
 case "check":c.drawCircle(12,12,9,p);line(c,7,12,10.5f,15.5f,17,8.5f);break;
 case "film":box(c,3,6,21,21,2);line(c,3,6,3,2,21,2,21,6,3,6);line(c,8,2,11,6);line(c,15,2,18,6);line(c,10,10,16,13,10,17,10,10);break;
 case "plus":box(c,3,3,21,21,3);line(c,12,7,12,17);line(c,7,12,17,12);break;
 case "chart":line(c,3,20,3,14);line(c,9,20,9,10);line(c,15,20,15,6);line(c,21,20,21,2);break;
 case "chat":box(c,3,3,21,18,3);line(c,6,18,6,22,11,18);line(c,8,8,8,12);line(c,12,7,12,13);line(c,16,9,16,12);break;
 case "person":c.drawCircle(12,6,4,p);c.drawArc(3,12,21,30,180,180,false,p);break;
 case "switch":c.drawCircle(8,7,3,p);c.drawArc(2,13,14,27,180,180,false,p);line(c,15,6,22,6,20,4);line(c,22,6,20,8);line(c,22,15,15,15,17,13);line(c,15,15,17,17);break;
 case "lock":box(c,4,10,20,22,2);c.drawArc(7,1,17,15,180,180,false,p);c.drawCircle(12,15.5f,1.2f,p);line(c,12,17,12,19);break;
 case "shield":line(c,12,2,21,6,20,14,17,19,12,22,7,19,4,14,3,6,12,2);break;
 case "headset":c.drawArc(3,2,21,21,180,180,false,p);box(c,2,11,6,20,1.5f);box(c,18,11,22,20,1.5f);line(c,20,20,18,23,14,23);break;
 case "refresh":c.drawArc(3,3,21,21,30,145,false,p);c.drawArc(3,3,21,21,210,145,false,p);line(c,3,4,3,10,9,10);line(c,21,20,21,14,15,14);break;
 case "search":c.drawCircle(10,10,7,p);line(c,15,15,22,22);break;
 case "gear":for(int i=0;i<8;i++){c.save();c.rotate(i*45,12,12);box(c,10,1,14,5,1);c.restore();}c.drawCircle(12,12,7,p);c.drawCircle(12,12,3,p);break;
 case "home":line(c,2,11,12,2,22,11);line(c,5,9,5,22,10,22,10,15,14,15,14,22,19,22,19,9);break;
 case "library":box(c,2,3,22,21,3);line(c,8,7,8,17,17,12,8,7);break;
 case "arrow":line(c,9,5,16,12,9,19);break;
 case "edit":line(c,4,16,16,4,20,8,8,20,3,21,4,16);line(c,13,7,17,11);break;
 case "bell":c.drawArc(5,3,19,17,180,180,false,p);line(c,5,10,5,16,3,19,21,19,19,16,19,10);c.drawArc(9,18,15,24,0,180,false,p);break;
 case "calendar":box(c,3,5,21,22,2);line(c,3,10,21,10);line(c,7,2,7,7);line(c,17,2,17,7);break;
 case "clock":c.drawCircle(12,12,9,p);line(c,12,6,12,12,16,14);break;
 default:box(c,3,3,21,21,3);line(c,7,8,17,8);line(c,7,12,17,12);line(c,7,16,14,16);}
 c.restore();}
}
