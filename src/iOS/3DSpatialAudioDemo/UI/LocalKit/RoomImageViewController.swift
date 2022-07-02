//
//  RoomImageViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/11/11.
//

import UIKit
import CoreMotion
import DarkEggKit

class RoomImageViewController: UIViewController {
    @IBOutlet weak var Seat01: UIButton!
    @IBOutlet weak var SeatLabel01: UILabel!
    @IBOutlet weak var Seat02: UIButton!
    @IBOutlet weak var SeatLabel02: UILabel!
    @IBOutlet weak var Seat03: UIButton!
    @IBOutlet weak var SeatLabel03: UILabel!
    @IBOutlet weak var Seat04: UIButton!
    @IBOutlet weak var SeatLabel04: UILabel!
    
    @IBOutlet weak var headMotionArea: UIStackView!
    @IBOutlet weak var headMotionLabel: UILabel!
    @IBOutlet weak var headMotionSwitch: UISwitch!
    
    @IBOutlet weak var debugLabel: UILabel!
    
    private var remoteUsers: [UInt: Int] = [:]
    
    var positions: [Int: [NSNumber]] = [
        0: [-1.5, 0.0, 0.0],
        1: [-0.8, -0.8, 0.0],
        2: [1.4, 1.0, 0.0],
        3: [1.5, -0.3, 0.0]
    ]
    var userButtons: [UInt: UIButton] = [:]
    
    let agoraMgr = AgoraManager.shared
    var channelName: String?
    var isHost: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.agoraMgr.delegate = self
        if let cName = self.channelName {
            //self.channelLabel.text = cName
            self.agoraMgr.join(channel: cName, asHost: self.isHost) { (success, uid) in
                //
                if success {
                    Logger.debug("join \(cName) as \(uid) success: \(success)")
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
                }
                
            }
        }
        
        // check head motion
        if #available(iOS 14.0, *) {
            HeadMotionManager.shared.checkAvailable({ ret in
                self.headMotionSwitch.isEnabled = ret
                //self.headMotionArea.isHidden = !ret
                if ret {
                    self.headMotionLabel.text = "Head Motion"
                    HeadMotionManager.shared.delegate = self
                }
                else {
                    self.headMotionLabel.text = "Head Motion is Disabled"
                }
            })
        } else {
            // Fallback on earlier versions
            self.headMotionSwitch.isHidden = true
            self.headMotionLabel.text = "Need more than iOS 14"
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if #available(iOS 14.0, *) {
            HeadMotionManager.shared.stopHeadMotion()
        } else {
            // Fallback on earlier versions
        }
        
        self.agoraMgr.delegate = nil
        self.agoraMgr.leave()
        
        super.viewWillDisappear(animated)
    }
}

