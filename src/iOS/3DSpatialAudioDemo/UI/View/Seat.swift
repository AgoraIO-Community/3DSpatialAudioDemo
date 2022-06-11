//
//  Seat.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/10/20.
//

import UIKit

@IBDesignable
class Seat: UIControl {
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var avatarView: UIView!
    var contentView: UIView!
    
    var uid: UInt? {
        didSet {
            if let id = uid {
                self.userNameLabel.text = "\(id)"
            }
            else {
                self.userNameLabel.text = "-"
            }
        }
    }
    
    lazy var position: [NSNumber] = {
        return []
    }()
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentView = loadViewFromNib()
        addSubview(contentView)
        let tap = UITapGestureRecognizer(target: self, action: #selector(sendTapAction))
        self.addGestureRecognizer(tap)
    }
    
    func loadViewFromNib() -> UIView {
        let view = Bundle.main.loadNibNamed("Seat", owner: self, options: nil)?.first as! UIView
        return view
    }
    
    @objc func sendTapAction() {
        self.sendActions(for: .touchUpInside)
    }
}

extension Seat {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.contentView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }
    
    public override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        // default display in storyboard
//        #if TARGET_INTERFACE_BUILDER
//        self.avatarView.layer.cornerRadius = self.avatarView.bounds.width/2
//        #endif
        
        self.avatarView.layer.cornerRadius = self.avatarView.bounds.width/2
        self.avatarView.layer.borderColor = UIColor.systemGray2.cgColor
        self.avatarView.layer.borderWidth = 4
    }
}
