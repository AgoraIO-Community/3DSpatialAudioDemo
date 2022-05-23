//
//  AgoraManager.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/10/14.
//

import Foundation
import AgoraRtcKit
import DarkEggKit
import PromiseKit

///
extension AgoraSaeConnectionState : CustomStringConvertible {
    public var description: String {
        switch self {
        case .connecting:
            return ".Connecting"
        case .disconnected:
            return ".Disconnected"
        default:
            return ".Connected"
        }
    }
}

///
extension AgoraSaeConnectionChangedReason : CustomStringConvertible {
    public var description: String {
        switch self {
        case .aborted:
            return ".Aborted"
        case .connecting:
            return ".Connecting"
        case .createRoomFail:
            return ".CreateRoomFail"
        case .rtmDisconnect:
            return ".RtmDisconnect"
        default:
            return ".Default"
        }
    }
}

@objc protocol AgoraManagerDelegate: AnyObject {
    func agoraMgr(_ mgr: AgoraManager, userJoined uid: UInt)
    func agoraMgr(_ mgr: AgoraManager, userLeaved uid: UInt)
    // Media player
    @objc optional func agoraManager(_ mgr: AgoraManager, mediaPlayer: AgoraRtcMediaPlayerProtocol, loadCompleted: Bool)
}

class AgoraManager: NSObject {
    
    //private var appId = "c7ac671989ee4309b0dbc3d0a473ed57"
    var recvRange: Float = 100.0
    var audioModel: AgoraAudioRangeMode = .world
    var soundEffect: SoundEffect = .enable
    
    weak var delegate: AgoraManagerDelegate?
    
    let teamId = 903
    let Sound3DRadius: UInt = 10
    let RecvRangeRadius: UInt = 100
    
    var agoraKit: AgoraRtcEngineKit!
    var cloudSpatialKit: CloudSpatialKit!   // = CloudSpatialKit.shared
    var localSpatialKit: LocalSpatialKit!   // = LocalSpatialKit.shared
    
    var selfUid: UInt = 0
    var users: [UInt] = []
    var mediaPlayers: [Int: AgoraRtcMediaPlayerProtocol] = [:]
    
    var containerView: UIView = UIView(frame: UIScreen.main.bounds)
    
    var enableVideo: Bool = false {
        didSet {
            if enableVideo {
                self.agoraKit.enableVideo()
            }
            else {
                self.agoraKit.disableVideo()
            }
        }
    }
    
    static let shared: AgoraManager = { AgoraManager()}()
    
    override init() {
        super.init()
        let appId = AppConfig.shared.agora.appId
        self.agoraKit = AgoraRtcEngineKit.sharedEngine(withAppId: appId, delegate: self)
        //agoraKit.delegate = self
        agoraKit.setChannelProfile(.liveBroadcasting)
        //agoraKit.setClientRole(.audience)
        agoraKit.setAudioProfile(.musicHighQualityStereo, scenario: .gameStreaming)
        agoraKit.enableAudio()
        agoraKit.enableVideo()
        agoraKit.enableLocalVideo(false)
        agoraKit.enableLocalAudio(true)
        agoraKit.muteLocalAudioStream(false)
        //agoraKit.muteRemoteAudioStream(false)
        //agoraKit.setDefaultAudioRouteToSpeakerphone(true)
        agoraKit.delegate = self
        agoraKit.adjustRecordingSignalVolume(100)
        agoraKit.adjustAudioMixingPublishVolume(0)
    }
    
    //
    func enableSpatialAudio() {
        self.localSpatialKit = LocalSpatialKit.shared
        self.cloudSpatialKit = CloudSpatialKit.shared
        // enable spatial audio
        agoraKit.enableSpatialAudio(true)
    }
    
    func join(channel: String, asHost: Bool, completion: ((Bool, UInt) -> Void)?) {
        self.agoraKit.setClientRole(asHost ? .broadcaster : .audience)
        
        agoraKit.setParameters("{\"rtc.audio.force_bluetooth_a2dp\": false}")
//        self.agoraKit.joinChannel(byToken: nil, channelId: channel, uid: 0, mediaOptions: option)  { [weak self] channel, uid, elapsed in
        self.agoraKit.joinChannel(byToken: nil, channelId: channel, info: nil, uid: 0) { [weak self] channel, uid, elapsed in
            print("Join \(channel) with uid \(uid) elapsed \(elapsed)ms")
            self?.selfUid = uid
            // set video preview view
            let videoCanvas = AgoraRtcVideoCanvas()
            videoCanvas.sourceType = .camera
            videoCanvas.view = self?.containerView
            videoCanvas.renderMode = .hidden
            self?.agoraKit.setupLocalVideo(videoCanvas)
            completion?(true, uid)
        }
    }
    
