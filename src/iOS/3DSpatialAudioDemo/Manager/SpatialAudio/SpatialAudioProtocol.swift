//
//  SpatialAudioProtocol.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/16.
//

import Foundation
import AgoraRtcKit
import DarkEggKit

protocol SpatialAudioProtocol {
    // properties
    var spatialAudioKit: AgoraBaseSpatialAudioKit? { get }
//    var rtcEngine: AgoraRtcEngineKit { get set }
    var agoraMgr: AgoraManager { get }
    var defaultRecvRange: Float { get }
    
    // Functions
    // Currency
    func updateRecvRange(_ range: Float)
    func updateSelfPosition(_ position: [NSNumber], forward: [NSNumber]?, right: [NSNumber]?, up: [NSNumber]?)
    func updatePlayerPositionInfo(_ playerId: Int, positionInfo: AgoraRemoteVoicePositionInfo)
    
    // Loacl
    func updateRemotePosition(of userId: UInt, positionInfo: AgoraRemoteVoicePositionInfo)
    func clearRemotePositions()
    
    // Cloud
    func enterRoom(_ roomName: String, uid: UInt, byToken token: String?)
}

/// Currency
extension SpatialAudioProtocol {
    var agoraMgr: AgoraManager {
        get {
            return AgoraManager.shared
        }
    }
    
    func updateRecvRange(_ range: Float) {
        self.spatialAudioKit?.setAudioRecvRange(range)
    }
    
    var defaultRecvRange: Float { return 100.0 }
    
    func updateSelfPosition(_ position: [NSNumber], forward: [NSNumber]?, right: [NSNumber]?, up: [NSNumber]?) {
        //Logger.debug("updateSelfPosition: \(position)")
        self.spatialAudioKit?.updateSelfPosition(position,
                                                 axisForward: forward ?? [0, 1, 0],
                                                 axisRight: right ?? [1, 0, 0],
                                                 axisUp: up ?? [0, 0, 1]);
    }
    
    func updatePlayerPositionInfo(_ playerId: Int, positionInfo: AgoraRemoteVoicePositionInfo) {
        self.spatialAudioKit?.updatePlayerPositionInfo(playerId, positionInfo: positionInfo)
    }
}

/// Local kit specific
extension SpatialAudioProtocol {
    func updateRemotePosition(of userId: UInt, positionInfo: AgoraRemoteVoicePositionInfo) {
        guard let localKit = self.spatialAudioKit as? AgoraLocalSpatialAudioKit else {
            return
        }
        
        Logger.debug("update user \(userId) position: \(positionInfo)")
        localKit.updateRemotePosition(userId, positionInfo: positionInfo)
    }
    
    func clearRemotePositions() {
        guard let localKit = self.spatialAudioKit as? AgoraLocalSpatialAudioKit else {
            return
        }
        localKit.clearRemotePositions()
    }
}

/// Cloud kit specific
extension SpatialAudioProtocol {
    func enterRoom(_ roomName: String, uid: UInt, byToken token: String?) {
        guard let cloudKit = self.spatialAudioKit as? AgoraCloudSpatialAudioKit else {
            return
        }
        cloudKit.enterRoom(byToken: token, roomName: roomName, uid: uid)
    }
}
