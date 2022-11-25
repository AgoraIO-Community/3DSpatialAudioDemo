package io.agora.nathan.spatialsound.common;

import android.content.Context;
import android.util.Log;
import android.view.SurfaceView;

import java.util.ArrayList;
import java.util.List;

import io.agora.mediaplayer.IMediaPlayer;
import io.agora.nathan.spatialsound.R;
import io.agora.rtc2.ChannelMediaOptions;
import io.agora.rtc2.IRtcEngineEventHandler;
import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.RtcEngineConfig;
import io.agora.rtc2.video.VideoCanvas;
import io.agora.spatialaudio.ILocalSpatialAudioEngine;
import io.agora.spatialaudio.LocalSpatialAudioConfig;
import io.agora.spatialaudio.RemoteVoicePositionInfo;

public class AgoraManager {
    private static final String TAG = "AgoraManager";
    private static volatile AgoraManager sInstance = null;
    private String appId;
    private int areaCode;
    private RtcEngine engine;
    private AgoraManager.InnerRtcEngineEventHandler iRtcEngineEventHandler = new AgoraManager.InnerRtcEngineEventHandler();
    private ILocalSpatialAudioEngine localSpatial;
    private boolean joined = false;


    private ArrayList<Integer> users = new ArrayList<Integer>();

    public static AgoraManager getInstance() {
        if (sInstance == null) {
            synchronized (AgoraManager.class) {
                if (sInstance == null) {
                    sInstance = new AgoraManager();
                }
            }
        }
        return sInstance;
    }

    private AgoraManager() {

    }


    public boolean createEnine(Context context)
    {
        return createEngine(context, appId, areaCode);
    }

