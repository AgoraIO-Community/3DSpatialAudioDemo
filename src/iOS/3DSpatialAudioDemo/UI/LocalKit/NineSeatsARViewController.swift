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
    
    @IBOutlet weak var setSeatsButton: UIButton!
    
    var userSeat: [UInt: Int] = [:]
    var userNodes: [UInt: SCNNode] = [:]
    var userPositions: [UInt: [NSNumber]] = [:]
    var undisplayedUsers: [UInt] = []
    var positionUpdateTimer: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
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
}

extension NineSeatsARViewController {
    @IBAction private func onSetSeatsButtonClicked(_ sender: UIButton) {
        //self.removeAllScreen()
        self.setScreens()
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
        for index in 0..<9 {
            self.addNode(ofScreen: index)
        }
    }
    
    /// Add node
    /// - Parameters:
    ///   - transform: matrix_float4x4
    private func addNode(ofScreen index: Int) {
        let scene = SCNScene(named: "AR.scnassets/displayer.scn")!
        let rootNode = scene.rootNode
        let pos = self.getPosition(ofSeat: index)
        rootNode.position = pos
        rootNode.rotation = SCNVector4(0, 1, 0, arView.session.currentFrame!.camera.eulerAngles.y)
        arView.scene.rootNode.addChildNode(rootNode)
        updateNodeUserLabel(uid: UInt(index), node: rootNode)
    }
    
    private func getPosition(ofSeat index: Int) -> SCNVector3 {
        let seatPos = PositionManager.shared.getPositionOfScreen(index)
//        let seatPos = PositionManager.shared.getPositionOfSeat(index)
        let pos = SCNVector3(
            seatPos[0].intValue,
            seatPos[1].intValue,
            seatPos[2].intValue
        )
        
        return pos
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

extension NineSeatsARViewController {
    @IBAction private func onSceneTapped(_ recognizer: UITapGestureRecognizer) {
        print("onSceneTapped")
//        guard self.isPlanarDetected else {
//            return
//        }
        
        let location = recognizer.location(in: self.arView)
        Logger.debug("\(location)")
        
        // if hit screen
        // remove it
        if let node = self.arView.hitTest(location, options: nil).first?.node {
            Logger.debug("node tapped \(node)")
        }
        return
    }
}

// MARK: -
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
        Logger.debug( frame.camera.trackingState )
        self.positionUpdateTimer += 1
        guard self.positionUpdateTimer >= 2 else {
            return
        }

        self.positionUpdateTimer = 0
        let transform: simd_float4x4 = frame.camera.transform

        //print("eulerAngles: \(frame.camera.eulerAngles)")
//        print("transform0: \(transform.columns.0)")
//        print("transform1: \(transform.columns.1)")
//        print("transform2: \(transform.columns.2)")

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
        // print("pos: \(pos)")
        updateSelfPositionLabel(pos, angle: frame.camera.eulerAngles, transform: transform)
        self.agoraMgr.updateSelfPosition(
            position: pos,
            forward: forward,
            right: right,
            up: up)
    }
}
