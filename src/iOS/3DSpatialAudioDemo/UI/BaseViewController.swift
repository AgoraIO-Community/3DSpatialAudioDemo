//
//  BaseViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/03/24.
//

import UIKit

class BaseViewController: UIViewController {
    var channelName: String?
    var isHost: Bool = false
    let agoraMgr = AgoraManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Common functions
    func showWarningAlert(title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let canncelAction = UIAlertAction(title: "OK", style: .cancel) { action in
            //
        }
        alert.addAction(canncelAction)
        self.present(alert, animated: true) {
            //
        }
    }
}
