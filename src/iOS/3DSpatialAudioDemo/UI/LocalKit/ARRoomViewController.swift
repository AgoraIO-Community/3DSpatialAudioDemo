//
//  SeatViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/10/14.
//

import Foundation
import UIKit
import ARKit
//import RealityKit

class ARRoomViewController: UIViewController {
    
    @IBOutlet weak var arView: ARSCNView!
    
    @IBOutlet weak var msgLabel: UILabel!
    
    @IBOutlet weak var uidListLabel: UILabel!
    @IBOutlet weak var selfPositionLabel: UILabel!
    
    //var arSession: ARSession = ARSession()
    
    var channelName: String?
    var isHost: Bool = false
    var undisplayedUsers: [UInt] = []
    var displayedUsers: [UInt] = []
    var userNodes: [UInt: SCNNode] = [:]
    var userPositions: [UInt: [NSNumber]] = [:]
    let agoraMgr = AgoraManager.shared
    
    var positionUpdateTimer: Int = 0
    
    private var isPlanarDetected: Bool = false{
        didSet {
            if ( isPlanarDetected ) {
                self.msgLabel.text = "Tap to place remote video canvas"
            } else {
                self.msgLabel.text = "Move Camera to find a planar\n(Shown as Red Rectangle)"
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.agoraMgr.delegate = self
        if let cName = self.channelName {
            //self.channelLabel.text = cName
            self.agoraMgr.join(channel: cName, asHost: true) { (success, uid) in
                if success {
                    print("join channel \(cName) success: \(success), uid is \(uid)")
                    // set self position
                    PositionManager.shared.resetSelfPosition()
                    //self.uidLabel.text = "\(uid)"
                }
                else {
                    
                }
            }
        }
        
        //set AR Scene delegate
        arView.delegate = self
        arView.session.delegate = self
        arView.showsStatistics = true
        arView.debugOptions = [.showFeaturePoints]
        
        // start AR Session
        startARSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        arSession
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.agoraMgr.delegate = nil
        self.agoraMgr.leave()
        self.stopARSession()
    }
}

extension ARRoomViewController {
    private func startARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            //showAlert(title: "ARKit is not available on this device.".localized, message: "This app requires world tracking, which is available only on iOS devices with the A9 processor or later.".localized)
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        //configuration.planeDetection = .horizontal
        // remember to set this to false, or ARKit may conflict with Agora SDK
        configuration.providesAudioData = false

        // start session
        arView.session.run(configuration)
    }
    
    // stop AR Tracking
    private func stopARSession() {
        arView.session.pause()
    }
    
    //
    @IBAction private func onSceneTapped(_ recognizer: UITapGestureRecognizer) {
        print("onSceneTapped")
//        guard self.isPlanarDetected else {
//            return
//        }
        
        let location = recognizer.location(in: self.arView)
        print("\(location)")
        
        // if hit screen
        // remove it
        if let node = self.arView.hitTest(location, options: nil).first?.node {
            print("removeNode")
            self.removeNode(node)
        }
        // if hit nothing, add a screen
//        print("location: \(location)")
//        print("arView.center: \(arView.center)")
//        let query = self.arView.raycastQuery(from: arView.center, allowing: .estimatedPlane, alignment: .any)
//        print("query?.direction: \(query?.direction)")
//        print("query?.origin: \(query?.origin)")
//        let results = arView.session.raycast(query!)
//        if let a: ARRaycastResult = results.first {
//            print("first point from ray cast query: \(a.worldTransform)")
//        }
        if let result = self.arView.hitTest(location, types: .featurePoint).first {
            let userSelectView = UIAlertController(title: "Select User", message: nil, preferredStyle: .actionSheet)
            for uid in self.undisplayedUsers {
                let action = UIAlertAction(title: "\(uid)", style: .default) { [weak self] action in
                    //
                    print("addNode for user: \(uid) at \(result.worldTransform)")
                    self?.addNode(withTransform: result.worldTransform, ofUser: uid)
                }
                userSelectView.addAction(action)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
                //.dismiss(animated: true, completion: nil)
            }
            userSelectView.addAction(cancelAction)
            self.present(userSelectView, animated: true) {
                // todo
            }
        }
        
//        let userSelectView = UIAlertController(title: "Select User", message: nil, preferredStyle: .actionSheet)
//
//        for uid in self.undisplayedUsers {
//            let action = UIAlertAction(title: "\(uid)", style: .default) { [weak self] action in
//                //
//                if let node = self?.arView.hitTest(location, options: nil).first?.node {
//                    print("removeNode")
//                    self?.removeNode(node)
//                } else if let result = self?.arView.hitTest(location, types: .featurePoint).first {
//                    print("addNode")
//                    self?.addNode(withTransform: result.worldTransform, ofUser: uid)
//                }
//            }
//            userSelectView.addAction(action)
//        }
//
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
//            //.dismiss(animated: true, completion: nil)
//        }
//        userSelectView.addAction(cancelAction)
//
//        self.present(userSelectView, animated: true) {
//            // todo
//        }
        return
    }
    
    @IBAction private func onCloseButtonClicked(_ sender: UIButton?) {
        self.dismiss(animated: true) {
            self.agoraMgr.delegate = nil
            self.agoraMgr.leave()
            self.stopARSession()
        }
    }
    
    private func randomSetUser(uid: UInt) {
        print("random set position of \(uid)")
    }
}

extension ARRoomViewController {
    private func addNode(withTransform transform: matrix_float4x4, ofUser uid: UInt) {
        let scene = SCNScene(named: "AR.scnassets/displayer.scn")!
        let rootNode = scene.rootNode
        
        rootNode.position = SCNVector3(
            transform.columns.3.x,
            transform.columns.3.y,
            transform.columns.3.z
        )
        rootNode.rotation = SCNVector4(0, 1, 0, arView.session.currentFrame!.camera.eulerAngles.y)
        
        self.updateNodeUserLabel(uid: uid, node: rootNode)
        
        arView.scene.rootNode.addChildNode(rootNode)
        
        userNodes[uid] = rootNode
        
        let pos = [
            NSNumber(value: transform.columns.3.x),
            NSNumber(value: transform.columns.3.y),
            NSNumber(value: transform.columns.3.z),
        ]
        userPositions[uid] = pos
        
        self.agoraMgr.updatePosition(of: uid, position: pos)
        
        self.updateDebugLabel()
        
        if let idx = self.undisplayedUsers.firstIndex(of: uid) {
            self.undisplayedUsers.remove(at: idx)
            print(self.undisplayedUsers)
        }
    }
    
