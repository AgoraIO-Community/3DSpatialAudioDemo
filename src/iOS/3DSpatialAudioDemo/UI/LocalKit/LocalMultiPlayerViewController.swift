//
//  LocalMultiPlayerViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/01/19.
//

import UIKit
import CoreMotion
import DarkEggKit

class LocalMultiPlayerViewController: UIViewController {
    // MARK: - UI
    @IBOutlet weak var channelLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var uidLabel: UILabel!
    @IBOutlet weak var sendToRemoteSwitch: UISwitch!
    @IBOutlet weak var debugLabel: UILabel!
    // head motion
    @IBOutlet weak var headMotionSwitch: UISwitch!
    @IBOutlet weak var headMotionSegment: UISegmentedControl!
    
    private var playerViews: [Int: UILabel] = [:]
    
    // MARK: - Properties
    var channelName: String?
    var isHost: Bool = true
    let agoraMgr = AgoraManager.shared
    
    var playerSounds: [Int: Sound] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.agoraMgr.delegate = self
        self.debugLabel.font = UIFont.monospacedSystemFont(ofSize: 12.0, weight: .medium)
        
        // check head motion
        if #available(iOS 14.0, *) {
            HeadMotionManager.shared.checkAvailable({ ret in
                self.headMotionSwitch.isEnabled = ret
                if ret {
                    //self.headMotionLabel.text = "Head Motion"
                    HeadMotionManager.shared.delegate = self
                }
                else {
                    self.showAlert(title: "Error", message: "Head Motion is Disabled.")
                    //self.headMotionLabel.text = "Head Motion is Disabled"
                }
            })
        } else {
            self.showAlert(title: "Error", message: "Need iOS version >= 14.0")
            // Fallback on earlier versions
            self.headMotionSwitch.isEnabled = false
//            self.headMotionLabel.text = "Need more than iOS 14"
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let cName = self.channelName {
            self.channelLabel.text = cName
            self.agoraMgr.join(channel: cName, asHost: self.isHost) { (success, uid) in
                if success {
                    Logger.debug("join channel \(cName) success: \(success), uid is \(uid)")
                    // reset self position
                    PositionManager.shared.resetSelfPosition()
                    self.uidLabel.text = "user id: \(uid)"
                }
                else {
                    Logger.debug("join channel \(cName) failed.")
                    // show alert
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.agoraMgr.delegate = nil
        self.agoraMgr.leave()
    }
}

extension LocalMultiPlayerViewController {
    @IBAction private func onSendToRemoteSwitchChanged(_ sender: UISwitch) {
        Logger.debug()
        if sender.isOn {
            for playerId in self.playerViews.keys {
//                self.agoraMgr.publishMediaPlayer(sender.isOn, playerId: playerId)
                self.agoraMgr.startSendMediaPlayer(playerId, name: "Player\(playerId)", ToChannel: self.channelName!)
            }
        }
    }
    
    @IBAction private func onTapped(_ sender: UITapGestureRecognizer) {
        let point = sender.location(in: self.view)
        Logger.debug(self.userLabel.center)
        Logger.debug(point)
        let distanceX = point.x.distance(to: self.userLabel.center.x)/100 * -1
        let distanceY = point.y.distance(to: self.userLabel.center.y)/100
        
        Logger.debug("distanceX: \(distanceX), distanceY: \(distanceY)")
        let soundSelectView = UIAlertController(title: "Select Sound", message: nil, preferredStyle: .actionSheet)
        
//        guard
        
        if let p = self.findTappedPlayer(byPoint: point),
           let player = self.agoraMgr.getPlayer(by:  p.0) {
            // change the sound
            //let label = p.1
            
            for s in Sound.allCases {
                let action = UIAlertAction(title: s.rawValue, style: .default) { [weak self] action in
                    //
                    self?.playerSounds[p.0] = s
                    player.stop()
                    player.open(s.filePath!, startPos: 0)
                    player.play()
                    self?.printDebugLog()
                }
                soundSelectView.addAction(action)
            }
            
            let removeAction = UIAlertAction(title: "Remove it", style: .destructive) { action in
                let pId = p.0
                self.playerViews.removeValue(forKey: pId)
                p.1.removeFromSuperview()
                self.agoraMgr.removePlayer(id: pId)
                self.playerSounds.removeValue(forKey: pId)
                self.printDebugLog()
            }
            soundSelectView.addAction(removeAction)
        }
        else {
            for s in Sound.allCases {
                let action = UIAlertAction(title: s.rawValue, style: .default) { action in
                    //
                    var startPos = 0
                    if let p = self.agoraMgr.mediaPlayers.first?.value {
                        startPos = p.getPosition()
                    }
                    AgoraManager.shared.createMediaPlayer(forFile: s.filePath!, at: [NSNumber(value: distanceX), NSNumber(value: distanceY), 0], startPosition: startPos) { [weak self] playerId in
                        self?.playerSounds[playerId] = s
                        // add player icon
                        let playerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                        self?.view.addSubview(playerLabel)
                        playerLabel.center = point
                        playerLabel.clipsToBounds = true
                        playerLabel.textAlignment = .center
                        playerLabel.backgroundColor = .systemOrange
                        playerLabel.layer.cornerRadius = 20
                        playerLabel.layer.cornerCurve = .circular
                        playerLabel.text = "\(playerId)"
                        // save player view
                        self?.playerViews[playerId] = playerLabel
                        self?.printDebugLog()
                    }
                }
                soundSelectView.addAction(action)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            //.dismiss(animated: true, completion: nil)
        }
        soundSelectView.addAction(cancelAction)
        
        self.present(soundSelectView, animated: true) {
            //
        }
    }
    
    private func findTappedPlayer(byPoint point: CGPoint) -> (Int, UILabel)? {
        let p = self.playerViews.first { body in
            if body.value.frame.contains(point) {
                return true
            }
            return false
        }
        return p
    }
    
    private func onMove(_ sender: UIPanGestureRecognizer) {
        sender.translation(in: self.view)
    }
}

@available(iOS 14.0, *)
extension LocalMultiPlayerViewController: HeadMotionManagerDelegate {
    @IBAction private func onHeadMotionSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            HeadMotionManager.shared.startHeadMotion { result in
                Logger.debug("startHeadMotion: \(result)")
                // disable segment
                self.headMotionSegment.isEnabled = !result
            }
        }
        else {
            HeadMotionManager.shared.stopHeadMotion()
            PositionManager.shared.resetSelfPosition()
            self.headMotionSegment.isEnabled = true
        }
    }
    
    @IBAction private func onHeadMotionSegmentChanged(_ sender: UISegmentedControl) {
        var angle: CGFloat = 0.0
        switch sender.selectedSegmentIndex {
        case 0: // forward
            angle = 0.0
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
            break
        case 1: // left
            angle = -CGFloat.pi/2
            self.agoraMgr.updateSelfPosition(
                position: [
                    NSNumber(value: 0),
                    NSNumber(value: 0),
                    NSNumber(value: 0)
                ], forward: [
                    NSNumber(value: -1),
                    NSNumber(value: 0),
                    NSNumber(value: 0)
                ], right: [
                    NSNumber(value: 0),
                    NSNumber(value: 1),
                    NSNumber(value: 0)
                ], up: [
                    NSNumber(value: 0),
                    NSNumber(value: 0),
                    NSNumber(value: 1)
            ])
            break
        case 2: // back
            angle = CGFloat.pi
            self.agoraMgr.updateSelfPosition(
                position: [
                    NSNumber(value: 0),
                    NSNumber(value: 0),
                    NSNumber(value: 0)
                ], forward: [
                    NSNumber(value: 0),
                    NSNumber(value: -1),
                    NSNumber(value: 0)
                ], right: [
                    NSNumber(value: -1),
                    NSNumber(value: 0),
                    NSNumber(value: 0)
                ], up: [
                    NSNumber(value: 0),
                    NSNumber(value: 0),
                    NSNumber(value: 1)
            ])
            break
        case 3: // right
            angle = CGFloat.pi/2
            self.agoraMgr.updateSelfPosition(
                position: [
                    NSNumber(value: 0),
                    NSNumber(value: 0),
                    NSNumber(value: 0)
                ], forward: [
                    NSNumber(value: 1),
                    NSNumber(value: 0),
                    NSNumber(value: 0)
                ], right: [
                    NSNumber(value: 0),
                    NSNumber(value: -1),
                    NSNumber(value: 0)
                ], up: [
                    NSNumber(value: 0),
                    NSNumber(value: 0),
                    NSNumber(value: 1)
            ])
            break
        default:
            break
        }
        self.rotateUser(to: angle)
    }
    
    private func rotateUser(to angle: CGFloat) {
        UIView.animate(withDuration: 0.33, delay: 0.0, options: .curveEaseInOut) {
            self.userLabel.transform = CGAffineTransform(rotationAngle: angle)
        } completion: { finished in
            //
        }
    }
    
    func headMotionMgr(_ mgr: HeadMotionManager, startFailed: Error?) {
        self.showAlert(title: "Error", message: "Start head motion error.")
    }
    
    func headMotionMgr(_ mgr: HeadMotionManager, motion: CMDeviceMotion?) {
        //Logger.debug("\(motion?.rotationRate)")
        Logger.debug("\(String(describing: motion?.attitude.quaternion))")
        let x = motion?.attitude.quaternion.x ?? 0
        let y = motion?.attitude.quaternion.y ?? 0
        let z = motion?.attitude.quaternion.z ?? 0
        let w = motion?.attitude.quaternion.w ?? 0
        
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
        f: [\(String (format:  "%.2f" ,forwordX)),\(String (format:  "%.2f" ,forwordY)),\(String (format:  "%.2f" ,forwordZ))]
        r: [\(String (format:  "%.2f" ,rightX)),\(String (format:  "%.2f" , rightY)),\(String (format:  "%.2f" ,rightZ))]
        u: [\(String (format:  "%.2f" ,upX)),\(String (format:  "%.2f" ,upY)),\(String (format:  "%.2f" ,upZ))]
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

extension LocalMultiPlayerViewController {
    private func sendPlayer(plyerId: Int) {
        // 
    }
}

extension LocalMultiPlayerViewController {
    func printDebugLog() {
        var str = "Debug\r\nMediaPlayer   | Sound"
        self.playerSounds.forEach { body in
            str += "\r\nplayer \(body.key)      | \(body.value.rawValue)"
        }
        self.debugLabel.text = str
    }
}

extension LocalMultiPlayerViewController: AgoraManagerDelegate {
    func agoraMgr(_ mgr: AgoraManager, userJoined uid: UInt) {
        Logger.debug("user \(uid) joined, add to remote user list")
        PositionManager.shared.changeSeat(ofUser: uid, to: 4)
        return
    }
    
    func agoraMgr(_ mgr: AgoraManager, userLeaved uid: UInt) {
        Logger.debug("user \(uid) leaved, remove from remote user list")
    }
}
