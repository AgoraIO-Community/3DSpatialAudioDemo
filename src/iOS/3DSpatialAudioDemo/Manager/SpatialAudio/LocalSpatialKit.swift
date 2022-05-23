//
//  AgoraManagerWithLocalKit.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/15.
//

import Foundation
import AgoraRtcKit

class LocalSpatialKit: SpatialAudioProtocol {
    var _spatialKit: AgoraLocalSpatialAudioKit!
    var spatialAudioKit: AgoraBaseSpatialAudioKit? {
        get {
            return _spatialKit
        }
    }
    
    static let shared: LocalSpatialKit = {LocalSpatialKit()}()
    
    init() {
        let config = AgoraLocalSpatialAudioConfig()
        config.rtcEngine = AgoraManager.shared.agoraKit
        _spatialKit = AgoraLocalSpatialAudioKit.sharedLocalSpatialAudio(with: config)
        //_spatialKit.enableMic(true)
        //_spatialKit.e
    }
}
