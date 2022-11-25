package io.agora.nathan.spatialsound.common;

import static io.agora.rtc2.Constants.RENDER_MODE_HIDDEN;

import android.app.Fragment;
import android.content.Context;
import android.util.Log;
import android.view.SurfaceView;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import io.agora.nathan.spatialsound.R;
import io.agora.nathan.spatialsound.widgets.VideoLayout;
//import io.agora.rtc2.RtcEngine;
import io.agora.rtc2.video.VideoCanvas;
//import io.agora.spatialaudio.ILocalSpatialAudioEngine;
import io.agora.spatialaudio.RemoteVoicePositionInfo;

public class PositionManager {

    private static final String TAG = "PositionManager";
    private static volatile PositionManager sInstance = null;

    private Context context;
    // default distance
    // radius = 2.5m
    private static final float axial       = (float) 1.2;
    private static final float axialMinus  = (float) -1.2;
    private static final float slant       = (float) 0.722;
    private static final float slantMinus  = (float) -0.722;


    private static int[] seatUIds = new int[] {0,0,0,0,0,0,0,0};
    private static final int[] _seatIds = new int[] {
        R.id.st0, R.id.st1, R.id.st2, R.id.st3, R.id.st4, R.id.st5, R.id.st6, R.id.st7
    };
    private VideoLayout[] seats = new VideoLayout[8];

    private int selectedId = -1;
    public BaseFragment view;

    public static PositionManager getInstance() {
        if (sInstance == null) {
            synchronized (PositionManager.class) {
                if (sInstance == null) {
                    sInstance = new PositionManager();
                }
            }
        }
        return sInstance;
    }

    private PositionManager() {

    }

    public void setContext(Context context)
    {
        this.context = context;
    }

    public int takeSeat(int uid, int seatIndex) {

        if(seatIndex == -1) {
            seatIndex = nextEmptySeat();
        };
        if(seatUIds[seatIndex] > 0) {
            return -1;
        }
        seatUIds[seatIndex] = uid;
        changeSoundPosition(uid, seatIndex);
        return seatIndex;
    }

    public int leaveSeat(int uid) {
        for(int i = 0; i< seatUIds.length; i++)
        {
            if(seatUIds[i] == uid)
            {
                seatUIds[i] = 0;
                AgoraManager.getInstance().setupRemoteVideo(new VideoCanvas(null, RENDER_MODE_HIDDEN, uid));
                seats[i].removeAllViews();
                //seatViews.get(uid).removeAllViews();
                //seatViews.remove(uid);
                return i;
            }
        }
        return -1;
    }

    public int nextEmptySeat() {
        for(int i = 0; i< seatUIds.length; i++)
        {
            if(seatUIds[i] == 0)
            {
                return i;
            }
        }
        return -1;
    }

    public void changeSoundPosition(int uid, int seatIndex) {
        Log.i(TAG,"select seat "+seatIndex+" for user "+uid);
        float[] pos = new float[3];
        switch(seatIndex) {
            case 2:
                pos = new float[]{slantMinus, slant, slant};
                break;
            case 1:
                pos = new float[]{0, 0, axial};
                break;
            case 0:
                pos = new float[]{slant, slant, slant};
                break;
            case 4:
                pos = new float[]{axialMinus, 0, 0};
                break;
            case 3:
                pos = new float[]{axial, 0, 0};
                break;
            case 5:
                pos = new float[]{slantMinus, slantMinus, slantMinus};
                break;
            case 7:
                pos = new float[]{0, 0, axialMinus};
                break;
            case 6:
                pos = new float[]{slant, slant, slantMinus};
                break;
            default: // default, not on stage, from back
                pos = new float[]{0, axialMinus, 0};
                break;
        }

        updatePosition(uid, pos);
    }

    public void setUid2SeatView(int uid, int seatId)
    {
        /**Display remote video stream*/
        SurfaceView surfaceView = null;
        // Create render view by RtcEngine
        surfaceView = new SurfaceView(context);
        surfaceView.setZOrderMediaOverlay(true);

        VideoLayout view = seats[seatId];
        view.setVideoUid(uid);

        //seatViews.put(uid, view);
        // Add to the remote container
        view.addView(surfaceView, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        // Setup remote video to render
        //engine.setupRemoteVideo(new VideoCanvas(surfaceView, RENDER_MODE_HIDDEN, uid));
        AgoraManager.getInstance().setupRemoteVideo(new VideoCanvas(surfaceView, RENDER_MODE_HIDDEN, uid));
    }

    public void changeSeatView(int seatA, int seatB)
    {
        int uidA = seatUIds[seatA];
        int uidB = seatUIds[seatB];
        if(uidA == 0 && uidB == 0) return;
        if(uidB == 0) {
            // empty seat
            SurfaceView viewA = (SurfaceView)seats[seatA].getChildAt(0);
            seats[seatA].removeAllViews();
            seats[seatB].addView(viewA, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

            changeSoundPosition(uidA, seatB);

        }
        else if(uidA == 0) {
            // empty seat
            SurfaceView viewB = (SurfaceView)seats[seatB].getChildAt(0);
            seats[seatB].removeAllViews();
            seats[seatA].addView(viewB, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

            changeSoundPosition(uidB, seatA);

        }
        else {
            SurfaceView viewA = (SurfaceView)seats[seatA].getChildAt(0);
            seats[seatA].removeAllViews();
            SurfaceView viewB = (SurfaceView)seats[seatB].getChildAt(0);
            seats[seatB].removeAllViews();

            seats[seatB].addView(viewA, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
            seats[seatA].addView(viewB, new FrameLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));

            changeSoundPosition(uidA, seatB);
            changeSoundPosition(uidB, seatA);
        }


        switchSeatIds(seatA, seatB);

    }

    private void switchSeatIds(int seatA, int seatB)
    {
        int tmp = seatUIds[seatB];
        seatUIds[seatB] = seatUIds[seatA];
        seatUIds[seatA] = tmp;
    }

    private void updatePosition(int uid, float[] pos)
    {
        RemoteVoicePositionInfo position = new RemoteVoicePositionInfo();
        position.position = pos;
        AgoraManager.getInstance().updateRemotePosition(uid, position);
        //localSpatial.updateRemotePosition(uid, position);

    }

    public void reset()
    {
        //localSpatial = null;
        AgoraManager.getInstance().resetLocalSpatial();
        seatUIds = new int[] {0,0,0,0,0,0,0,0};
    }

    public int[] getSeatIds()
    {
        return _seatIds;
    }

    public void setSeats(VideoLayout[] seats)
    {
        this.seats = seats;
    }

    public void setSelectedSeat(int seatId)
    {
        if(selectedId == -1) {
            selectedId = seatId;
            // hilite view

            Log.i(TAG, "selected seat: "+selectedId);
            view.showLog("selected seatA: "+selectedId, false);
            return;
        }

        if(selectedId == seatId) {

            // same selection
            selectedId = -1;
        }
        else {

            Log.i(TAG, "change seatA: "+selectedId+" seatB: "+seatId);
            changeSeatView(selectedId, seatId);
            view.showLog("change seatA: "+selectedId+" to seatB: "+seatId, false);
            selectedId = -1;
        }

        // reset view
    }
}