    func joinPromise(channel: String, asHost: Bool = false) -> Promise<UInt> {
        self.agoraKit.setClientRole(asHost ? .broadcaster : .audience)
        
        return Promise { seal in
            let ret = self.agoraKit.joinChannel(byToken: nil, channelId: channel, info: nil, uid: 0) { [weak self] channel, uid, elapsed in
                print("Join \(channel) with uid \(uid) elapsed \(elapsed)ms")
                self?.selfUid = uid
                // set video preview view
                let videoCanvas = AgoraRtcVideoCanvas()
                videoCanvas.sourceType = .camera
                videoCanvas.view = self?.containerView
                videoCanvas.renderMode = .hidden
                self?.agoraKit.setupLocalVideo(videoCanvas)
                Logger.debug("enter cloud spatial audio room")
                self?.cloudSpatialKit.enterRoom(channel+"sa", uid: uid, byToken: nil)
                seal.fulfill(uid)
            }
            
            if ret != 0 {
                seal.reject(DemoError.rtcError(Int(ret)))
            }
            else {
                // maybe will not called
                //seal.fulfill(UInt(0))
            }
        }
    }
    
    func leave() {
        // clear position
        SpatialAudioMode.local.spatialKit.clearRemotePositions()
        SpatialAudioMode.cloud.spatialKit.clearRemotePositions()
        self.mediaPlayers.values.forEach { p in
            p.stop()
            self.agoraKit.destroyMediaPlayer(p)
        }
        self.mediaPlayers.removeAll()
        // leave channel
        self.agoraKit.leaveChannel { state in
            // leave gem room
            Logger.debug("leaveChannel")
        }
    }
}

// MARK: -
extension AgoraManager {
    func switchVideo(_ videoOn: Bool) {
        self.agoraKit.enableLocalVideo(videoOn)
    }
    
    func setLocalVideoPreview(in view: UIView) {
        guard !view.subviews.contains(self.containerView) else {
            return
        }
        self.containerView.frame = view.frame
        view.addSubview(self.containerView)
        self.agoraKit.startPreview()
    }
    
    func removeLocalVideoPreview() {
        self.containerView.removeFromSuperview()
        self.agoraKit.stopPreview()
    }
    
    // remote
    func setRemoteVideoView(_ view: UIView, forUser uid: UInt) {
        let videoCanvas = AgoraRtcVideoCanvas()
        videoCanvas.uid = uid
        videoCanvas.view = view
        videoCanvas.renderMode = .hidden
        self.agoraKit.setupRemoteVideo(videoCanvas)
    }
}

// MARK: - Media Player Delegate
extension AgoraManager: AgoraRtcMediaPlayerDelegate {
    func createMediaPlayer(forFile filePath: String, at position: [NSNumber], startPosition: Int = 0, mode: SpatialAudioMode = .local, completion: ((Int) -> Void)?) {
        let player = agoraKit.createMediaPlayer(with: self)
        if let playerId = player?.getMediaPlayerId(), playerId >= 0 {
            player?.open(filePath, startPos: startPosition)
            let pos = AgoraRemoteVoicePositionInfo()
            let param = AgoraSpatialAudioParams()
            param.enable_blur = AgoraRtcBoolOptional.of(true)
            pos.position = position
            mode.spatialKit.updatePlayerPositionInfo(Int(playerId), positionInfo: pos)
            
            player?.setLoopCount(-1)
            if let p = player {
                self.mediaPlayers[Int(playerId)] = p
            }
            completion?(Int(playerId))
            //print(player?.getPlayoutVolume())
            print("publish volume: \(player?.getPublishSignalVolume() ?? -1)")
            print("players count: \(self.mediaPlayers.count)")
            //player?.play()
        }
    }
    
    func getPlayer(by playerId: Int) -> AgoraRtcMediaPlayerProtocol? {
        let player = self.agoraKit.getMediaPlayer(Int32(playerId))
        return player
    }
    
    func changePlayer(_ playerId: Int, to position: [NSNumber], mode: SpatialAudioMode = .local) {
        let pos = AgoraRemoteVoicePositionInfo()
        pos.position = position
        mode.spatialKit.updatePlayerPositionInfo(playerId, positionInfo: pos)
    }
    
    func removePlayer(id: Int) {
        if let player = self.mediaPlayers[id] {
            player.stop()
            self.mediaPlayers.removeValue(forKey: id)
            self.agoraKit.destroyMediaPlayer(player)
        }
    }
    
    func publishMediaPlayer(_ on: Bool, playerId: Int) {
        let mediaOption = AgoraRtcChannelMediaOptions()
        if on, let _ = self.mediaPlayers[playerId] {
            mediaOption.publishMediaPlayerId = AgoraRtcIntOptional.of(Int32(playerId))
            mediaOption.publishMediaPlayerAudioTrack = AgoraRtcBoolOptional.of(true)
            let a = self.agoraKit.updateChannel(with: mediaOption)
            print("update media option: \(a)")
        }
        else {
            mediaOption.publishMediaPlayerAudioTrack = AgoraRtcBoolOptional.of(false)
            self.agoraKit.updateChannel(with: mediaOption)
        }
    }
    
    
    // Delegate functions
    func agoraRtcMediaPlayer(_ playerKit: AgoraRtcMediaPlayerProtocol, didChangedTo state: AgoraMediaPlayerState, error: AgoraMediaPlayerError) {
        //
        print("state: \(state.rawValue), error: \(error.rawValue)")
        if state == .openCompleted {
            // loading completed, start player
            playerKit.play()
        }
    }
}

