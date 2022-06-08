//
//  CloudKitViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/11.
//

import UIKit
import DarkEggKit

class CloudKitViewController: UIViewController {
    enum SceneType: String {
        case nineSeatsRoomHost
        case nineSeatsRoomAudience
        
        var segueName: String {
            switch self {
            case .nineSeatsRoomHost:
                return "EnterNineSeatsRoomHost"
            case .nineSeatsRoomAudience:
                return "EnterNineSeatsRoomAudience"
            }
        }
        
        var menuName: String {
            switch self {
            case .nineSeatsRoomHost:
                return "Host"
            case .nineSeatsRoomAudience:
                return "nineSeatsRoomAudience"
            }
        }
    }

    @IBOutlet weak var channelNameField: UITextField!
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var nineSeatsRoomHostButton: UIButton!
    @IBOutlet weak var nineSeatsRoomAudienceButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if #available(iOS 15, *) {
            self.nineSeatsRoomHostButton.configuration?.baseBackgroundColor = ThemeDefault.primaryColor
            self.nineSeatsRoomHostButton.configurationUpdateHandler = buttonHandler
            
            [nineSeatsRoomAudienceButton].forEach { btn in
                btn?.configuration?.baseBackgroundColor = ThemeDefault.secondaryColor
                btn?.configurationUpdateHandler = buttonHandler
            }
        } else {
            // Fallback on earlier versions
            self.nineSeatsRoomHostButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.nineSeatsRoomAudienceButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        }
    }
    
    let buttonHandler: (UIButton) -> Void = { (button) in
        // do something
        if #available(iOS 15.0, *) {
            var config = button.configuration
            var attribute = AttributeContainer()
            attribute.font = UIFont.boldSystemFont(ofSize: 15.0)
            config?.attributedTitle?.setAttributes(attribute)
            switch button.state {
            case .normal:
                button.backgroundColor = config?.baseBackgroundColor
                break
            case .highlighted:
                button.backgroundColor = config?.baseBackgroundColor?.withAlphaComponent(0.7)
                break
            case .disabled:
                button.backgroundColor = .gray
                break
            default:
                break
            }
            button.configuration = config
        } else {
            // Fallback on earlier versions
        }
    }
}

extension CloudKitViewController {
    /// 9 seats room host button click event handle
    /// - Parameter sender: 9 seats room host button
    @IBAction private func onNineSeatsHostButtonClicked(_ sender: UIButton?) {
        // select seat
        Logger.debug()
        if checkChannelName() {
            self.performSegue(withIdentifier: SceneType.nineSeatsRoomHost.segueName, sender: self)
        }
    }
    
    /// 9 seats room audience button click event handle
    /// - Parameter sender: 9 seats room audience button
    @IBAction private func onNineSeatsAudienceButtonClicked(_ sender: UIButton?) {
        Logger.debug()
        if checkChannelName() {
            self.performSegue(withIdentifier: SceneType.nineSeatsRoomAudience.segueName, sender: self)
        }
    }
    
    /// View tap event handle
    /// Hide the keyboard
    /// - Parameter sender: View
    @IBAction private func onViewTapped(_ sender: UITapGestureRecognizer) {
        self.channelNameField.endEditing(true)
    }
    
    /// Check channel name
    private func checkChannelName() -> Bool{
        guard let channelName = channelNameField.text, !channelName.isEmpty else {
            Logger.debug("[Error]Please enter channel name.")
            self.showAlert(title: "Cannot proceed", message: "Please enter the channel name.")
            return false
        }
        return true
    }
    
    /// Preform segue
    /// Paramater:
    ///     segueId: String
    private func joinRoom(segue segueId: String) {
        if checkChannelName() {
            self.performSegue(withIdentifier: segueId, sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == SceneType.nineSeatsRoomHost.segueName {
//            if let destinationVC = segue.destination as? NineSeatCloudViewController {
//                destinationVC.channelName = channelNameField.text
//                destinationVC.isHost = true
//            }
//        }
//        else if segue.identifier == SceneType.nineSeatsRoomAudience.segueName {
//            if let destinationVC = segue.destination as? NineSeatCloudViewController {
//                destinationVC.channelName = channelNameField.text
//                destinationVC.isHost = false
//            }
//        }
    }
}