    private func removeNode(_ node: SCNNode) {
        let rootNode: SCNNode
        //let screen: SCNNode
        
        if node.name == "screen", let parent = node.parent?.parent {
            rootNode = parent
            //screen = node
        } else if node.name == "displayer", let parent = node.parent {
            rootNode = parent
            //screen = parent.childNode(withName: "screen", recursively: false)!
        } else {
            rootNode = node
            //screen = node
        }
        
        rootNode.removeFromParentNode()
        
        for k in userNodes.keys {
            if userNodes[k] == rootNode {
                print("removeNode \(k)")
                userNodes.removeValue(forKey: k)
                self.undisplayedUsers.append(k)
                print(self.undisplayedUsers)
            }
        }
    }
    
    private func updateNodeUserLabel(uid: UInt, node: SCNNode) {
        let displayer = node.childNode(withName: "displayer", recursively: false)!
        let screen = displayer.childNode(withName: "screen", recursively: false)!
        
        let skScene = SKScene(size: CGSize(width: 140, height: 140))
        skScene.backgroundColor = UIColor.clear
        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 140, height: 140), cornerRadius: 0)
        //rectangle.fillColor = #colorLiteral(red: 0.807843148708344, green: 0.0274509806185961, blue: 0.333333343267441, alpha: 1.0)
        //rectangle.strokeColor = #colorLiteral(red: 0.439215689897537, green: 0.0117647061124444, blue: 0.192156866192818, alpha: 1.0)
        rectangle.lineWidth = 0
        rectangle.alpha = 0.4
        let labelNode = SKLabelNode(text: "\(uid)")
        labelNode.fontSize = 20
        labelNode.fontName = "San Fransisco"
        labelNode.position = CGPoint(x:70,y:70)
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
    
    private func updateDebugLabel() {
        var uidList = ""
        for uid in self.undisplayedUsers {
            uidList.append("\(uid):\r\n -> \(self.userPositions[uid] ?? [0,0,0])\r\n")
        }
        self.uidListLabel.text = uidList
    }
    
