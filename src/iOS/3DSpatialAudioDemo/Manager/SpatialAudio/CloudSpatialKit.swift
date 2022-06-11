//
//  AgoraManagerWithCloudKit.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/15.
//

import Foundation
import AgoraRtcKit
import DarkEggKit

class CloudSpatialKit: NSObject, SpatialAudioProtocol {
    var _spatialKit: AgoraCloudSpatialAudioKit!
    var spatialAudioKit: AgoraBaseSpatialAudioKit? {
        get {
            return _spatialKit
        }
    }
    
    static let shared: CloudSpatialKit = {CloudSpatialKit()}()
    
    override init() {
        super.init()
        let config = AgoraCloudSpatialAudioConfig()
        config.rtcEngine = AgoraManager.shared.agoraKit
        config.appId = AppConfig.shared.agora.appId
        _spatialKit = AgoraCloudSpatialAudioKit.sharedCloudSpatialAudio(with: config, delegate: self)
        //_spatialKit.enableMic(true)
        //_spatialKit.enableSpeaker(true)
        _spatialKit.enableSpatializer(true, applyToTeam: false)
    }
}

extension CloudSpatialKit: AgoraCloudSpatialAudioDelegate {
    func csaEngineTokenWillExpire(_ engine: AgoraCloudSpatialAudioKit) {
        // renew the token
    }
    
    func csaEngine(_ engine: AgoraCloudSpatialAudioKit, connectionDidChangedTo state: AgoraSaeConnectionState, with reason: AgoraSaeConnectionChangedReason) {
        //
        Logger.debug("\(state.description), reason: \(reason)")
    }
    
    func csaEngine(_ engine: AgoraCloudSpatialAudioKit, teammateJoined userId: UInt) {
        //
        Logger.debug()
    }
    
    func csaEngine(_ engine: AgoraCloudSpatialAudioKit, teammateLeft userId: UInt) {
        //
        Logger.debug()
    }
}

extension CloudSpatialKit {
    func sendSelfPosition() {
        
    }
}
