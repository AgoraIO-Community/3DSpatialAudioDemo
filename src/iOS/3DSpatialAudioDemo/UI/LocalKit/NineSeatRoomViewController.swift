//
//  RoomViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/10/14.
//

import UIKit

class NineSeatRoomViewController: UIViewController {
    // only for audience
    @IBOutlet weak var seat0_0: Seat!
    @IBOutlet weak var seat0_1: Seat!
    @IBOutlet weak var seat0_2: Seat!
    @IBOutlet weak var seat1_0: Seat!
    @IBOutlet weak var seat1_1: Seat!
    @IBOutlet weak var seat1_2: Seat!
    @IBOutlet weak var seat2_0: Seat!
    @IBOutlet weak var seat2_1: Seat!
    @IBOutlet weak var seat2_2: Seat!
    
    @IBOutlet weak var channelLabel: UILabel!
    @IBOutlet weak var uidLabel: UILabel!
    
    var channelName: String?
    var isHost: Bool = false
    
    var remoteUsers: [UInt: Int] = [:]
    var seats: [Seat] = []
    
    let agoraMgr = AgoraManager.shared
    
    override func viewDidLoad() {
        self.seats = [self.seat0_0, self.seat0_1, self.seat0_2,
                      self.seat1_0, self.seat1_1, self.seat1_2,
                      self.seat2_0, self.seat2_1, self.seat2_2]
        
        self.seat0_0.tag = 0
        self.seat0_1.tag = 1
        self.seat0_2.tag = 2
        self.seat1_0.tag = 3
        self.seat1_1.tag = 4
        self.seat1_2.tag = 5
        self.seat2_0.tag = 6
        self.seat2_1.tag = 7
        self.seat2_2.tag = 8
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.agoraMgr.delegate = self
        if let cName = self.channelName {
            self.channelLabel.text = cName
            self.agoraMgr.join(channel: cName, asHost: self.isHost) { (success, uid) in
                if success {
                    print("join channel \(cName) success: \(success), uid is \(uid)")
                    // reset self position
                    PositionManager.shared.resetSelfPosition()
                    self.uidLabel.text = "user id: \(uid)"
                }
                else {
                    print("join channel \(cName) failed.")
                    // show alert
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.agoraMgr.delegate = nil
        self.agoraMgr.leave()
    }

    deinit {
        print("dddd")
    }
}

extension NineSeatRoomViewController {
//    @IBAction func onCloseButtonClicked(_ sender: UIButton) {
//        self.dismiss(animated: true) {
//            self.agoraMgr.leave()
//        }
//    }
    
    @IBAction func onSeatClicked(_ sender: Seat) {
        print("\(sender.tag)")
        setRemoteHostSeat(sender)
    }
    
    func setRemoteHostSeat(_ seat: Seat) {
        let userSelectView = UIAlertController(title: "Select User", message: nil, preferredStyle: .actionSheet)
        
        for uid in self.remoteUsers.keys {
            guard (self.remoteUsers[uid] ?? -1) < 0 else {
                continue
            }
            let action = UIAlertAction(title: "\(uid)", style: .default) { [weak self] action in
                PositionManager.shared.changeSeat(ofUser: uid, to: seat.tag)
                for s in self?.seats ?? [] {
                    guard (s.uid ?? 0) == uid else {
                        continue
                    }
                    s.uid = nil
                }
                seat.uid = uid
                self?.agoraMgr.setRemoteVideoView(seat.avatarView, forUser: uid)
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
}

extension NineSeatRoomViewController: AgoraManagerDelegate {
    func agoraMgr(_ mgr: AgoraManager, userJoined uid: UInt) {
        print("user \(uid) joined, add to remote user list")
        guard self.remoteUsers.keys.contains(uid) else {
            // new user,
            self.remoteUsers[uid] = -1
            PositionManager.shared.changeSeat(ofUser: uid, to: -1)
            return
        }
    }
    
    func agoraMgr(_ mgr: AgoraManager, userLeaved uid: UInt) {
        print("user \(uid) leaved, remove from remote user list")
        if self.remoteUsers.keys.contains(uid) {
            self.remoteUsers.removeValue(forKey: uid)
        }
    }
}
