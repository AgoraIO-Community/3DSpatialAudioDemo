//
//  Error.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/03/01.
//

import AgoraRtcKit
//import AgoraRtmKit

enum DemoError: Error {
    case rtcError(Int)
    //case rtmLoginError(AgoraRtmLoginErrorCode)
    enum rtm: Error {
        case createChannelFailed
        case joinChannelFaied
    }
}
