//
//  NineSeatCloudHotstViewController.swift
//  Radio3DAudioSample
//
//  Created by Yuhua Hu on 2022/02/28.
//

import UIKit
import DarkEggKit
import Contacts
import PromiseKit
import AgoraRtmKit
import MBProgressHUD

class NineSeatCloudViewController: UIViewController {
    @IBOutlet weak var seat0_0: Seat!
    @IBOutlet weak var seat0_1: Seat!
    @IBOutlet weak var seat0_2: Seat!
    @IBOutlet weak var seat1_0: Seat!
    @IBOutlet weak var seat1_1: Seat!
    @IBOutlet weak var seat1_2: Seat!
    @IBOutlet weak var seat2_0: Seat!
    @IBOutlet weak var seat2_1: Seat!
    @IBOutlet weak var seat2_2: Seat!
//
    @IBOutlet weak var channelLabel: UILabel!
    @IBOutlet weak var uidLabel: UILabel!
    
    // audio mixing (for host)
    @IBOutlet weak var audioMixingTitleLabel: UILabel!
    @IBOutlet weak var audioMixingArea: UIView!
    @IBOutlet weak var audioMixingSwitch: UISwitch!
    @IBOutlet weak var audioMixingSegment: UISegmentedControl!
    
    @IBOutlet weak var messageField: UITextField!
    
    var timer: Timer? // cloud kit must update self position for every 120ms - 7sec
    
    var channelName: String?
    var isHost: Bool = false
    
    var selfUid: UInt? = nil
    var selfSeatIndex = -1
    var remoteUsers: [UInt: Int] = [:]
    var seats: [Seat] = []

    var agoraMgr: AgoraManager = AgoraManager.shared
    
    var rtmChannel: AgoraRtmChannel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        self.audioMixingTitleLabel.isHidden = !isHost
        self.audioMixingArea.isHidden = !isHost
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let progress = MBProgressHUD.showAdded(to: self.view, animated: true)
        if let cName = self.channelName {
            self.agoraMgr.delegate = self
            self.channelLabel.text = cName
            progress.label.text = "Join agora rtc channel..."
            self.agoraMgr.joinPromise(channel: cName, asHost: isHost).then ({ [weak self] uid -> Promise<AgoraRtmLoginErrorCode> in
                self?.selfUid = uid
                self?.uidLabel.text = "user id: \(uid)"
                progress.label.text = "Login to agora rtm server..."
                self?.agoraMgr.switchVideo(self?.isHost ?? false)
                return AgoraRtmManager.shared.loginPromise("\(uid)")
            }).then({ code -> Promise<AgoraRtmChannel> in
                Logger.debug("rtm login success.")
                progress.label.text = "Join agora rtm channel..."
                return AgoraRtmManager.shared.joinChannelPromise(cName)
            }).done({ [weak self] channel in
                // end
                self?.rtmChannel = channel
                PositionManager.shared.resetSelfPosition(mode: .cloud)
                Logger.debug("rtm join channel success.")
                AgoraRtmManager.shared.delegate = self
                // start timer
                self?.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in // cloud kit must update self position for every 120ms - 7sec
                    //Logger.debug("Timer fires.")
                    if let flag = self?.isHost, flag {
                        PositionManager.shared.changeSelfSeat(self?.selfSeatIndex ?? -1, mode: .cloud)
                    }
                    else {
                        Logger.debug("resetSelfPosition")
                        PositionManager.shared.resetSelfPosition()
                    }
                })
            }).catch { error in
                Logger.error(error.localizedDescription)
            }.finally {
                //
                progress.hide(animated: false)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.timer?.invalidate()
        self.timer = nil
        self.agoraMgr.leave()
        AgoraRtmManager.shared.leave()
        super.viewDidDisappear(animated)
    }
}

