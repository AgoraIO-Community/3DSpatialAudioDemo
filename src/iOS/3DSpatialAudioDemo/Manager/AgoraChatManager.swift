//
//  AgoraChatManager.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/25.
//

import Foundation
import HyphenateChat
import DarkEggKit

class AgoraChatManager: NSObject {
    let emClient = EMClient.shared()
}

private extension AgoraChatManager {
    func register(userName: String, password: String) {
        emClient?.register(withUsername: userName, password: password, completion: { user, error in
            guard let err = error else {
                Logger.debug("register \(userName) success")
                return
            }
            Logger.debug("register \(userName) failure, error: \(err)")
        })
        
        //
    }
    
    func login(userName: String, password: String) {
        emClient?.login(withUsername: userName, password: password, completion: { user, error in
            if let err = error {
                Logger.debug("\(userName) login failure, error: \(err)")
                return
            }
            //
            Logger.debug("\(userName) login success")
        })
    }
    
    func createGroup(_ groupName: String) {
        let groupOptions = EMGroupOptions()
        groupOptions.style = EMGroupStylePublicOpenJoin
        groupOptions.isInviteNeedConfirm = false
        groupOptions.maxUsers = 32
        
        emClient?.groupManager.createGroup(withSubject: groupName, description: "", invitees: [], message: "", setting: groupOptions, completion: { group, error in
            //
            group?.groupId
        })
    }
    
    func joinGroup(_ groupId: String) {
        emClient?.groupManager.joinPublicGroup(groupId, completion: { group, error in
            //
        })
    }
    
    func joinRoom(_ roomId: String, userName: String) {
        emClient?.register(withUsername: userName, password: "", completion: { userName, error in
            //
        })
    }
    
    func leaveRoom(_ roomId: String? = nil) {
        
    }
}
