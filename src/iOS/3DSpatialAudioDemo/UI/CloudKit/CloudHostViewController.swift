//
//  CloudHostViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/15.
//

import UIKit
import GameKit
import DarkEggKit

class CloudHostViewController: UIViewController {
    enum MoveTo: Int {
        case stop = 0
        case up
        case left
        case down
        case right
    }
    
    @IBOutlet weak var upButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var downButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    @IBOutlet weak var hostView: UILabel!
    @IBOutlet weak var audienceView: UILabel!
    
    var direction: MoveTo = .stop
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.timer = Timer(timeInterval: 1, repeats: true) { [weak self] timer in
            self?.updateView(timer)
        }
        self.timer?.fire()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.timer?.invalidate()
    }
}

extension CloudHostViewController {
    @IBAction func onDirectButtonTouched(_ sender: UIButton) {
        switch sender {
        case upButton:
            direction = MoveTo.up
            break
        case leftButton:
            direction = MoveTo.left
            break
        case downButton:
            direction = MoveTo.down
            break
        case rightButton:
            direction = MoveTo.right
            break
        default:
            break
        }
        
        // move
        Logger.debug("\(direction.rawValue)")
    }
    
    @IBAction func onDircetionButtonUntouched(_ sender: UIButton) {
        
    }
    
    private func updateView(_ timer: Timer) {
        
    }
}

extension CloudHostViewController {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        //
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        //
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        //
    }
}
