//
//  PositionManager.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/01/10.
//

//import Foundation
import DarkEggKit

protocol PositionManagerDelegate {
//    func agoraMgr(_ mgr: AgoraManager, seat: UInt ,selectedBy uid: UInt)
//    func agoraMgr(_ mgr: AgoraManager, seat: UInt ,deselectedBy uid: UInt)
}

class PositionManager: NSObject {
    let agoraManager: AgoraManager = AgoraManager.shared
    
    // default distance
    // radius = 2.5m
    let axial       = NSNumber(value: 1.2)
    let axialMinus  = NSNumber(value: -1.2)
    let slant       = NSNumber(value: 0.722)
    let slantMinus  = NSNumber(value: -0.722)
    
    // default vector3
    let defaultPosition = [NSNumber(value: 0), NSNumber(value: 0), NSNumber(value: 0)]
    let defaultForward  = [NSNumber(value: 0), NSNumber(value: 1), NSNumber(value: 0)]
    let defaultRight    = [NSNumber(value: 1), NSNumber(value: 0), NSNumber(value: 0)]
    let defaultUp       = [NSNumber(value: 0), NSNumber(value: 0), NSNumber(value: 1)]
    
    static let shared: PositionManager = { PositionManager()}()
}

extension PositionManager {
    func resetSelfPosition(mode: SpatialAudioMode = .local) {
        // set self position
        self.updateSelfPosition(self.defaultPosition,
                                forward: self.defaultForward,
                                right: self.defaultRight,
                                up: self.defaultUp,
                                mode: mode)
    }
    
    
    func changeSeat(ofUser uid: UInt, to seatIndex: Int) {
        Logger.debug("select seat \(seatIndex) for user \(uid)")
        var pos: [NSNumber] = []
        switch seatIndex {
        case 0:
            pos = [slantMinus, slant, slant]
            break
        case 1:
            pos = [0, 0, axial]
            break
        case 2:
            pos = [slant, slant, slant]
            break
        case 3:
            pos = [axialMinus, 0, 0]
            break
        case 4:
            pos = [0, axial, 0]
            break
        case 5:
            pos = [axial, 0, 0]
            break
            
        case 6:
            pos = [slantMinus, slant, slantMinus]
            break
        case 7:
            pos = [0, 0, axialMinus]
            break
        case 8:
            pos = [slant, slant, slantMinus]
            break
        default: // default, not on stage, from back
            pos = [0, axialMinus, 0]
            break
        }
        
        self.updatePosition(ofRemoteUser: uid, to: pos)
    }
    
    func changeSelfSeat(_ seatIndex: Int, mode: SpatialAudioMode = .local) {
        Logger.debug("select seat \(seatIndex) for self")
        let pos: [NSNumber] = self.getPositionOfSeat(seatIndex)
        self.updateSelfPosition(pos, forward: defaultForward, right: defaultRight, up: defaultUp, mode: mode)
    }
    
    func getPositionOfSeat(_ seatIndex: Int) -> [NSNumber] {
        var pos: [NSNumber] = []
        switch seatIndex {
        case 0:
            pos = [slantMinus, slant, slant]
            break
        case 1:
            pos = [0, 0, axial]
            break
        case 2:
            pos = [slant, slant, slant]
            break
        case 3:
            pos = [axialMinus, 0, 0]
            break
        case 4:
            pos = [0, axial, 0]
            break
        case 5:
            pos = [axial, 0, 0]
            break
            
        case 6:
            pos = [slantMinus, slant, slantMinus]
            break
        case 7:
            pos = [0, 0, axialMinus]
            break
        case 8:
            pos = [slant, slant, slantMinus]
            break
        default: // default, not on stage, from back
            pos = [0, axialMinus, 0]
            break
        }
        Logger.debug("set screen \(seatIndex) at \(pos)")
        return pos
    }
    
    func updatePosition(ofRemoteUser uid: UInt, to position: [NSNumber]) {
        self.agoraManager.updatePosition(of: uid, position: position)
    }
    
    func updateSelfPosition(_ position: [NSNumber], forward: [NSNumber], right: [NSNumber], up: [NSNumber], mode: SpatialAudioMode = .local) {
        self.agoraManager.updateSelfPosition(
            position: position,
            forward: forward,
            right: right,
            up: up,
            mode: mode)
    }
}

extension PositionManager {
    func getPositionOfScreen(_ index: Int) -> [NSNumber] {
        let column = index % 3
        let row = index / 3
        //Logger.debug("set screen \(row) - \(column)")
        // (-1,-1,-1) (0,-1,-1) (1,-1,-1)
        // (-1,0,-1) (0,0,-1) (1,0,-1)
        // (-1,1,-1) (0,1,-1) (1,1,-1)
        var pos: [NSNumber] = []
        
        pos = [NSNumber(value: column-1), NSNumber(value: 1-row), NSNumber(value: -1.0)]
        //Logger.debug("set screen \(row) - \(column) at \(pos)")
        return pos
    }
    
    func getVoicePosition(ofScreen index: Int) -> [NSNumber] {
        var pos: [NSNumber] = []
        switch index {
        case 0:
            pos = [slantMinus, slant, slant]
            break
        case 1:
            pos = [0, 0, axial]
            break
        case 2:
            pos = [slant, slant, slant]
            break
        case 3:
            pos = [-1, 1, 0]
            break
        case 4:
            pos = [0, 1, -1]
            break
        case 5:
            pos = [1, 1, -1]
            break

        case 6:
            pos = [slantMinus, slant, slantMinus]
            break
        case 7:
            pos = [0, 0, axialMinus]
            break
        case 8:
            pos = [slant, slant, slantMinus]
            break
        default: // default, not on stage, from back
            pos = [0, axialMinus, 0]
            break
        }
        Logger.debug("set screen \(index) at \(pos)")
        return pos
    }
}