extension RoomImageViewController {
    @IBAction private func onSeatClicked(_ sender: UIButton) {
        let tag = sender.tag
        //let pos = positions[tag]
        // set the remote user position
        
        let userSelectView = UIAlertController(title: "Select User", message: nil, preferredStyle: .actionSheet)
        for uid in self.remoteUsers.keys {
            let action = UIAlertAction(title: "\(uid)", style: .default) { [weak self] action in
                if let pos = self?.positions[tag] {
                    self?.agoraMgr.setHostPosition(UInt(uid), position: pos)
                    if self?.userButtons.keys.contains(uid) ?? false {
                        self?.userButtons[uid]?.setTitle("\(tag): ", for: .normal)
                    }
                    self?.userButtons[uid] = sender
                    sender.setTitle("\(tag): \(uid)", for: .normal)
                }
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
    
    @IBAction private func onDirectionChanged(_ sender: UISegmentedControl) {
        var forwardX = 0.0
        var forwardY = 1.0
        var forwardZ = 0.0

        var rightX = 1.0
        var rightY = 0.0
        var rightZ = 0.0

        var upX = 0.0
        var upY = 0.0
        var upZ = 1.0
        
        switch sender.selectedSegmentIndex {
        case 0: //forward
            forwardX = 0.0
            forwardY = 1.0
            forwardZ = 0.0

            rightX = 1.0
            rightY = 0.0
            rightZ = 0.0

            upX = 0.0
            upY = 0.0
            upZ = 1.0
            break
        case 1: // left
            forwardX = -1.0
            forwardY = 0.0
            forwardZ = 0.0

            rightX = 0.0
            rightY = 1.0
            rightZ = 0.0

            upX = 0.0
            upY = 0.0
            upZ = 1.0
            break
        case 2: // back
            forwardX = -1.0
            forwardY = 0.0
            forwardZ = 0.0

            rightX = 0.0
            rightY = -1.0
            rightZ = 0.0

            upX = 0.0
            upY = 0.0
            upZ = 1.0
            break
        case 3: // right
            forwardX = 1.0
            forwardY = 0.0
            forwardZ = 0.0

            rightX = 0.0
            rightY = -1.0
            rightZ = 0.0

            upX = 0.0
            upY = 0.0
            upZ = 1.0
            break
        default: // forward
            break
        }
        
        self.agoraMgr.updateSelfPosition(
            position: [
                NSNumber(value: 0),
                NSNumber(value: 0),
                NSNumber(value: 0)
            ], forward: [
                NSNumber(value: forwardX),
                NSNumber(value: forwardY),
                NSNumber(value: forwardZ)
            ], right: [
                NSNumber(value: rightX),
                NSNumber(value: rightY),
                NSNumber(value: rightZ)
            ], up: [
                NSNumber(value: upX),
                NSNumber(value: upY),
                NSNumber(value: upZ)
        ])
        
        let debugMsg = """
        forword: [\(String (format:  "%+.2f" ,forwardX)),\(String (format:  "%+.2f" ,forwardY)),\(String (format:  "%+.2f" ,forwardZ))]
        right: [\(String (format:  "%+.2f" ,rightX)),\(String (format:  "%+.2f" , rightY)),\(String (format:  "%+.2f" ,rightZ))]
        up: [\(String (format:  "%+.2f" ,upX)),\(String (format:  "%+.2f" ,upY)),\(String (format:  "%+.2f" ,upZ))]
        """
        self.debugLabel.text = debugMsg
    }
}

@available(iOS 14.0, *)
extension RoomImageViewController: HeadMotionManagerDelegate {
    @IBAction private func onHeadMotionSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            HeadMotionManager.shared.startHeadMotion { result in
                Logger.debug("startHeadMotion: \(result)")
            }
        }
        else {
            HeadMotionManager.shared.stopHeadMotion()
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
        }
    }
    
    func headMotionMgr(_ mgr: HeadMotionManager, startFailed: Error?) {
        
    }
    
    func headMotionMgr(_ mgr: HeadMotionManager, motion: CMDeviceMotion?) {
        //Logger.debug("\(motion?.rotationRate)")
        Logger.debug("\(String(describing: motion?.attitude.quaternion))")
        let x = motion?.attitude.quaternion.x ?? 0
        let y = motion?.attitude.quaternion.y ?? 0
        let z = motion?.attitude.quaternion.z ?? 0
        let w = motion?.attitude.quaternion.w ?? 0
        
//        if let uid = self.userButtons.keys.first {
//            self.agoraMgr.setHostPosition(UInt(uid), position: [-1.5, 0.0, 0.0])
//        }
        
        let forwordX = (2*x*y-2*z*w)
        let forwordY = (1-2*x*x-2*z*z)
        let forwordZ = (2*y*z+2*x*w)

        let rightX = (1-2*y*y-2*z*z)
        let rightY = (2*x*y+2*z*w)
        let rightZ = (2*x*z-2*y*w)

        let upX = (2*x*z+2*y*w)
        let upY = (2*y*z-2*x*w)
        let upZ = (1-2*x*x-2*y*y)
        
        let debugMsg = """
        forword: [\(String (format:  "%.2f" ,forwordX)),\(String (format:  "%.2f" ,forwordY)),\(String (format:  "%.2f" ,forwordZ))]
        right: [\(String (format:  "%.2f" ,rightX)),\(String (format:  "%.2f" , rightY)),\(String (format:  "%.2f" ,rightZ))]
        up: [\(String (format:  "%.2f" ,upX)),\(String (format:  "%.2f" ,upY)),\(String (format:  "%.2f" ,upZ))]
        """
        self.debugLabel.text = debugMsg
        
        self.agoraMgr.updateSelfPosition(
            position: [
                NSNumber(value: 0),
                NSNumber(value: 0),
                NSNumber(value: 0)
            ], forward: [
                NSNumber(value: forwordX),
                NSNumber(value: forwordY),
                NSNumber(value: forwordZ)
            ], right: [
                NSNumber(value: rightX),
                NSNumber(value: rightY),
                NSNumber(value: rightZ)
            ], up: [
                NSNumber(value: upX),
                NSNumber(value: upY),
                NSNumber(value: upZ)
        ])
    }
}

extension RoomImageViewController: AgoraManagerDelegate {
    func agoraMgr(_ mgr: AgoraManager, userJoined uid: UInt) {
        Logger.debug("user \(uid) joined, add to remote user list")
        guard self.remoteUsers.keys.contains(uid) else {
            // new user,
            self.remoteUsers[uid] = -1
            //PositionManager.shared.changeSeat(ofUser: uid, to: -1)
            return
        }
    }
    
    func agoraMgr(_ mgr: AgoraManager, userLeaved uid: UInt) {
        Logger.debug("user \(uid) leaved, remove from remote user list")
        if self.remoteUsers.keys.contains(uid) {
            self.remoteUsers.removeValue(forKey: uid)
        }
    }
}
