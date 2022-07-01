//
//  Enumerations.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/16.
//

import Foundation

/// SoundEffect
enum SoundEffect : Int, CustomStringConvertible, Codable {
    case disable
    case enable
    case applyToTeam
    
    public var description: String {
        switch self {
        case .disable:
            return "Close"
        case .enable:
            return "Open"
        default:
            return "Include Team"
        }
    }
}

/// Sound names
enum Sound : String, CaseIterable {
    case music
    case sound1
    case sound2
    case sound3
    case song01Vocal
    case song01Instrumental
    
    private var fileName: String {
        switch self {
        case .music:
            return "With-You-in-My-Arms-SSJ011001"
        case .sound1:
            return "sound01"                // "DogsBarkingCUandDistInfuriated"
        case .sound2:
            return "sound02"                // "ManWhistlingLikeAS"
        case .sound3:
            return "sound03"                // "CrixCicadasLoopNig"
        case .song01Vocal:
            return "song01_vocal"           // song01 vocal
        case .song01Instrumental:
            return "song01_instrumental"    // song01 instrumental
        }
    }
    
    var filePath: String? {
        return Bundle.main.path(forResource: self.fileName, ofType: "mp3")
    }
}

/// Spatial audio mode, local or cloud
enum SpatialAudioMode: String, CaseIterable {
    case cloud
    case local
    
    var spatialKit: SpatialAudioProtocol {
        switch self {
        case .local:
            return LocalSpatialKit.shared
        case .cloud:
            return CloudSpatialKit.shared
        }
    }
}

