//
//  MultiMediaViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/06/22.
//

import UIKit
import DarkEggKit

class MultiMediaHostViewController: UIViewController {
    @IBOutlet private weak var channelNameLabel: UILabel!
    @IBOutlet private weak var mediaCollectionView: UICollectionView!
    @IBOutlet private weak var sendSelfVoiceSwitch: UISwitch!
    
    var channelName: String?
    var mediaList: [MediaType] = MediaType.allCases
    var playingMedia: [MediaType: Int] = [:]
    var isSendingToRemote: Bool = false
    
    let agoraMgr = AgoraManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.agoraMgr.delegate = self
        if let cName = self.channelName {
            self.channelNameLabel.text = cName
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.agoraMgr.leave()
    }
}

// MARK: - Actions
extension MultiMediaHostViewController {
    @IBAction private func onSendSelfVoiceSwitchChanged(_ sender: UISwitch) {
        Logger.debug()
        if sender.isOn {
            if let cName = self.channelName {
                self.channelNameLabel.text = cName
                self.agoraMgr.join(channel: cName, asHost: true) { (success, uid) in
                    if success {
                        Logger.debug("join channel \(cName) success: \(success), uid is \(uid)")
                        // reset self position
                        PositionManager.shared.resetSelfPosition()
                        //self.uidLabel.text = "user id: \(uid)"
                    }
                    else {
                        Logger.debug("join channel \(cName) failed.")
                        // show alert
                    }
                }
            }
        }
        else {
            self.agoraMgr.leave()
        }
    }
    
    @IBAction private func onSendToRemoteButtonClicked(_ sender: UIButton) {
        Logger.debug()
        if isSendingToRemote {
            //
            for media in self.playingMedia.keys {
                self.agoraMgr.stopSendMediaPlayer(media.localUid, fromChannel: self.channelName!)
            }
            self.isSendingToRemote = false
        }
        else {
            for media in self.playingMedia.keys {
                let localUid = media.localUid
                if let playerId = self.playingMedia[media] {
                    AgoraManager.shared.startSendMediaPlayer(playerId, localUid: localUid, name: media.data.name, ToChannel: self.channelName!)
                }
            }
            self.isSendingToRemote = true
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MultiMediaHostViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let screenWidth = UIScreen.main.bounds.width
        return CGSize(width: screenWidth/2 - 16.0, height: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: self.view.bounds.width, height: 0)
    }
}

// MARK: - UICollectionViewDataSource
extension MultiMediaHostViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mediaList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaDataCell", for: indexPath) as! MediaDataCell
        cell.layer.cornerRadius = 16
        cell.media = mediaList[indexPath.row]
        cell.onSwitchChangeHandler = {[weak self] (isON: Bool) -> Void in
            Logger.debug(cell.media.data.name)
            if isON {
                Logger.debug("Start player for media: \(cell.media.data.name)")
                var startPos = 0
                if let p = self?.agoraMgr.mediaPlayers.first?.value {
                    startPos = p.getPosition()
                }
                if let fpath = cell.media.data.path {
                    let localUid = cell.media.localUid
                    //AgoraManager.shared.createMediaPlayer(forFile: s.filePath!, at: [NSNumber(value: distanceX), NSNumber(value: distanceY), 0], startPosition: startPos) { [weak self] playerId in
                    AgoraManager.shared.createMediaPlayer(forFile: fpath, at: [0, 0, 0], startPosition: startPos) { [weak self] playerId in
                        //self?.playerSounds[localUid] = cell.media
                        self?.playingMedia[cell.media] = playerId
                        AgoraManager.shared.startSendMediaPlayer(playerId, localUid: localUid, name: cell.media.data.name, ToChannel: (self?.channelName)!)
                    }
                }
            }
            else {
                // stop
                if let playerId = self?.playingMedia[cell.media] {
                    Logger.debug("Stop player \(playerId), media: \(cell.media.data.name)")
                    AgoraManager.shared.removePlayer(id: playerId)
                    self?.agoraMgr.stopSendMediaPlayer(cell.media.localUid, fromChannel: (self?.channelName)!)
                    self?.playingMedia.removeValue(forKey: cell.media)
                }
            }
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension MultiMediaHostViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Logger.debug()
    }
}
