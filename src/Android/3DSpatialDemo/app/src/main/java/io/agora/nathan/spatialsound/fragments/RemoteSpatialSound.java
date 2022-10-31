package io.agora.nathan.spatialsound.fragments;

import static io.agora.rtc2.Constants.RENDER_MODE_HIDDEN;

import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import io.agora.nathan.spatialsound.MainActivity;
import io.agora.nathan.spatialsound.R;
import io.agora.nathan.spatialsound.common.BaseFragment;
import io.agora.nathan.spatialsound.common.PositionManager;
import io.agora.nathan.spatialsound.widgets.VideoLayout;
import io.agora.rtc2.ChannelMediaOptions;
import io.agora.rtc2.IRtcEngineEventHandler;
import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.RtcEngineConfig;
import io.agora.rtc2.video.VideoCanvas;
import io.agora.spatialaudio.ILocalSpatialAudioEngine;
import io.agora.spatialaudio.LocalSpatialAudioConfig;

public class RemoteSpatialSound extends BaseFragment {
    private static final String TAG = RemoteSpatialSound.class.getSimpleName();
    private RtcEngine engine;

    private ImageView listenerIv;
    private ILocalSpatialAudioEngine localSpatial;
    private final RemoteSpatialSound.ListenerOnTouchListener listenerOnTouchListener = new RemoteSpatialSound.ListenerOnTouchListener();
    private final RemoteSpatialSound.InnerRtcEngineEventHandler iRtcEngineEventHandler = new RemoteSpatialSound.InnerRtcEngineEventHandler();
    private VideoLayout[] seats = new VideoLayout[8];
    private Map<Integer, ViewGroup> remoteViews = new ConcurrentHashMap<Integer, ViewGroup>();
    private boolean joined = false;
    private EditText channel;
    private Button join;
    private static PositionManager posManager;



    private void joinChannel(String channelId)
    {
        // Check if the context is valid
        Context context = getContext();
        if (context == null)
        {
            return;
        }


        ChannelMediaOptions option = new ChannelMediaOptions();
        option.autoSubscribeAudio = true;
        option.autoSubscribeVideo = true;
        option.publishMicrophoneTrack = true;
        option.publishCameraTrack = true;

        engine.joinChannel("", channelId, 0, option);

        PositionManager.getInstance().setRtcEngine(engine);
        startLocalSpatialSound();
    }

    private void leaveChannel()
    {
        engine.leaveChannel();
        PositionManager.getInstance().reset();
    }

