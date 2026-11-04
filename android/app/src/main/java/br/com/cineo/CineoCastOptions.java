package br.com.cineo;
import android.content.Context;import com.google.android.gms.cast.CastMediaControlIntent;import com.google.android.gms.cast.framework.*;import com.google.android.gms.cast.framework.media.*;import java.util.List;
public class CineoCastOptions implements OptionsProvider {
 public CastOptions getCastOptions(Context context){return new CastOptions.Builder().setReceiverApplicationId(CastMediaControlIntent.DEFAULT_MEDIA_RECEIVER_APPLICATION_ID).setCastMediaOptions(new CastMediaOptions.Builder().setExpandedControllerActivityClassName(CineoCastController.class.getName()).setNotificationOptions(new NotificationOptions.Builder().setTargetActivityClassName(CineoCastController.class.getName()).build()).build()).build();}
 public List<SessionProvider> getAdditionalSessionProviders(Context c){return null;}
}
