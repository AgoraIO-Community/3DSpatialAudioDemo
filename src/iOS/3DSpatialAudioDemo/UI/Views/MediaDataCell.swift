//
//  MediaDataCell.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/06/22.
//

import UIKit

class MediaDataCell: UICollectionViewCell {
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var uidLabel: UILabel!
    @IBOutlet private weak var playSwitch: UISwitch!
    
    var onSwitchChangeHandler: ((Bool) -> Void)?
    var media: MediaType! {
        didSet {
            self.nameLabel.text = "\(media.localizedName)"
            self.uidLabel.text = "\(media.localUid)"
        }
    }
    
    @IBAction private func onPlaySwitchChanged(_ sender: UISwitch?) {
        self.onSwitchChangeHandler?(sender?.isOn ?? false)
    }
}