    private void startLocalSpatialSound()
    {
        LocalSpatialAudioConfig localSpatialAudioConfig = new LocalSpatialAudioConfig();
        localSpatialAudioConfig.mRtcEngine = engine;
        localSpatial = ILocalSpatialAudioEngine.create();
        localSpatial.initialize(localSpatialAudioConfig);
        localSpatial.muteLocalAudioStream(true);
        localSpatial.muteAllRemoteAudioStreams(true);
        localSpatial.setAudioRecvRange(50);
        localSpatial.setDistanceUnit(1);
        float[] pos = new float[]{0.0F, 0.0F, 0.0F};
        float[] forward = new float[]{1.0F, 0.0F, 0.0F};
        float[] right = new float[]{0.0F, 1.0F, 0.0F};
        float[] up = new float[]{0.0F, 0.0F, 1.0F};
        localSpatial.updateSelfPosition(pos, forward, right, up);
        PositionManager.getInstance().setLocalSpatialAudioEngine(localSpatial);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_remote_spatial_sound, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        PositionManager.getInstance().setContext(getContext());

        channel = view.findViewById(R.id.et_channel);
        join = (Button)view.findViewById(R.id.btn_join);
        listenerIv = view.findViewById(R.id.iv_listener);
        //listenerIv.setOnTouchListener(listenerOnTouchListener);
        join.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if(!joined) {

                    String channelId = channel.getText().toString();

                    joinChannel(channelId);
                    Log.i(TAG, "joidChannel:"+ channelId);

                    join.setText(R.string.leave);
                    channel.setEnabled(false);
                    joined = true;
                }
                else {
                    leaveChannel();
                    join.setText(R.string.join);
                    channel.setEnabled(true);
                    joined = false;
                }
            }
        });

        int[] seatIds = PositionManager.getInstance().getSeatIds();

        for(int i=0;i<seatIds.length;i++)
        {
            seats[i] = (VideoLayout) view.findViewById(seatIds[i]);
            seats[i].setSeatId(i);
            Log.i(TAG, "init seat:"+seats[i].getId());
            seats[i].setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    int id = ((VideoLayout)view).getSeatId();
                    PositionManager.getInstance().setSelectedSeat(id);
                }
            });
        }

        PositionManager.getInstance().setSeats(seats);
    }

    private void resetSpeaker(){
        listenerIv.setTranslationY(50);
        listenerIv.setTranslationX(0);
    }

    private void updateSpatialSoundParam() {
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        handler.removeCallbacksAndMessages(null);
        handler.post(RtcEngine::destroy);
        engine = null;
    }

    @Override
    public void onActivityCreated(@Nullable Bundle savedInstanceState) {
        super.onActivityCreated(savedInstanceState);
        // Check if the context is valid
        Context context = getContext();
        if (context == null) {
            return;
        }
        try {
            /**Creates an RtcEngine instance.
             * @param context The context of Android Activity
             * @param appId The App ID issued to you by Agora. See <a href="https://docs.agora.io/en/Agora%20Platform/token#get-an-app-id">
             *              How to get the App ID</a>
             * @param handler IRtcEngineEventHandler is an abstract class providing default implementation.
             *                The SDK uses this class to report to the app on SDK runtime events.*/
            String appId = getString(R.string.agora_app_id);
            RtcEngineConfig config = new RtcEngineConfig();
            config.mContext = getContext().getApplicationContext();
            config.mAppId = appId;
            config.mEventHandler = iRtcEngineEventHandler;
            config.mAreaCode = ((MainActivity)getActivity()).getGlobalSettings().getAreaCode();
            engine = RtcEngine.create(config);
            engine.setDefaultAudioRoutetoSpeakerphone(true);

        } catch (Exception e) {
            e.printStackTrace();
            getActivity().onBackPressed();
        }
    }

    private class ListenerOnTouchListener implements View.OnTouchListener {
        private float startX, startY, tranX, tranY, curX, curY, maxX, maxY, minX, minY;

        @Override
        public boolean onTouch(View v, MotionEvent event) {
            switch (event.getAction()) {
                case MotionEvent.ACTION_DOWN:
                    startX = event.getRawX();
                    startY = event.getRawY();
                    tranX = v.getTranslationX();
                    tranY = v.getTranslationY();
                    if (v.getParent() instanceof ViewGroup) {
                        maxX = (((ViewGroup) v.getParent()).getWidth() - v.getWidth() + 1) / 2;
                        maxY = (((ViewGroup) v.getParent()).getHeight() - v.getHeight() + 1) / 2;
                        minX = -maxX;
                        minY = -maxY;
                    }
                    break;
                case MotionEvent.ACTION_MOVE:
                    curX = event.getRawX();
                    curY = event.getRawY();
                    float newTranX = tranX + curX - startX;
                    if (minX != 0 && newTranX < minX) {
                        newTranX = minX;
                    }
                    if (maxX != 0 && newTranX > maxX) {
                        newTranX = maxX;
                    }
                    v.setTranslationX(newTranX);
                    float newTranY = tranY + curY - startY;
                    if (minY != 0 && newTranY < minY) {
                        newTranY = minY;
                    }
                    if (maxY != 0 && newTranY > maxY) {
                        newTranY = maxY;
                    }
                    v.setTranslationY(newTranY);
                    updateSpatialSoundParam();
                    break;
                case MotionEvent.ACTION_UP:
                    break;
            }
            return true;
        }
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
            showAlert(String.format("onError code %d message %s", err, RtcEngine.getErrorDescription(err)));
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
            showLongToast(String.format("user %d joined!", uid));

            /**Check if the context is correct*/
            Context context = getContext();
            if (context == null) {
                return;
            }
            int seatId = PositionManager.getInstance().takeSeat(uid, -1);
            if(seatId < 0){
                return;
            }
            else{
                handler.post(() ->
                {

                    PositionManager.getInstance().setUid2SeatView(uid, seatId);
                });
            }
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
            showLongToast(String.format("user %d offline! reason:%d", uid, reason));
            handler.post(new Runnable() {
                @Override
                public void run() {
                    /**Clear render view
                     Note: The video will stay at its last frame, to completely remove it you will need to
                     remove the SurfaceView from its parent*/
                    PositionManager.getInstance().leaveSeat(uid);
                }
            });
        }

    }
}
