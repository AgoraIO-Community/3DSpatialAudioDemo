//
//  HostViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/11/09.
//

import UIKit
import DarkEggKit

class HostViewController: UIViewController {
    // MARK: - Control
    @IBOutlet weak var channelNameLabel: UILabel!
    @IBOutlet weak var uidLabel: UILabel!
    @IBOutlet weak var videoSwitch: UISwitch!
    @IBOutlet weak var audioMixingSwitch: UISwitch!
    @IBOutlet weak var audioMixingSegment: UISegmentedControl!
    @IBOutlet weak var loaclVideoView: UIView!
    
    // MARK: - Properties
    var channelName: String?
    let agoraMgr = AgoraManager.shared
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.agoraMgr.delegate = self
        if let cName = self.channelName {
            self.channelNameLabel.text = cName
            self.agoraMgr.join(channel: cName, asHost: true) { (success, uid) in
                if success {
                    Logger.debug("Join channel \(cName) success: \(success), uid is \(uid).")
                    self.uidLabel.text = "user id: \(uid)"
                    // reset self position
                    PositionManager.shared.resetSelfPosition()
                }
                else {
                    Logger.debug("Join channel \(cName) failed.")
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.agoraMgr.delegate = nil
        self.agoraMgr.leave()
    }
    
    func onVideoStateChanged() {
        // when the video is on, show preview
    }
}

extension HostViewController {
    @IBAction private func onVideoSwitchChanged(_ sender: UISwitch) {
        let videoOn = sender.isOn
        // turn the video
        self.agoraMgr.switchVideo(videoOn)
        if videoOn {
            self.agoraMgr.setLocalVideoPreview(in: self.loaclVideoView)
        }
        else {
            self.agoraMgr.removeLocalVideoPreview()
        }
    }
    
    /// AudioMixingSwitch value changed event handle
    /// - Parameter sender: UISwitch
    @IBAction private func onAudioMixingSwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            self.agoraMgr.startAudioMixing(soundType: audioMixingSegment.titleForSegment(at: audioMixingSegment.selectedSegmentIndex) ?? "", completion: { ret in
                // completion function
            })
        } else {
            self.agoraMgr.stopAudioMixing()
        }
    }
    
    /// AudioMixingSegment value changed event handle
    /// - Parameter sender: UISegmentedControl
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

extension HostViewController: AgoraManagerDelegate {
    func agoraMgr(_ mgr: AgoraManager, userJoined uid: UInt) {
        // set to default seat
        // enable to hear other host
        Logger.debug("User \(uid) joined, add to remote user list")
        PositionManager.shared.changeSeat(ofUser: uid, to: 4)
    }
    
    func agoraMgr(_ mgr: AgoraManager, userLeaved uid: UInt) {
        Logger.debug("User \(uid) leaved.")
    }
}
