//
//  HeadphoneMotionVC.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/11/12.
//

import UIKit

import CoreMotion

class HeadphoneMotionVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
}

extension HeadphoneMotionVC {
    private func initMotionManager(completion: ((Bool) -> Void)?) {
        if #available(iOS 14.0, *) {
            let motionMgr = CMHeadphoneMotionManager()
            guard motionMgr.isDeviceMotionActive else {
                completion?(false)
                return
            }
            completion?(true)
        } else {
            // Fallback on earlier versions
            completion?(false)
        }
    }
}
