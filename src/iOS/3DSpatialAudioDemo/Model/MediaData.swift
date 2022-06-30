//
//  MediaData.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/06/22.
//

import Foundation

struct MediaData: Codable {
    var name: String
    var type: String = "mp3"
    var path: String? {
        return Bundle.main.path(forResource: self.name, ofType: "mp3")
    }
}

enum MediaType: String, CaseIterable {
    case Basses
    case Cello
    case Choir
    case Clarinets
    case Flutes
    case Harp
    case Horn
    case Piano
    case Timpani
    case Trombone
    case Trumpet
    case Viola
    case Violin_1
    case Violin_2
    
    var data: MediaData {
        return MediaData(name: self.rawValue, type: "mp3")
    }
    
    var localUid: Int {
        switch self {
        case .Basses:
            return 100001
        case .Cello:
            return 100002
        case .Choir:
            return 100003
        case .Clarinets:
            return 100004
        case .Flutes:
            return 100005
        case .Harp:
            return 100006
        case .Horn:
            return 100007
        case .Piano:
            return 100008
        case .Timpani:
            return 100009
        case .Trombone:
            return 100010
        case .Trumpet:
            return 100011
        case .Viola:
            return 100012
        case .Violin_1:
            return 100013
        case .Violin_2:
            return 100014
        default:
            return 0
        }
    }
    
    var filePath: String? {
        return Bundle.main.path(forResource: self.rawValue, ofType: "mp3")
    }
    
    static func TypeOf(uid: Int) -> MediaType? {
        switch uid {
        case 100001:
            return .Basses
        case 100002:
            return .Cello
        case 100003:
            return .Choir
        case 100004:
            return .Clarinets
        case 100005:
            return .Flutes
        case 100006:
            return .Harp
        case 100007:
            return .Horn
        case 100008:
            return .Piano
        case 100009:
            return .Timpani
        case 100010:
            return .Trombone
        case 100011:
            return .Trumpet
        case 100012:
            return .Viola
        case 100013:
            return .Violin_1
        case 100014:
            return .Violin_2
        default:
            return nil
        }
    }
}