// MARK: - 3D
extension AgoraManager {
    /// Update audio mode
    /// Paramater:
    ///     type: AgoraRangeAudioMode
    private func updateAudioMode(_ type: AgoraAudioRangeMode) {
//        self.localSpatialKit.setRangeAudioMode(type)
    }
    
    /// Update spatializer
    /// Paramters:
    ///     type: SoundEffect
    private func updateSpatializer(_ type: SoundEffect) {
//        if type == .disable {
//            self.localSpatialKit.enableSpatializer(false, applyToTeam: false)
//        } else {
//            let applyToTeam = type == .applyToTeam
//            self.localSpatialKit.enableSpatializer(true, applyToTeam: applyToTeam)
//        }
    }
}

// MARK: - Audio mixing functions
extension AgoraManager {
    /// Start audio mixing
    func startAudioMixing(soundType: String, completion: ((Bool) -> Void)?) {
        print("Start audio mixing: \(soundType)")
        agoraKit.adjustRecordingSignalVolume(0)
        agoraKit.adjustAudioMixingPublishVolume(100)
        agoraKit.stopAudioMixing()
        if let sound = Sound(rawValue: soundType), let filePath = sound.filePath {
            let ret = self.agoraKit.startAudioMixing(filePath, loopback: false, replace: false, cycle: -1)
//             let ret = self.agoraKit.startAudioMixing(filePath, loopback: false, replace: false, cycle: -1, startPos: 0)
            completion?((ret == 0))
        }
    }
    
    /// Stop audio mixing
    func stopAudioMixing() {
        print("Stop audio mixing")
        agoraKit.adjustRecordingSignalVolume(100)
        agoraKit.adjustAudioMixingPublishVolume(0)
        agoraKit.stopAudioMixing()
    }
}

// MARK: - Spatial Audio
extension AgoraManager {
    /// Update self position
    /// - Parameters:
    ///   - position: [x,y,z]
    ///   - forward: [fx,fy,fz]
    ///   - right: [rx, ry, rz]
    ///   - up: [ux, uy, uz]
    ///   - mode: Spatial Audio Mode (local or cloud), default is local
    func updateSelfPosition(position: [NSNumber], forward: [NSNumber], right: [NSNumber], up: [NSNumber], mode: SpatialAudioMode = .local) {
        mode.spatialKit.updateSelfPosition(position, forward: forward, right: right, up: up)
    }
    
    /// Update position
    /// - Parameters:
    ///   - userId: user id(UInt)
    ///   - position: [x, y, z]
    ///   - mode: Spatial Audio Mode (local or cloud)
    func updatePosition(of userId: UInt, position: [NSNumber], mode: SpatialAudioMode = .local) {
        print("update user \(userId) position: \(position)")
        let posInfo = AgoraRemoteVoicePositionInfo()
        posInfo.position = position
        mode.spatialKit.updateRemotePosition(of: userId, positionInfo: posInfo)
    }
    
//    func updatePlayerPosition(of playerId: Int, position: [NSNumber], mode: SpatialAudioMode = .local) {
//        let pos = AgoraRemoteVoicePositionInfo()
//        let param = AgoraSpatialAudioParams()
//        param.enable_blur = AgoraRtcBoolOptional.of(true)
//        pos.position = position
//        mode.spatialKit.updatePlayerPositionInfo(Int(playerId), positionInfo: pos)
//    }
}

// MARK: - AgoraRtcEngineDelegate
extension AgoraManager: AgoraRtcEngineDelegate {
    func setHostPosition(_ uid: UInt, position: [NSNumber]) {
        print("setHostPosition")
        self.updatePosition(of: uid, position: position)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didMicrophoneEnabled enabled: Bool) {
        print("didMicrophoneEnabled: \(enabled)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinedOfUid uid: UInt, elapsed: Int) {
        print("user \(uid) join")
        let param = AgoraSpatialAudioParams()
        self.agoraKit.setRemoteUserSpatialAudioParams(uid, params: param)
        self.delegate?.agoraMgr(self, userJoined: uid)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOfflineOfUid uid: UInt, reason: AgoraUserOfflineReason) {
        print("user \(uid) leave")
        self.delegate?.agoraMgr(self, userLeaved: uid)
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didJoinChannel channel: String, withUid uid: UInt, elapsed: Int) {
        print("Join \(channel) with uid \(uid) elapsed \(elapsed)ms")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurError errorCode: AgoraErrorCode) {
        print("errorCode \(errorCode.rawValue)")
    }
    
    func rtcEngine(_ engine: AgoraRtcEngineKit, didOccurWarning warningCode: AgoraWarningCode) {
        print("warningCode \(warningCode.rawValue)")
    }
}
