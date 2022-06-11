//
//  RealityKitViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/11/17.
//

import UIKit
import RealityKit
import ARKit
import DarkEggKit

class RealityKitViewController: UIViewController {
    @IBOutlet weak var arView: ARView!
    
    var channelName: String?
    var isHost: Bool = false
    var undisplayedUsers: [UInt] = []
    var displayedUsers: [UInt] = []
    var userNodes: [UInt: SCNNode] = [:]
    var userPositions: [UInt: [NSNumber]] = [:]
    let agoraMgr = AgoraManager.shared
    
    var positionUpdateTimer: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.agoraMgr.delegate = self
        if let cName = self.channelName {
            //self.channelLabel.text = cName
            self.agoraMgr.join(channel: cName, asHost: true) { (success, uid) in
                if success {
                    Logger.debug("success: \(success)")
                    // set self position
                    self.agoraMgr.updateSelfPosition(
                        position: [
                            NSNumber(value: 0),
                            NSNumber(value: 0),
                            NSNumber(value: 0)
                        ], forward: [
                            NSNumber(value: 0),
                            NSNumber(value: 1),
                            NSNumber(value: 0)
                        ], right: [
                            NSNumber(value: 1),
                            NSNumber(value: 0),
                            NSNumber(value: 0)
                        ], up: [
                            NSNumber(value: 0),
                            NSNumber(value: 0),
                            NSNumber(value: 1)
                    ])
                    
                    //self.uidLabel.text = "\(uid)"
                }
                else {
                    
                }
            }
        }
        
        //set AR View delegate
//        arView.delegate = self
        arView.session.delegate = self
//        arView.showsStatistics = true
        arView.debugOptions = [.showFeaturePoints]
        
        // start AR Session
        startARSession()
        
        // Add coaching overlay
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.center = arView.center
        arView.addSubview(coachingOverlay)
        
        arView.debugOptions = [.showFeaturePoints, .showAnchorOrigins, .showAnchorGeometry]
        
        if let screen = try? Entity.loadModel(named: "displayer", in: nil) {
            Logger.debug(screen)
        }
    }
}

extension RealityKitViewController {
    private func startARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            //showAlert(title: "ARKit is not available on this device.".localized, message: "This app requires world tracking, which is available only on iOS devices with the A9 processor or later.".localized)
            return
        }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        // remember to set this to false, or ARKit may conflict with Agora SDK
        configuration.providesAudioData = false

        // start session
        arView.session.run(configuration)
    }
}

extension RealityKitViewController {
}

// MARK: -
extension RealityKitViewController: ARSessionDelegate {
    @IBAction private func onSceneTapped(_ recognizer: UITapGestureRecognizer) {
        Logger.debug("onSceneTapped")
//        guard self.isPlanarDetected else {
//            return
//        }
        
        let location = recognizer.location(in: self.arView)
        Logger.debug("\(location)")
        
        // if hit screen
        // remove it
//        if let node = self.arView.hitTest(location, options: .featurePoint).first?.anchor {
//            Logger.debug("removeNode")
//        }
        
        if let query = self.arView.makeRaycastQuery(from: location, allowing: .estimatedPlane, alignment: .any) {
            let resultAnchor = self.arView.session.raycast(query).first?.anchor
//            arView.scene.addAnchor(Entity())
        }
//        let results = self.arView.raycast(from: location, allowing: .estimatedPlane, alignment: .any)
        
        // if hit nothing, add a screen
//        Logger.debug("location: \(location)")
//        Logger.debug("arView.center: \(arView.center)")
//        let query = self.arView.raycastQuery(from: arView.center, allowing: .estimatedPlane, alignment: .any)
//        Logger.debug("query?.direction: \(query?.direction)")
//        Logger.debug("query?.origin: \(query?.origin)")
//        let results = arView.session.raycast(query!)
//        if let a: ARRaycastResult = results.first {
//            Logger.debug("first point from ray cast query: \(a.worldTransform)")
//        }
//        if let result = self.arView.hitTest(location, types: .featurePoint).first {
//            let userSelectView = UIAlertController(title: "Select User", message: nil, preferredStyle: .actionSheet)
//            for uid in self.undisplayedUsers {
//                let action = UIAlertAction(title: "\(uid)", style: .default) { [weak self] action in
//                    //
//                    Logger.debug("addNode for user: \(uid) at \(result.worldTransform)")
//                    self?.addNode(withTransform: result.worldTransform, ofUser: uid)
//                }
//                userSelectView.addAction(action)
//            }
//            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
//                //.dismiss(animated: true, completion: nil)
//            }
//            userSelectView.addAction(cancelAction)
//            self.present(userSelectView, animated: true) {
//                // todo
//            }
//        }
        
//        let userSelectView = UIAlertController(title: "Select User", message: nil, preferredStyle: .actionSheet)
//
//        for uid in self.undisplayedUsers {
//            let action = UIAlertAction(title: "\(uid)", style: .default) { [weak self] action in
//                //
//                if let node = self?.arView.hitTest(location, options: nil).first?.node {
//                    Logger.debug("removeNode")
//                    self?.removeNode(node)
//                } else if let result = self?.arView.hitTest(location, types: .featurePoint).first {
//                    Logger.debug("addNode")
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
    private func addNode(withTransform transform: matrix_float4x4, ofUser uid: UInt) {
        if let screen = try? Entity.loadModel(named: "displayer", in: nil) {
            Logger.debug(screen)
        }
//        let scene = SCNScene(named: "AR.scnassets/displayer.scn")!
//        let rootNode = scene.rootNode
//
//        rootNode.position = SCNVector3(
//            transform.columns.3.x,
//            transform.columns.3.y,
//            transform.columns.3.z
//        )
//        rootNode.rotation = SCNVector4(0, 1, 0, arView.session.currentFrame!.camera.eulerAngles.y)
//
//        self.updateNodeUserLabel(uid: uid, node: rootNode)
//
//        arView.scene.addAnchor(rootNode)
//
//        userNodes[uid] = rootNode
//
//        let pos = [
//            NSNumber(value: transform.columns.3.x),
//            NSNumber(value: transform.columns.3.y),
//            NSNumber(value: transform.columns.3.z),
//        ]
//        userPositions[uid] = pos
//
//        self.agoraMgr.updatePosition(of: uid, position: pos)
//
//        self.updateDebugLabel()
//
//        if let idx = self.undisplayedUsers.firstIndex(of: uid) {
//            self.undisplayedUsers.remove(at: idx)
//            Logger.debug(self.undisplayedUsers)
//        }
    }
}

extension RealityKitViewController: AgoraManagerDelegate {
    func agoraMgr(_ mgr: AgoraManager, seat: UInt, selectedBy uid: UInt) {
        //
    }
    
    func agoraMgr(_ mgr: AgoraManager, seat: UInt, deselectedBy uid: UInt) {
        //
    }
    
    func agoraMgr(_ mgr: AgoraManager, userJoined uid: UInt) {
        //
        Logger.debug("User \(uid) joined.")
    }
    
    func agoraMgr(_ mgr: AgoraManager, userLeaved uid: UInt) {
        //
    }
    
    
}
