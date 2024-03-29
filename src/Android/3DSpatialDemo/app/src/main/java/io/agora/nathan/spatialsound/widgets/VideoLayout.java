package io.agora.nathan.spatialsound.widgets;

import android.content.Context;
import android.graphics.Color;
import android.util.AttributeSet;
import android.view.SurfaceView;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import io.agora.nathan.spatialsound.common.StatisticsInfo;
import io.agora.rtc2.IRtcEngineEventHandler;

public class VideoLayout extends FrameLayout {

    private final StatisticsInfo statisticsInfo = new StatisticsInfo();
    private TextView reportTextView;
    private int reportUid = -1;
    private int seatId = -1;

    public VideoLayout(@NonNull Context context) {
        super(context);
    }

    public VideoLayout(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);

    }

    public VideoLayout(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
    }

    @Override
    public void addView(View child, int index, ViewGroup.LayoutParams params) {
        super.addView(child, index, params);

        if (child instanceof SurfaceView || child instanceof TextureView) {
            reportTextView = new TextView(getContext());
            reportTextView.addOnAttachStateChangeListener(new OnAttachStateChangeListener() {
                @Override
                public void onViewAttachedToWindow(View v) {

                }

                @Override
                public void onViewDetachedFromWindow(View v) {
                    reportTextView.removeOnAttachStateChangeListener(this);
                    reportTextView = null;
                }
            });
            reportTextView.setTextColor(Color.parseColor("#000000"));
            LayoutParams reportParams = new LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT);
            reportParams.topMargin = reportParams.leftMargin = 16;
            addView(reportTextView, reportParams);
        }
    }

    public void setVideoUid(int uid) {
        this.reportUid = uid;
    }

    public int getVideoUid() {
        return reportUid;
    }

    public void setSeatId(int seatId) { this.seatId = seatId; }

    public int getSeatId() { return seatId; }

    public void setLocalAudioStats(IRtcEngineEventHandler.LocalAudioStats stats){
        statisticsInfo.setLocalAudioStats(stats);
        setReportText(statisticsInfo.getLocalVideoStats());
    }

    public void setLocalVideoStats(IRtcEngineEventHandler.LocalVideoStats stats){
        if (stats.uid != reportUid) {
            return;
        }
        statisticsInfo.setLocalVideoStats(stats);
        setReportText(statisticsInfo.getLocalVideoStats());
    }

    public void setRemoteAudioStats(IRtcEngineEventHandler.RemoteAudioStats stats){
        if (stats.uid != reportUid) {
            return;
        }
        statisticsInfo.setRemoteAudioStats(stats);
        setReportText(statisticsInfo.getRemoteVideoStats());
    }

    public void setRemoteVideoStats(IRtcEngineEventHandler.RemoteVideoStats stats){
        if (stats.uid != reportUid) {
            return;
        }
        statisticsInfo.setRemoteVideoStats(stats);
        setReportText(statisticsInfo.getRemoteVideoStats());
    }


    private void setReportText(String reportText) {
        if(reportTextView != null){
            reportTextView.post(new Runnable() {
                @Override
                public void run() {
                    reportTextView.setText(reportText);
                }
            });
        }
    }

}