// for host
extension NineSeatCloudViewController {
    @IBAction func onSeatClicked(_ sender: Seat) {
        Logger.debug("Seat \(sender.tag) selected")
        selectSeat(sender)
    }
    
    private func selectSeat(_ seat: Seat) {
        guard self.isHost else {
            return
        }
        // check seat
        guard seat.uid == nil else {
            let alert = UIAlertController(title: "Error", message: "This seat is already taked by \(seat.uid ?? 0)", preferredStyle: .alert)
            let canncelAction = UIAlertAction(title: "OK", style: .cancel) { action in
                //
            }
            alert.addAction(canncelAction)
            self.present(alert, animated: true) {
                //
            }
            return
        }
        
        // take seat
        // show local preview in the seat
        showVideo(onSeat: seat)
        self.selfSeatIndex = seat.tag
        PositionManager.shared.changeSelfSeat(seat.tag, mode: .cloud)
        
        // send seat index with rtm
        if let uid = self.selfUid {
            //PositionManager.shared.changeSeat(ofUser: uid, to: seat.tag)
            AgoraRtmManager.shared.sendUser(uid, seatIndex: seat.tag)
        }
    }
    
    private func showVideo(uid: UInt = 0, onSeat seat: Seat) {
        if uid == 0 {
            // self preview
            self.agoraMgr.setLocalVideoPreview(in: seat.avatarView)
        }
        else {
            Logger.debug("dddd")
            self.agoraMgr.setRemoteVideoView(seat.avatarView, forUser: uid)
        }
    }
    
    //
    @IBAction func onSendButtonclicked(_ sender: UIButton) {
        self.rtmChannel?.send(AgoraRtmMessage(text: "aaa"), sendMessageOptions: AgoraRtmSendMessageOptions(), completion: { error in
            Logger.debug(error.rawValue)
        })
        AgoraRtmManager.shared.sendMessage("test message")
    }
    
    /// View tap event handle
    /// Hide the keyboard
    /// - Parameter sender: View
    @IBAction private func onViewTapped(_ sender: UITapGestureRecognizer) {
        self.messageField.endEditing(true)
    }
    
    /// AudioMixingSwitch value changed event handle
    /// - Parameter sender: AudioMixingSwitch
    @IBAction private func onAudioMixingSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            self.agoraMgr.startAudioMixing(soundType: audioMixingSegment.titleForSegment(at: audioMixingSegment.selectedSegmentIndex) ?? "", completion: { ret in
                //
            })
        } else {
            self.agoraMgr.stopAudioMixing()
        }
    }
    
    /// AudioMixingSegment vaule changed event handle
    /// - Parameter sender: AudioMixingSegment
    @IBAction private func onAudioMixingSegmentChanged(_ sender: UISegmentedControl) {
        guard self.audioMixingSwitch.isOn else {
            return
        }
        if let soundName = sender.titleForSegment(at: sender.selectedSegmentIndex) {
            self.agoraMgr.startAudioMixing(soundType: soundName, completion: { ret in
                //
            })
        }
    }
}

// MARK: - AgoraManagerDelegate
extension NineSeatCloudViewController: AgoraManagerDelegate {
    func agoraMgr(_ mgr: AgoraManager, userJoined uid: UInt) {
        //
        Logger.debug("User \(uid) joined")
        self.showVideo(uid: uid, onSeat: seat0_0)
    }
    
    func agoraMgr(_ mgr: AgoraManager, userLeaved uid: UInt) {
        //
        Logger.debug("User \(uid) leaved")
    }
}

// MARK: - AgoraRtmManagerDelegate
extension NineSeatCloudViewController: AgoraRtmManagerDelegate {
    func rtmMgr(_ mgr: AgoraRtmManager, onReciveSeat seatIndex: Int, fromUser uid: UInt) {
        // seat remote user seat
        Logger.debug("user \(uid) take seat \(seatIndex)")
        self.showVideo(uid: uid, onSeat:  self.seats[seatIndex])
    }
}
