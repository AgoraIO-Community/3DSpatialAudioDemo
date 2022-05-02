//
//  SpatialAudioCommon.swift
//  Radio3DAudioSample
//
//  Created by Yuhua Hu on 2022/02/21.
//

import Foundation
import AgoraRtcKit

@objc protocol SpatialAudioKitDelegate: AnyObject {
    func spatialKit(_ mgr: SpatialAudioCommon, userJoined uid: UInt)
    func spatialKit(_ mgr: SpatialAudioCommon, userLeaved uid: UInt)
    // Media player
    func spatialKit(_ mgr: SpatialAudioCommon, mediaPlayer: AgoraRtcMediaPlayerProtocol, loadCompleted: Bool)
}

class SpatialAudioCommon: NSObject, SpatialAudioProtocol, AgoraRtcManagerProtocol {
    var agoraKit: AgoraRtcEngineKit!
    weak var delegate: SpatialAudioKitDelegate?
    
    var spatialAudioKit: AgoraBaseSpatialAudioKit {
        get {
            let spatialKit = AgoraLocalSpatialAudioKit.sharedLocalSpatialAudio(withRtcEngine: self.agoraKit)
            spatialKit.enableMic(true)
            return spatialKit
        }
    }
    
    static let shared: SpatialAudioCommon = {SpatialAudioCommon()}()
    
    override init() {
        super.init()
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: self.appId, delegate: self)
        agoraKit.setChannelProfile(.liveBroadcasting)
        //agoraKit.setClientRole(.audience)
        agoraKit.setAudioProfile(.musicHighQualityStereo, scenario: .gameStreaming)
        agoraKit.enableAudio()
        agoraKit.enableVideo()
        agoraKit.enableLocalVideo(false)
        agoraKit.enableLocalAudio(true)
        agoraKit.muteLocalAudioStream(false)
        //agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        agoraKit.delegate = self
        agoraKit.adjustRecordingSignalVolume(100)
        agoraKit.adjustAudioMixingPublishVolume(0)
        
        // enable spatial audio
        agoraKit.enableSpatialAudio(true)
    }
    
    func join(channel: String, asHost: Bool, completion: ((Bool, UInt) -> Void)?) {
        self.agoraKit.setClientRole(asHost ? .broadcaster : .audience)
        
        //self.spatialKit = LocalSpatialKit()
        
//        self.agoraKit.joinChannel(byToken: nil, channelId: channel, uid: 0, mediaOptions: option)  { [weak self] channel, uid, elapsed in
        self.agoraKit.joinChannel(byToken: nil, channelId: channel, info: nil, uid: 0) { [weak self] channel, uid, elapsed in
            print("Join \(channel) with uid \(uid) elapsed \(elapsed)ms")
            // set video preview view
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.sourceType = .camera
            videoCanvas.view = self?.containerView
            videoCanvas.renderMode = .hidden
            self?.agoraKit.setupLocalVideo(videoCanvas)
            
            //self?.updateRecvRange(self?.recvRange ?? 100.0)
            
            completion?(true, uid)
        }
    }
    
    func leave() {
        // clear position
        //self.spatialKit.clearRemotePositions()
        self.mediaPlayers.values.forEach { p in
            p.stop()
            self.agoraKit.destroyMediaPlayer(p)
        }
        //self.mediaPlayers.removeAll()
        // leave channel
        self.agoraKit.leaveChannel { state in
            // leave gem room
            print("leaveChannel")
        }
    }
}