    private func updateSelfPositionLabel(_ pos: [NSNumber], angle: simd_float3, transform: simd_float4x4) {
        let trans: simd_float4x4 = simd_float4x4(
            simd_float4(1, 0, 0, 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(0, 0, -1, 0),
            simd_float4(0, 0, 0, 1)
        )
        
        let transR: simd_float4x4 = simd_float4x4(
            simd_float4(1, 0, 0, 0),
            simd_float4(0, 0, -1, 0),
            simd_float4(0, 1, 0, 0),
            simd_float4(0, 0, 0, 1)
        )
        
        let transB: simd_float4x4 = simd_float4x4(
            simd_float4(0, 1, 0, 0),
            simd_float4(-1, 0, 0, 0),
            simd_float4(0, 0, 1, 0),
            simd_float4(0, 0, 0, 1)
        )
        
        let result = transform //* transB // * trans * transR
        
        self.selfPositionLabel.font = UIFont.monospacedSystemFont(ofSize: 12.0, weight: .medium)
        self.selfPositionLabel.text = """
        Position: \(String(format:  "%.2f" ,pos[0])), \(String (format:  "%.2f" ,pos[1])),\(String (format:  "%.2f" ,pos[2]))
        angle: \(String(format:  "%.2f" ,angle[0])),\(String(format:  "%.2f",angle[1])),\(String(format:  "%.2f",angle[2]))
        4x4 matrix column
            X     Y     Z     T
        x | \(String (format:  "%+.2f" ,result.columns.0.x)) \(String (format:  "%+.2f" ,result.columns.1.x)) \(String (format:  "%+.2f" ,result.columns.2.x)) \(String (format:  "%+.2f" ,result.columns.3.x)) |
        y | \(String (format:  "%+.2f" ,result.columns.0.y)) \(String (format:  "%+.2f" ,result.columns.1.y)) \(String (format:  "%+.2f" ,result.columns.2.y)) \(String (format:  "%+.2f" ,result.columns.3.y)) |
        z | \(String (format:  "%+.2f" ,result.columns.0.z)) \(String (format:  "%+.2f" ,result.columns.1.z)) \(String (format:  "%+.2f" ,result.columns.2.z)) \(String (format:  "%+.2f" ,result.columns.3.z)) |
        w | \(String (format:  "%+.2f" ,result.columns.0.w)) \(String (format:  "%+.2f" ,result.columns.1.w)) \(String (format:  "%+.2f" ,result.columns.2.w)) \(String (format:  "%+.2f" ,result.columns.3.w)) |
        """
        /*
         transform 0: \(String (format:  "%.2f" ,transform.columns.0.x)), \(String (format:  "%.2f" ,transform.columns.0.y)),\(String (format:  "%.2f" ,transform.columns.0.z)),\(String (format:  "%.2f" ,transform.columns.0.w))
         transform 1: \(String (format:  "%.2f" ,transform.columns.1.x)), \(String (format:  "%.2f" ,transform.columns.1.y)),\(String (format:  "%.2f" ,transform.columns.1.z)),\(String (format:  "%.2f" ,transform.columns.1.w))
         transform 2: \(String (format:  "%.2f" ,transform.columns.2.x)), \(String (format:  "%.2f" ,transform.columns.2.y)),\(String (format:  "%.2f" ,transform.columns.2.z)),\(String (format:  "%.2f" ,transform.columns.2.w))
         transform 2: \(String (format:  "%.2f" ,transform.columns.3.x)), \(String (format:  "%.2f" ,transform.columns.3.y)),\(String (format:  "%.2f" ,transform.columns.3.z)),\(String (format:  "%.2f" ,transform.columns.3.w))
         */
        //transform.inverse.columns.
    }
}

extension ARRoomViewController: AgoraManagerDelegate {
    func agoraMgr(_ mgr: AgoraManager, seat: UInt, selectedBy uid: UInt) {
        // not used here
    }
    
    func agoraMgr(_ mgr: AgoraManager, seat: UInt, deselectedBy uid: UInt) {
        // not used here
    }
    
    func agoraMgr(_ mgr: AgoraManager, userJoined uid: UInt) {
        //
        self.undisplayedUsers.append(uid)
        self.updateDebugLabel()
    }
    
    func agoraMgr(_ mgr: AgoraManager, userLeaved uid: UInt) {
        //
    }
}

extension ARRoomViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let plane = SCNBox(width: CGFloat(planeAnchor.extent.x),
                           height: CGFloat(planeAnchor.extent.y),
                           length: CGFloat(planeAnchor.extent.z),
                           chamferRadius: 0)
        plane.firstMaterial?.diffuse.contents = UIColor.red
        
        let planeNode = SCNNode(geometry: plane)
        node.addChildNode(planeNode)
        planeNode.runAction(SCNAction.fadeOut(duration: 3))
        
        //found planar
        if(!isPlanarDetected) {
            DispatchQueue.main.async {[weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.isPlanarDetected = true
            }
        }
    }
}

extension ARRoomViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        self.positionUpdateTimer += 1
        guard self.positionUpdateTimer >= 2 else {
            return
        }
        
        self.positionUpdateTimer = 0
        let transform: simd_float4x4 = frame.camera.transform
        
        //print("eulerAngles: \(frame.camera.eulerAngles)")
        print("transform0: \(transform.columns.0)")
        print("transform1: \(transform.columns.1)")
        print("transform2: \(transform.columns.2)")
        
        let pos = [
            NSNumber(value: transform.columns.3.x),
            NSNumber(value: transform.columns.3.y),
            NSNumber(value: transform.columns.3.z),
        ]
        let forward = [
            NSNumber(value: transform.columns.0.x),
            NSNumber(value: transform.columns.0.y),
            NSNumber(value: transform.columns.0.z),
        ]
        let right = [
            NSNumber(value: transform.columns.1.x),
            NSNumber(value: transform.columns.1.y),
            NSNumber(value: transform.columns.1.z),
        ]
        let up = [
            NSNumber(value: transform.columns.2.x),
            NSNumber(value: transform.columns.2.y),
            NSNumber(value: transform.columns.2.z),
        ]
        //print("pos: \(pos)")
        updateSelfPositionLabel(pos, angle: frame.camera.eulerAngles, transform: transform)
        self.agoraMgr.updateSelfPosition(
            position: pos,
            forward: forward,
            right: right,
            up: up)
    }
}
