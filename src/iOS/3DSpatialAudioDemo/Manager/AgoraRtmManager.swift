//
//  ChatManager.swift
//  Radio3DAudioSample
//
//  Created by Yuhua Hu on 2022/02/28.
//

import AgoraRtmKit
import DarkEggKit
import Foundation
import PromiseKit

@objc protocol AgoraRtmManagerDelegate: AnyObject {
    @objc optional func rtmMgr(_ mgr: AgoraRtmManager, onRecivedText text: String, fromUser uid: UInt)
    @objc optional func rtmMgr(_ mgr: AgoraRtmManager, onRecivedData data: NSData, fromUser uid: UInt)
    @objc optional func rtmMgr(_ mgr: AgoraRtmManager, onReciveSeat seatIndex: Int, fromUser uid: UInt)
}

class AgoraRtmManager: NSObject {
    
    var rtmKit: AgoraRtmKit!
    static let shared: AgoraRtmManager = { AgoraRtmManager()}()
    
    var currentChannelId: String?
    var rtmChannel: AgoraRtmChannel?
    
    var delegate: AgoraRtmManagerDelegate?
    
    override init() {
        super.init()
        self.rtmKit = AgoraRtmKit(appId: AppConfig.shared.agora.appId, delegate: self)
    }
}

extension AgoraRtmManager {
    func login(_ userId: String) {
        rtmKit.login(byToken: nil, user: userId) { error in
            Logger.debug(error.rawValue)
        }
    }
    
    func loginPromise(_ userId: String) -> Promise<AgoraRtmLoginErrorCode> {
        return Promise { seal in
            rtmKit.login(byToken: nil, user: userId) { error in
                Logger.debug(error.rawValue)
                if error == AgoraRtmLoginErrorCode.ok {
                    seal.fulfill(error)
                }
                else {
                    seal.reject(DemoError.rtmLoginError(error))
                }
            }
        }
    }
    
    func joinChannel(_ channelId: String) {
        // destory old one
        if let cChannelId = self.currentChannelId, cChannelId != channelId {
            self.rtmKit.destroyChannel(withId: cChannelId)
        }
        self.currentChannelId = channelId
        self.rtmChannel = self.rtmKit.createChannel(withId: channelId, delegate: self)
    }
    
    func joinChannelPromise(_ channelId: String) -> Promise<AgoraRtmChannel> {
        return Promise { seal in
            if let cChannelId = self.currentChannelId, cChannelId != channelId {
                self.rtmKit.destroyChannel(withId: cChannelId)
            }
            self.currentChannelId = channelId
            if let rtmChannel = self.rtmKit.createChannel(withId: channelId, delegate: self) {
                rtmChannel.join { error in
                    if error == .channelErrorOk {
                        rtmChannel.channelDelegate = self
                        self.rtmChannel = rtmChannel
                        seal.fulfill(rtmChannel)
                    }
                    else {
                        seal.reject(DemoError.rtm.joinChannelFaied)
                    }
                }
            }
            else {
                seal.reject(DemoError.rtm.createChannelFailed)
            }
        }
    }
    
    func sendMessage(_ text: String) {
        let msg = AgoraRtmMessage(text: text)
        self.rtmChannel?.send(msg, sendMessageOptions: AgoraRtmSendMessageOptions(), completion: { errorCode in
            //
            Logger.debug(errorCode.rawValue)
        })
    }
    
    func sendUser(_ uid: UInt, seatIndex: Int) {
        let msg = SeatMessage()
        msg.type = MessageType.seat.rawValue
        msg.uid = uid
        msg.seatIndex = seatIndex
        if let data = try? JSONEncoder().encode(msg) {
//        if let data = try? NSKeyedArchiver.archivedData(withRootObject: msg, requiringSecureCoding: false) {
            let rawMsg = AgoraRtmRawMessage(rawData: data, description: "User \(uid) take seat \(seatIndex)")
            self.rtmChannel?.send(rawMsg, sendMessageOptions: AgoraRtmSendMessageOptions(), completion: { errorCode in
                //
                Logger.debug("Send seat message: \(errorCode.rawValue)")
            })
        }
    }
    
    func leave() {
        self.rtmChannel?.leave(completion: { [weak self] errorCode in
            self?.currentChannelId = nil
            self?.rtmKit.logout { errorCode in
                //
                Logger.debug("Leave rtm channel.")
            }
        })
    }
}

extension AgoraRtmManager: AgoraRtmDelegate {
    
}

extension AgoraRtmManager: AgoraRtmChannelDelegate {
    func channel(_ channel: AgoraRtmChannel, memberJoined member: AgoraRtmMember) {
        Logger.debug("Channel \(member.channelId), \(member.userId) joined")
    }
    
    func channel(_ channel: AgoraRtmChannel, messageReceived message: AgoraRtmMessage, from member: AgoraRtmMember) {
        Logger.debug()
        switch message.type {
        case .text:
            Logger.debug(message.text)
//            self.delegate?.rtmMgr?(self, onRecivedText: message.text, fromUser: message.ui)
            break
        case .raw:
            if let d = message as? AgoraRtmRawMessage {
                Logger.debug(d.rawData)
                if let msg = try? JSONDecoder().decode(SeatMessage.self, from: d.rawData) {
//                    Logger.debug("Message type is \(message.type)")
//                    Logger.debug("User \(msg.uid) change the seat to \(msg.seatIndex)")
                    self.delegate?.rtmMgr?(self, onReciveSeat: msg.seatIndex!, fromUser: msg.uid!)
                }
            }
            break
        default:
            // do nothing
            break
        }
    }
    
    func channel(_ channel: AgoraRtmChannel, memberLeft member: AgoraRtmMember) {
        //
        Logger.debug("\(member.userId) leave channel \(member.channelId)")
    }
    
    func channel(_ channel: AgoraRtmChannel, memberCount count: Int32) {
        Logger.debug("\(count)")
        if count <= 0 {
            Logger.debug("No one in channel. \(channel)")
        }
    }
}
