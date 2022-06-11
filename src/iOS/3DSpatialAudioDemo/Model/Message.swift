//
//  Message.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/03/01.
//

//import AgoraRtmKit
import Foundation

enum MessageType: Int, CaseIterable {
    case text = 0
    case seat = 1
    case gift = 2
}

protocol Message: Codable {
    var uid: UInt? {get set}
    var type: Int? {get set}
}

class TextMessage: Message {
    var uid: UInt?
    var type: Int?
    var text: String?
}

class SeatMessage: Message {
    var uid: UInt?
    var type: Int?
    var seatIndex: Int?
}

class GiftMessage: Message {
    var uid: UInt?
    var type: Int?
    var giftId: String?
}

