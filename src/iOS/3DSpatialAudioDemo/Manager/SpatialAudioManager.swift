//
//  SpatialAudioManager.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/09.
//

import AgoraRtcKit

class SpatialAudioManager: NSObject {
    let agoraManager: AgoraManager = AgoraManager.shared
    var recvRange: Float = 100.0
    var mode: SpatialAudioMode = .local
    var spatialAudioKit: AgoraBaseSpatialAudioKit?
    
    static let local: SpatialAudioManager = { SpatialAudioManager(.local) }()
    static let cloud: SpatialAudioManager = { SpatialAudioManager(.cloud) }()
    
    init(_ mode: SpatialAudioMode) {
        self.mode = mode
        super.init()
        
        switch self.mode {
        case .local:
            let config: AgoraLocalSpatialAudioConfig = AgoraLocalSpatialAudioConfig()
            config.rtcEngine = self.agoraManager.agoraKit
            self.spatialAudioKit = AgoraLocalSpatialAudioKit.sharedLocalSpatialAudio(with: config) //AgoraCloudSpatialAudioKit.sharedCloudSpatialAudio(with: config, delegate: self)
            self.spatialAudioKit?.setAudioRecvRange(self.recvRange)
            //self.spatialAudioKit?.enableMic(true)
            break
        case .cloud:
            let config: AgoraCloudSpatialAudioConfig = AgoraCloudSpatialAudioConfig()
            config.rtcEngine = self.agoraManager.agoraKit
            self.spatialAudioKit = AgoraCloudSpatialAudioKit.sharedCloudSpatialAudio(with: config, delegate: self)//AgoraLocalSpatialAudioKit.sharedLocalSpatialAudio(withRtcEngine: self.agoraKit) //AgoraCloudSpatialAudioKit.sharedCloudSpatialAudio(with: config, delegate: self)
            self.spatialAudioKit?.setAudioRecvRange(self.recvRange)
            //self.spatialAudioKit?.enableMic(true)
        }
    }
}

extension SpatialAudioManager {
    func updateSelfPosition(position: [Float]) {
        // debug
    }
}

extension SpatialAudioManager: AgoraCloudSpatialAudioDelegate {
    func csaEngineTokenWillExpire(_ engine: AgoraCloudSpatialAudioKit) {
        //
    }
    
    func csaEngine(_ engine: AgoraCloudSpatialAudioKit, connectionDidChangedTo state: AgoraSaeConnectionState, with reason: AgoraSaeConnectionChangedReason) {
        //
    }
    
    func csaEngine(_ engine: AgoraCloudSpatialAudioKit, teammateJoined userId: UInt) {
        //
    }
    
    func csaEngine(_ engine: AgoraCloudSpatialAudioKit, teammateLeft userId: UInt) {
        //
    }
}
