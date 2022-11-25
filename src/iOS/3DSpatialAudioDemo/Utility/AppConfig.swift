//
//  AppConfig.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/25.
//

import Foundation

// Agora config keys
private let kAgoraConfig: String            = "AgoraConfig"
private let kAgoraAppIdKey: String          = "AppId"
private let kAgoraAppCertificate: String    = "AppCertificate"

// default agora setting strings
private let DefaultAgoraAppName: String         = <#Your Agora project name (not used this time)#>
private let DefaultAgoraAppId: String           = <#Your Agora AppId#>    // default App Id
private let DefaultAgoraAppCertificate: String  = <#Your Agora App Certificate (not used this time)#>    // default App Certificate

struct KeychainConfiguration {
    static var serviceName: String {
        let bundleId = Bundle.main.bundleIdentifier ?? "cn.darkzero.Radio3DAudioSample"
        return bundleId
    }
    static let accessGroup: String? = nil
}

/// struct for agora config
struct AgoraConfig: Codable {
    //var appName: String
    var appId: String
    var appCertificate: String
    var token: String?
}

struct BasicConfig: Codable {
    var language: String
}

class AppConfig {
    private let decoder = JSONDecoder() 
    private let encoder = JSONEncoder()
    
    private let keychainAppConfig = KeychainAppConfig(service: KeychainConfiguration.serviceName);
    
    let defaultAgoraConfig = AgoraConfig(appId: DefaultAgoraAppId, appCertificate: DefaultAgoraAppCertificate)
    let defaultBasicConfig = BasicConfig(language: "")
    
    static let shared: AppConfig = {AppConfig()}()
    
    /// Agora config
    ///     Load from info.plist. Please check the info.plist.
    ///     If can not load, use default.
    lazy var agora: AgoraConfig = {
        // load from keychain
        if let _appId = try? keychainAppConfig.readItem(key: kAgoraAppIdKey) {
            let config = AgoraConfig(appId: _appId, appCertificate: DefaultAgoraAppCertificate)
            return config
        }
        
        // load from info.plist
        guard let dict = Bundle.main.object(forInfoDictionaryKey: kAgoraConfig) as? [String: String],
              let data = try? encoder.encode(dict),
              let config = try? decoder.decode(AgoraConfig.self, from: data),
              !config.appId.isEmpty else {
            return self.defaultAgoraConfig
        }
        return config
    }()
    
    // TODO: language
    lazy var basic: BasicConfig = {
        if let _language = try? keychainAppConfig.readItem(key: kAgoraAppIdKey) {
            let config = BasicConfig(language: _language)
            return config
        }
        return defaultBasicConfig
    }()
}

// MARK: - Keychain
struct KeychainAppConfig {
    // MARK: Types
    enum KeychainError: Error {
        case noData
        case unexpectedData
        case unhandledError(status: OSStatus)
    }
    
    let service: String
    
    private(set) var account: String?
    
    let accessGroup: String?
    
    // MARK: Intialization
    
    init(service: String, account: String? = nil, accessGroup: String? = nil) {
        self.service = service
        self.account = account
        self.accessGroup = accessGroup
    }
    
    // read
    func readItem(key: String) throws -> String  {
        /*
         Build a query to find the item that matches the service, account and
         access group.
         */
        var query = KeychainAppConfig.keychainQuery(withService: service, account: key, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw KeychainError.noData }
        guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        
        // Parse the password string from the query result.
        guard let existingItem = queryResult as? [String : AnyObject],
            let itemData = existingItem[kSecValueData as String] as? Data,
            let item = String(data: itemData, encoding: String.Encoding.utf8)
            else {
                throw KeychainError.unexpectedData
        }
        
        return item
    }
    
    func saveItem(key: String, value: String) throws {
        // Encode the password into an Data object.
        let encodedPassword = value.data(using: String.Encoding.utf8)!
        
        do {
            // Check for an existing item in the keychain.
            try _ = readItem(key: key)
            
            // Update the existing item with the new password.
            var attributesToUpdate = [String : AnyObject]()
            attributesToUpdate[kSecValueData as String] = encodedPassword as AnyObject?
            
            let query = KeychainAppConfig.keychainQuery(withService: service, account: key, accessGroup: accessGroup)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
        catch KeychainError.noData {
            /*
             No password was found in the keychain. Create a dictionary to save
             as a new keychain item.
             */
            var newItem = KeychainAppConfig.keychainQuery(withService: service, account: key, accessGroup: accessGroup)
            newItem[kSecValueData as String] = encodedPassword as AnyObject?
            
            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
    }
    
    func deleteItem(key: String) throws {
        // Delete the existing item from the keychain.
        let query = KeychainAppConfig.keychainQuery(withService: service, account: key, accessGroup: accessGroup)
        let status = SecItemDelete(query as CFDictionary)
        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }

    func getUserInfo(forService service: String, accessGroup: String? = nil) throws -> [KeychainAppConfig] {
        var query = KeychainAppConfig.keychainQuery(withService: service, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanFalse
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        };
        
        // If no items were found, return an empty array.
        guard status != errSecItemNotFound else { return [] }
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        
        // Cast the query result to an array of dictionaries.
        guard let resultData = queryResult as? [[String : AnyObject]] else { throw KeychainError.unexpectedData }
        
        // Create a `KeychainPasswordItem` for each dictionary in the query result.
        var passwordItems = [KeychainAppConfig]()
        for result in resultData {
            guard let account  = result[kSecAttrAccount as String] as? String else { throw KeychainError.unexpectedData }
            
            let passwordItem = KeychainAppConfig(service: service, account: account, accessGroup: accessGroup)
            passwordItems.append(passwordItem)
        }
        
        return passwordItems
    }
    
    // MARK: Convenience
    private static func keychainQuery(withService service: String, account: String? = nil, accessGroup: String? = nil) -> [String : AnyObject] {
        var query = [String : AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?
        
        if let account = account {
            query[kSecAttrAccount as String] = account as AnyObject?
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }
        
        return query
    }
}

