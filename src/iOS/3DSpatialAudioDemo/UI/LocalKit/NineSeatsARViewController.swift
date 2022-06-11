//
//  NineSeatsARViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/03/24.
//

import UIKit
import ARKit
import DarkEggKit

class NineSeatsARViewController: BaseViewController {
    @IBOutlet weak var arView: ARSCNView!
    @IBOutlet weak var msgLabel: UILabel!
    
    @IBOutlet weak var uidListLabel: UILabel!
    @IBOutlet weak var selfPositionLabel: UILabel!
    
    @IBOutlet weak var setScreensButton: UIButton!
    
    var screens: [Int:Screen] = [:]
    var userScreenIndex: [UInt: Int] = [:]
    var userScreen: [UInt: Screen] = [:]
    var undisplayedUsers: [UInt] = []
    var positionUpdateTimer: Int = 0
    
    private var isARSessionPrepared: Bool = false
        private var isScreenSet: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.agoraMgr.delegate = self
        if let cName = self.channelName {
            //self.channelLabel.text = cName
            self.agoraMgr.join(channel: cName, asHost: true) { (success, uid) in
                if success {
                    Logger.debug("join channel \(cName) success: \(success), uid is \(uid)")
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
        // arView.debugOptions = [.showFeaturePoints]
        
        // start AR Session
        startARSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.agoraMgr.delegate = nil
        self.agoraMgr.leave()
    }
}

extension NineSeatsARViewController {
    @IBAction private func onSetSeatsButtonClicked(_ sender: UIButton) {
        //self.removeAllScreen()
        self.setScreens()
        self.isScreenSet = true
        sender.isEnabled = false
    }
    
    @IBAction private func onSceneTapped(_ recognizer: UITapGestureRecognizer) {
        print("onSceneTapped")
        let location = recognizer.location(in: self.arView)
        Logger.debug("\(location)")
        
        // if hit screen, show user select alert
        if let node = self.arView.hitTest(location, options: nil).first?.node {
            guard let screen = getScreen(of: node) else {
                Logger.debug("No screen is tapped")
                return
            }
            Logger.debug("Screen \(screen.index) is tapped.")
            
            let userSelectView = UIAlertController(title: "Select User", message: nil, preferredStyle: .actionSheet)
            for uid in self.undisplayedUsers {
                let action = UIAlertAction(title: "\(uid)", style: .default) { [weak self] action in
                    
                    //let pos = PositionManager.shared.getVoicePosition(ofScreen: index)
                    let pos = PositionManager.shared.getPositionOfSeat(screen.index)
                    Logger.debug("set user \(uid) to position \(pos)")
                    self?.agoraMgr.updatePosition(of: uid, position: pos)
                    if let oldScreen = self?.userScreen[uid] {
                        oldScreen.uid = 0
                    }
                    self?.userScreen[uid] = screen
                    screen.uid = uid
                    
                    self?.updateDebugLabel()
                    //if let idx = self?.undisplayedUsers.firstIndex(of: uid) {
                    //    self?.undisplayedUsers.remove(at: idx)
                    //    // print(self.undisplayedUsers)
                    //}
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
        return
    }
    
    private func getScreen(of node: SCNNode) -> Screen? {
        let rootNode: SCNNode
        if node.name == "screen", let parent = node.parent?.parent {
            rootNode = parent
            //screen = node
        } else if node.name == "displayer", let parent = node.parent {
            rootNode = parent
            //screen = parent.childNode(withName: "screen", recursively: false)!
        } else {
            rootNode = node
        }
        
        if let tag = rootNode.tag, tag > 0 {
            return screens[tag]
        }
        else {
            return nil
        }
    }
    
    private func updateDebugLabel() {
        var uidList = ""
        for uid in self.undisplayedUsers {
            uidList.append("\(uid):\r\n -> \(self.userScreen[uid]?.index ?? -1)\r\n")
        }
        self.uidListLabel.text = uidList
    }
    
    private func removeAllScreen() {
        //
        arView.scene.rootNode.childNodes.forEach { node in
            let rootNode: SCNNode
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
        }
    }
    
    // set 9 screen
    private func setScreens() {
        let camera = arView.session.currentFrame!.camera
        let rotation = camera.eulerAngles.y
        let rotation4x4 = camera.transform
        Logger.debug("\(rotation), \(rotation4x4)")
        let posOffset = camera.transform.columns.3
        for index in 0..<9 {
            self.addScreen(of: index, positionOffset: posOffset, rotation: rotation)
        }
    }
    
    /// Add screen
    /// - Parameters:
    ///   - index: index (0 ~ 8)
    private func addScreen(of index: Int, positionOffset: simd_float4, rotation: Float) {
        let screen = Screen(index: index)
        
        let pos = self.getPosition(ofScreen: index, positionOffset: positionOffset)
        screen.setPosition(pos)
        screen.setRotation(SCNVector4(0, 1, 0, rotation))
        
        screens[index] = screen
        
        arView.scene.rootNode.addChildNode(screen.rootNode)
    }
    
    private func getPosition(ofScreen index: Int) -> SCNVector3 {
        let seatPos = PositionManager.shared.getPositionOfScreen(index)
        let pos = SCNVector3(
            seatPos[0].intValue,
            seatPos[1].intValue,
            seatPos[2].intValue
        )
        return pos
    }
    
    /// Add node
    /// - Parameters:
    ///   - transform: matrix_float4x4
//    private func addNode(ofScreen index: Int) {
//        let scene = SCNScene(named: "AR.scnassets/displayer.scn")!
//        let rootNode = scene.rootNode
//        let pos = self.getPosition(ofSeat: index)
//        rootNode.position = pos
//        rootNode.rotation = SCNVector4(0, 1, 0, arView.session.currentFrame!.camera.eulerAngles.y)
//        arView.scene.rootNode.addChildNode(rootNode)
//        updateNodeUserLabel(uid: UInt(index), node: rootNode)
//    }
    
    private func getPosition(ofScreen index: Int, positionOffset: simd_float4) -> SCNVector3 {
        let seatPos = PositionManager.shared.getPositionOfScreen(index)
//        let seatPos = PositionManager.shared.getPositionOfSeat(index)
        let x = seatPos[0].floatValue + positionOffset.x
        let y = seatPos[1].floatValue + positionOffset.y
        let z = seatPos[2].floatValue + positionOffset.z
        Logger.debug("(\(x), \(y),\(z))")
        let pos = SCNVector3(x, y, z)
        return pos
    }
    
    func QuaternionMultVector(rotation: SCNQuaternion, point: SCNVector3) -> SCNVector3 {
        let num: Float = rotation.x * 2;
        let num2: Float = rotation.y * 2;
        let num3: Float = rotation.z * 2;
        let num4: Float = rotation.x * num;
        let num5: Float = rotation.y * num2;
        let num6: Float = rotation.z * num3;
        let num7: Float = rotation.x * num2;
        let num8: Float = rotation.x * num3;
        let num9: Float = rotation.y * num3;
        let num10: Float = rotation.w * num;
        let num11: Float = rotation.w * num2;
        let num12: Float = rotation.w * num3;
        var result: SCNVector3 = point
        result.x = (1 - (num5 + num6)) * point.x + (num7 - num12) * point.y + (num8 + num11) * point.z;
        result.y = (num7 + num12) * point.x + (1 - (num4 + num6)) * point.y + (num9 - num10) * point.z;
        result.z = (num8 - num11) * point.x + (num9 + num10) * point.y + (1 - (num4 + num5)) * point.z;
        return result;
    }
    
    private func getTransform(ofSeat index: Int) -> matrix_float4x4 {
        return matrix_float4x4()
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

extension NineSeatsARViewController {
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
}

// MARK: - AgoraManagerDelegate
extension NineSeatsARViewController: AgoraManagerDelegate {
    func agoraMgr(_ mgr: AgoraManager, seat: UInt, selectedBy uid: UInt) {
        // not used here
    }
    
    func agoraMgr(_ mgr: AgoraManager, seat: UInt, deselectedBy uid: UInt) {
        // not used here
    }
    
    func agoraMgr(_ mgr: AgoraManager, userJoined uid: UInt) {
        //
        self.undisplayedUsers.append(uid)
//        self.updateDebugLabel()
    }
    
    func agoraMgr(_ mgr: AgoraManager, userLeaved uid: UInt) {
        //
    }
}

// MARK: - ARSCNViewDelegate
extension NineSeatsARViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
//        let plane = SCNBox(width: CGFloat(planeAnchor.extent.x),
//                           height: CGFloat(planeAnchor.extent.y),
//                           length: CGFloat(planeAnchor.extent.z),
//                           chamferRadius: 0)
//        plane.firstMaterial?.diffuse.contents = UIColor.red
//
//        let planeNode = SCNNode(geometry: plane)
//        node.addChildNode(planeNode)
//        planeNode.runAction(SCNAction.fadeOut(duration: 3))
//
//        //found planar
//        if(!isPlanarDetected) {
//            DispatchQueue.main.async {[weak self] in
//                guard let weakSelf = self else {
//                    return
//                }
//                weakSelf.isPlanarDetected = true
//            }
//        }
    }
}

extension NineSeatsARViewController: ARSessionDelegate {
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        //Logger.debug( frame.camera.trackingState )
        self.positionUpdateTimer += 1
        guard self.positionUpdateTimer >= 2 else {
            return
        }

        self.positionUpdateTimer = 0
        let transform: simd_float4x4 = frame.camera.transform

        //Logger.debug("eulerAngles: \(frame.camera.eulerAngles)")
//        Logger.debug("transform0: \(transform.columns.0)")
//        Logger.debug("transform1: \(transform.columns.1)")
//        Logger.debug("transform2: \(transform.columns.2)")

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
        // Logger.debug("pos: \(pos)")
        updateSelfPositionLabel(pos, angle: frame.camera.eulerAngles, transform: transform)
        self.agoraMgr.updateSelfPosition(
            position: pos,
            forward: forward,
            right: right,
            up: up)
    }
}
