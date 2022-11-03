package io.agora.nathan.spatialsound;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;

import androidx.annotation.NonNull;
import androidx.navigation.fragment.NavHostFragment;

import io.agora.nathan.spatialsound.R;
import io.agora.nathan.spatialsound.common.AgoraManager;
import io.agora.nathan.spatialsound.common.BaseFragment;
import io.agora.nathan.spatialsound.databinding.FragmentHomeBinding;
import io.agora.nathan.spatialsound.fragments.DemoSpatialSound;
import io.agora.rtc2.RtcEngine;

public class HomeFragment extends BaseFragment {
    private static final String TAG = DemoSpatialSound.class.getSimpleName();
    private FragmentHomeBinding binding;
    private EditText channel;
    private Button join;

    @Override
    public View onCreateView(
            LayoutInflater inflater, ViewGroup container,
            Bundle savedInstanceState
    ) {

        binding = FragmentHomeBinding.inflate(inflater, container, false);
        return binding.getRoot();

    }

    public void onViewCreated(@NonNull View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        channel = view.findViewById(R.id.et_channel);
        join = (Button)view.findViewById(R.id.btn_join);

        if(AgoraManager.getInstance().isJoined()) {
            binding.btnDemo2.setEnabled(true);
            join.setText(R.string.leave);
            channel.setEnabled(false);
        }
        else {
            join.setText(R.string.join);
            channel.setEnabled(true);
            binding.btnDemo2.setEnabled(false);

        }
        join.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if(!AgoraManager.getInstance().isJoined()) {
                    int areaCode = ((MainActivity)getActivity()).getGlobalSettings().getAreaCode();

                    String channelId = channel.getText().toString();
                    AgoraManager.getInstance().createEngine(getContext(), binding.etAppid.getText().toString(), areaCode);
                    AgoraManager.getInstance().joinChannel(channelId);
                    Log.i(TAG, "joidChannel:"+ channelId);

                    join.setText(R.string.leave);
                    channel.setEnabled(false);
                    binding.btnDemo2.setEnabled(true);
                }
                else {
                    AgoraManager.getInstance().leaveChannel();
                    join.setText(R.string.join);
                    channel.setEnabled(true);
                    binding.btnDemo2.setEnabled(false);
                }
            }
        });

        binding.demo1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                NavHostFragment.findNavController(HomeFragment.this)
                        .navigate(R.id.action_homeFragment_to_demoSpatialSound);
            }
        });

        binding.demo2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                NavHostFragment.findNavController(HomeFragment.this)
                        .navigate(R.id.action_homeFragment_to_remoteSpatialSound);
            }
        });

        binding.btnDemo1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                NavHostFragment.findNavController(HomeFragment.this)
                        .navigate(R.id.action_homeFragment_to_demoSpatialSound);
            }
        });

        binding.btnDemo2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                NavHostFragment.findNavController(HomeFragment.this)
                        .navigate(R.id.action_homeFragment_to_remoteSpatialSound);
            }
        });
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        handler.removeCallbacksAndMessages(null);
        handler.post(RtcEngine::destroy);
        AgoraManager.getInstance().destroy();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }

}