    public boolean createEngine(Context context, String appId, int areaCode)
    {
        try{
            /**Creates an RtcEngine instance.
             * @param context The context of Android Activity
             * @param appId The App ID issued to you by Agora. See <a href="https://docs.agora.io/en/Agora%20Platform/token#get-an-app-id">
             *              How to get the App ID</a>
             * @param handler IRtcEngineEventHandler is an abstract class providing default implementation.
             *                The SDK uses this class to report to the app on SDK runtime events.*/
            //String appId = getString(R.string.agora_app_id);
            RtcEngineConfig config = new RtcEngineConfig();
            config.mContext = context.getApplicationContext();
            config.mAppId = appId;
            config.mEventHandler = iRtcEngineEventHandler;
            config.mAreaCode = areaCode;
            engine = RtcEngine.create(config);
            engine.setDefaultAudioRoutetoSpeakerphone(true);

            this.appId = appId;
            this.areaCode = areaCode;
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    public IMediaPlayer createMediaPlayer()
    {
        return engine.createMediaPlayer();
    }

    public ArrayList<Integer> getAllUsers()
    {
        return users;
    }

    public void addRtcEngineEventHandler(IRtcEngineEventHandler handler)
    {
        if (engine == null) {
            Log.e(TAG, "RTC engine has not been initialized");
        } else {
            engine.addHandler(handler);
        }
    }

    public void removeRtcEngineEventHandler(IRtcEngineEventHandler handler)
    {
        if (engine == null) {
            Log.e(TAG, "RTC engine has not been initialized");
        } else {
            engine.removeHandler(handler);
        }
    }


    public boolean startLocalSpatialSound(boolean muteRemoteAudio)
    {
        if (engine == null) {
            Log.e(TAG, "RTC engine has not been initialized");
            return false;
        }
        engine.setDefaultAudioRoutetoSpeakerphone(true);
        LocalSpatialAudioConfig localSpatialAudioConfig = new LocalSpatialAudioConfig();
        localSpatialAudioConfig.mRtcEngine = engine;
        localSpatial = ILocalSpatialAudioEngine.create();
        localSpatial.initialize(localSpatialAudioConfig);
        localSpatial.muteLocalAudioStream(true);
        localSpatial.muteAllRemoteAudioStreams(muteRemoteAudio);
        localSpatial.setAudioRecvRange(50);
        localSpatial.setDistanceUnit(1);

        setDefaultSelfPosition();
        return true;
    }

    public void setDefaultSelfPosition()
    {
        float[] pos = new float[]{0.0F, 0.0F, 0.0F};
        float[] forward = new float[]{0.0F, 1.0F, 0.0F};
        float[] right = new float[]{1.0F, 0.0F, 0.0F};
        float[] up = new float[]{0.0F, 0.0F, 1.0F};
        localSpatial.updateSelfPosition(pos, forward, right, up);
    }

    public boolean isJoined()
    {
        return joined;
    }

    public boolean joinChannel(String channelId)
    {
        if (engine == null) {
            Log.e(TAG, "RTC engine has not been initialized");
            return false;
        }
        ChannelMediaOptions option = new ChannelMediaOptions();
        option.autoSubscribeAudio = true;
        option.autoSubscribeVideo = true;
        option.publishMicrophoneTrack = true;
        option.publishCameraTrack = true;

        engine.joinChannel("", channelId, 0, option);

        joined = true;
        return true;
    }

    public void leaveChannel()
    {
        if (engine == null) {
            Log.e(TAG, "RTC engine has not been initialized");
            return;
        }
        engine.leaveChannel();
        joined = false;
    }

    public void setupRemoteVideo(VideoCanvas view)
    {
        if (engine == null) {
            Log.e(TAG, "RTC engine has not been initialized");
            return;
        }
        engine.setupRemoteVideo(view);
    }

    public void updatePlayerPositionInfo(IMediaPlayer mediaPlayer, RemoteVoicePositionInfo position)
    {
        if (localSpatial == null) {
            Log.e(TAG, "RTC engine has not been initialized");
            return;
        }
        localSpatial.updatePlayerPositionInfo(mediaPlayer.getMediaPlayerId(), position);
    }

    public void updateRemotePosition(int uid, RemoteVoicePositionInfo position)
    {
        if (localSpatial == null) {
            Log.e(TAG, "RTC engine has not been initialized");
            return;
        }
        localSpatial.updateRemotePosition(uid, position);
    }

    public void resetLocalSpatial()
    {
        localSpatial = null;
    }

    public void destroy()
    {

        engine = null;
    }

    public void addUser(Integer uid) {

        if(!users.contains(uid)) {
            users.add(uid);
        }
    }

    public void removeUser(Integer uid)
    {
        if(users.contains(uid))
            users.remove(uid);
    }

    public void setAppId(String appId)
    {
        this.appId = appId;
    }

    public void setAreaCode(int areaCode)
    {
        this.areaCode = areaCode;
    }

    /**
     * IRtcEngineEventHandler is an abstract class providing default implementation.
     * The SDK uses this class to report to the app on SDK runtime events.
     */
    private class InnerRtcEngineEventHandler extends IRtcEngineEventHandler {
        /**
         * Reports a warning during SDK runtime.
         * Warning code: https://docs.agora.io/en/Voice/API%20Reference/java/classio_1_1agora_1_1rtc_1_1_i_rtc_engine_event_handler_1_1_warn_code.html
         */
        @Override
        public void onWarning(int warn) {
            Log.w(TAG, String.format("onWarning code %d message %s", warn, RtcEngine.getErrorDescription(warn)));
        }

        /**
         * Reports an error during SDK runtime.
         * Error code: https://docs.agora.io/en/Voice/API%20Reference/java/classio_1_1agora_1_1rtc_1_1_i_rtc_engine_event_handler_1_1_error_code.html
         */
        @Override
        public void onError(int err) {
            Log.e(TAG, String.format("onError code %d message %s", err, RtcEngine.getErrorDescription(err)));
            //AgoraManager.getInstance().onError(err);
            //showAlert(String.format("onError code %d message %s", err, RtcEngine.getErrorDescription(err)));
        }

        /**
         * Occurs when a remote user (Communication)/host (Live Broadcast) joins the channel.
         *
         * @param uid     ID of the user whose audio state changes.
         * @param elapsed Time delay (ms) from the local user calling joinChannel/setClientRole
         *                until this callback is triggered.
         */
        @Override
        public void onUserJoined(int uid, int elapsed) {
            super.onUserJoined(uid, elapsed);
            Log.i(TAG, "onUserJoined->" + uid);
            //showLongToast(String.format("user %d joined!", uid));
            addUser(uid);

        }

        /**
         * Occurs when a remote user (Communication)/host (Live Broadcast) leaves the channel.
         *
         * @param uid    ID of the user whose audio state changes.
         * @param reason Reason why the user goes offline:
         *               USER_OFFLINE_QUIT(0): The user left the current channel.
         *               USER_OFFLINE_DROPPED(1): The SDK timed out and the user dropped offline because no data
         *               packet was received within a certain period of time. If a user quits the
         *               call and the message is not passed to the SDK (due to an unreliable channel),
         *               the SDK assumes the user dropped offline.
         *               USER_OFFLINE_BECOME_AUDIENCE(2): (Live broadcast only.) The client role switched from
         *               the host to the audience.
         */
        @Override
        public void onUserOffline(int uid, int reason) {
            Log.i(TAG, String.format("user %d offline! reason:%d", uid, reason));
            removeUser(uid);
        }

    }
}
