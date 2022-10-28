package io.agora.nathan.spatialsound.common;

import android.util.Log;

import io.agora.spatialaudio.ILocalSpatialAudioEngine;
import io.agora.spatialaudio.RemoteVoicePositionInfo;

public class PositionManager {

    private static final String TAG = "PositionManager";
    private static volatile PositionManager sInstance = null;

    // default distance
    // radius = 2.5m
    private static final float axial       = (float) 1.2;
    private static final float axialMinus  = (float) -1.2;
    private static final float slant       = (float) 0.722;
    private static final float slantMinus  = (float) -0.722;

    private ILocalSpatialAudioEngine localSpatial;

    private static int[] seats = new int[] {0,0,0,0,0,0,0,0};

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

    public void setLocalSpatialAudioEngine(ILocalSpatialAudioEngine engine) {
        localSpatial = engine;
    }

    public boolean takeSeat(int uid, int seatIndex) {
        if(seats[seatIndex] > 0) {
            return false;
        }
        seats[seatIndex] = uid;
        changeSeat(uid, seatIndex);
        return true;
    }

    public void leaveSeat(int uid) {
        for(int i=0;i<seats.length;i++)
        {
            if(seats[i] == uid)
            {
                seats[i] = 0;
            }
        }
    }

    public int nextEmptySeat() {
        for(int i=0;i<seats.length;i++)
        {
            if(seats[i] == 0)
            {
                return i;
            }
        }
        return -1;
    }

    public void changeSeat(int uid, int seatIndex) {
        Log.i(TAG,"select seat "+seatIndex+" for user "+uid);
        float[] pos = new float[3];
        switch(seatIndex) {
            case 0:
                pos = new float[]{slantMinus, slant, slant};
                break;
            case 1:
                pos = new float[]{0, 0, axial};
                break;
            case 2:
                pos = new float[]{slant, slant, slant};
                break;
            case 3:
                pos = new float[]{axialMinus, 0, 0};
                break;
            case 4:
                pos = new float[]{axial, 0, 0};
                break;
            case 5:
                pos = new float[]{slantMinus, slant, slantMinus};
                break;
            case 6:
                pos = new float[]{0, 0, axialMinus};
                break;
            case 7:
                pos = new float[]{slant, slant, slantMinus};
                break;
            default: // default, not on stage, from back
                pos = new float[]{0, axialMinus, 0};
                break;
        }

        updatePosition(uid, pos);
    }

    private void updatePosition(int uid, float[] pos)
    {
        RemoteVoicePositionInfo postion = new RemoteVoicePositionInfo();
        postion.position = pos;
        localSpatial.updateRemotePosition(uid, postion);
    }

    public void reset()
    {
        localSpatial = null;
        seats = new int[] {0,0,0,0,0,0,0,0};
    }

}
