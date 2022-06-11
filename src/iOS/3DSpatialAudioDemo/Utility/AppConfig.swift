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

// default AgoraChat config

/// struct for agora config
struct AgoraConfig: Codable {
    //var appName: String
    var appId: String
    var appCertificate: String
    //var token: String
}

class AppConfig {
    private let decoder = JSONDecoder() 
    private let encoder = JSONEncoder()
    
    let defaultAgoraConfig = AgoraConfig(appId: DefaultAgoraAppId, appCertificate: DefaultAgoraAppCertificate)
    
    static let shared: AppConfig = {AppConfig()}()
    
    /// Agora config
    ///     Load from info.plist. Please check the info.plist.
    ///     If can not load, use default.
    lazy var agora: AgoraConfig = {
        guard let dict = Bundle.main.object(forInfoDictionaryKey: kAgoraConfig) as? [String: String],
              let data = try? encoder.encode(dict),
              let config = try? decoder.decode(AgoraConfig.self, from: data),
              !config.appId.isEmpty else {
            return self.defaultAgoraConfig
        }
        return config
    }()
}
