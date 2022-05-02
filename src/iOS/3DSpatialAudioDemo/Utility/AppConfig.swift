//
//  AppConfig.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/25.
//

import Foundation

// Agora config keys
private let kAgoraConfig: String            = "AgoraConfig"
private let kAgoraAppNameKey: String        = "AppId"
private let kAgoraAppCertificate: String    = "AppCertificate"

// default agora setting strings
private let DefaultAgoraAppName: String         = <#Your Agora project name (not used this time)#>
private let DefaultAgoraAppId: String           = <#Your Agora AppId#>    // default App Id
private let DefaultAgoraAppCertificate: String  = <#Your Agora App Certificate (not used this time)#>    // default App Certificate

// AgoraChat config keys
private let kAgoraChatConfig: String        = "AgoraChatConfig"
private let kAgoraChatAppKey: String        = "AppKey"

// default AgoraChat setting strings
private let DefaultAgoraChatAppKey: String  = <#Your AgoraChat AppKey (not used this time)#>

// default AgoraChat config

/// struct for agora config
struct AgoraConfig: Codable {
    //var appName: String
    var appId: String
    var appCertificate: String
    //var token: String
}

///struct for agora chat config
struct AgoraChatConfig: Codable {
    var appKey: String
}

class AppConfig {
    private let decoder = JSONDecoder() 
    private let encoder = JSONEncoder()
    
    let defaultAgoraConfig = AgoraConfig(appId: DefaultAgoraAppId, appCertificate: DefaultAgoraAppCertificate)
    let defaultAgoraChatConfig = AgoraChatConfig(appKey: DefaultAgoraChatAppKey)
    
    static let shared: AppConfig = {AppConfig()}()
    
    /// agora config
    lazy var agora: AgoraConfig = {
        guard let dict = Bundle.main.object(forInfoDictionaryKey: kAgoraConfig) as? [String: String],
              let data = try? encoder.encode(dict),
              let config = try? decoder.decode(AgoraConfig.self, from: data) else {
            return self.defaultAgoraConfig
        }
        return config
    }()
    
    lazy var agoraChat: AgoraChatConfig = {
        guard let dict = Bundle.main.object(forInfoDictionaryKey: kAgoraChatConfig) as? [String: String],
              let data = try? encoder.encode(dict),
              let config = try? decoder.decode(AgoraChatConfig.self, from: data) else {
            return self.defaultAgoraChatConfig
        }
        return config
    }()
}
