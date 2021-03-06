//
//  HeadMotionManager.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/11/12.
//

import Foundation
import CoreMotion
import DarkEggKit

@available(iOS 14.0, *)
protocol HeadMotionManagerDelegate: AnyObject {
    func headMotionMgr(_ mgr: HeadMotionManager, motion: CMDeviceMotion?)
    func headMotionMgr(_ mgr: HeadMotionManager, startFailed: Error?)
}

@available(iOS 14.0, *)
class HeadMotionManager: NSObject {
    static let shared: HeadMotionManager = { HeadMotionManager()}()
    
    lazy var available: Bool = {
        guard self.motionMgr.isDeviceMotionAvailable else {
            Logger.debug("isDeviceMotion Available: false")
            return false
        }
        guard self.motionMgr.isDeviceMotionActive else {
            Logger.debug("isDeviceMotion Active: false")
            return false
        }
        return true
    }()
    
    let motionMgr = CMHeadphoneMotionManager()
    weak var delegate: HeadMotionManagerDelegate?
    
    override init() {
        CMHeadphoneMotionManager.authorizationStatus()
    }
    
    func checkAvailable(_ completion: ((Bool) -> Void)) {
        var result = false
        switch CMHeadphoneMotionManager.authorizationStatus() {
        case .authorized:
            Logger.debug("User previously allowed motion tracking")
            result = true
        case .restricted:
            Logger.debug("User access to motion updates is restricted")
        case .denied:
            Logger.debug("User denied access to motion updates; will not start motion tracking")
        case .notDetermined:
            Logger.debug("Permission for device motion tracking unknown; will prompt for access")
        default:
            break
        }
        
        completion(result)
    }
}

@available(iOS 14.0, *)
extension HeadMotionManager {
    /// Start head motion
    func startHeadMotion(completion: ((Bool)->Void)) {
        guard !motionMgr.isDeviceMotionActive else { 
            completion(true)
            return
        }
        
        self.motionMgr.delegate = self
        self.motionMgr.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            if let err = error {
                Logger.debug("Error: \(err.localizedDescription)")
                return
            }
            // update
            if let mgr = self {
                mgr.delegate?.headMotionMgr(mgr, motion: motion)
            }
        }
        
        completion(true)
    }
    
    /// Stop head motion
    func stopHeadMotion() {
        self.motionMgr.stopDeviceMotionUpdates()
    }
}

@available(iOS 14.0, *)
extension HeadMotionManager: CMHeadphoneMotionManagerDelegate {
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        //
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        //
    }
}
