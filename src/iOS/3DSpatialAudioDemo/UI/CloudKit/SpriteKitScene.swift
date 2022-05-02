//
//  SpriteKitScene.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/15.
//

import GameKit
import AgoraRtcKit

class SpriteKitScene: SKScene {
    var selfNode: SKSpriteNode?
    var remoteNode: SKSpriteNode?
    
    var agoraKit: AgoraRtcEngineKit?
    
    override func didMove(to view: SKView) {
        createScene()
    }
    
    func createAgoraEn() {
        //goraKit = AgoraRtcEngineKit.sharedEngine(with: nil, delegate: self)
    }
    
    func createScene() {
        self.backgroundColor = .systemBackground
        self.selfNode = SKSpriteNode(color: .systemOrange, size: CGSize(width: 60, height: 60))
    }
}

extension SpriteKitScene: AgoraRtcEngineDelegate {
    
}
