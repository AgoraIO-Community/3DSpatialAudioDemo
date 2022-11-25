//
//  Screen.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/05/24.
//

import Foundation
import SceneKit
import SpriteKit

class Screen {
    var uid: UInt = 0{
        didSet {
            guard uid > 0 else {
                // TODO: update label to index
                self.labelNode.text = "\(self.index)"
                return
            }
            // TODO: update label to uid
            let text = uid > 0 ? "\(uid)" : "\(index)"
            self.labelNode.text = text
        }
    }
    private(set) var index: Int = -1
    var videoOn: Bool = false {
        didSet {
            // TODO: turn on video
        }
    }

    var rootNode: SCNNode!
    var labelNode: SKLabelNode!

    init(index: Int = -1, uid: UInt = 0) {
        self.index = index
        self.uid = uid
        // create node
        let scnScene = SCNScene(named: "AR.scnassets/displayer.scn")!
        rootNode = scnScene.rootNode
        rootNode.tag = index

        let text = uid > 0 ? "\(uid)" : "\(index)"
        labelNode = SKLabelNode(text: text)
        labelNode.fontSize = 20
        labelNode.fontName = UIFont.systemFont(ofSize: 14).fontName
        labelNode.position = CGPoint(x:70,y:70)
        self.setLabel()
    }

    private func setLabel() {
        let displayer = rootNode.childNode(withName: "displayer", recursively: false)!
        let screen = displayer.childNode(withName: "screen", recursively: false)!

        let skScene = SKScene(size: CGSize(width: 140, height: 140))
        skScene.backgroundColor = UIColor.clear
        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 140, height: 140), cornerRadius: 0)
        //rectangle.fillColor = #colorLiteral(red: 0.807843148708344, green: 0.0274509806185961, blue: 0.333333343267441, alpha: 1.0)
        //rectangle.strokeColor = #colorLiteral(red: 0.439215689897537, green: 0.0117647061124444, blue: 0.192156866192818, alpha: 1.0)
        rectangle.lineWidth = 0
        rectangle.alpha = 0.4
        skScene.addChild(rectangle)
        skScene.addChild(labelNode)

        let plane = SCNPlane(width: 1, height: 1)
        let material = SCNMaterial()
        material.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        material.isDoubleSided = true
        material.diffuse.contents = skScene
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        screen.addChildNode(node)
    }
}

extension Screen {
    func setPosition(_ pos: SCNVector3) {
//        rootNode.position = pos
        rootNode.transform = SCNMatrix4MakeTranslation(pos.x, pos.y, pos.z)
    }

    func setRotation(_ rotation: SCNVector4) {
        rootNode.rotation = rotation
    }
}

extension Screen {
    func setUser(uid: UInt) {
        self.uid = uid
        let text = uid > 0 ? "\(uid)" : "\(index)"
        self.labelNode.text = text
    }

    func removeUser() {
        self.uid = 0
        // refresh label
        self.labelNode.text = "\(self.index)"
    }
    
    func setVideoFrame(texture: SKTexture) {
        let material = SCNMaterial()
        let p = SCNMaterialProperty()
        p.contents = texture
        material.diffuse.contents = p
        let plane = SCNPlane(width: 1, height: 1)
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        let displayer = rootNode.childNode(withName: "displayer", recursively: false)!
        let screen = displayer.childNode(withName: "screen", recursively: false)!
        screen.addChildNode(node)
    }
}

// MARK: - Add tag to SCNNode
protocol PropertyStoring {
    associatedtype T
    func getAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T) -> T
}

extension PropertyStoring {
    func getAssociatedObject(_ key: UnsafeRawPointer!, defaultValue: T) -> T {
        guard let value = objc_getAssociatedObject(self, key) as? T else {
            return defaultValue
        }
        return value
    }
}

extension SCNNode: PropertyStoring {
    typealias T = Int

    private struct AssociatedKeys {
        static var kNodeTag = "kNodeTag"
    }

    public var tag: Int? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.kNodeTag) as? Int
        }
        set {
            if let value = newValue {
                objc_setAssociatedObject(self, &AssociatedKeys.kNodeTag, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
}
