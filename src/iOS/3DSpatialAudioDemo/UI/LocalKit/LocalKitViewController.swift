//
//  LocalKitViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/10/14.
//

import UIKit
import DarkEggKit

enum SceneType: String {
    case hostRoom
    case multiPlayerHostRoom
    
    case nineSeat
    case arRoom
    case localMultiPlayerRoom
    
    var segueName: String {
        switch self {
        case .hostRoom:
            return "EnterRoomAsHost"
        case .multiPlayerHostRoom:
            return "EnterMultiPlayerHostRoom"
            
        case .nineSeat:
            return "EnterNineSeatsRoom"
        case .arRoom:
            return "EnterARRoom"
        case .localMultiPlayerRoom:
            return "EnterLocalMultiPlayerRoom"
        }
    }
    
    var menuName: String {
        switch self {
        case .hostRoom:
            return "Host"
        case .multiPlayerHostRoom:
            return "Multi Player - Host"
            
        case .nineSeat:
            return "Audience - Nine seat room"
        case .arRoom:
            return "Audience - AR room(ARKit)"
        case .localMultiPlayerRoom:
            return "Audience - MultiPlayerRoom"
        }
    }
}

class LocalKitViewController: UIViewController {
    @IBOutlet weak var channelNameField: UITextField!
    
    @IBOutlet weak var HostButton: UIButton!
    @IBOutlet weak var MultiPlayerHostButton: UIButton!
    
    @IBOutlet weak var AudienceButton: UIButton!
    @IBOutlet weak var arRoomButton: UIButton!
    @IBOutlet weak var mediaPlayerRoomButton: UIButton!
    @IBOutlet weak var realityRoomButton: UIButton!
    
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if #available(iOS 15, *) {
            self.HostButton.configuration?.baseBackgroundColor = ThemeDefault.primaryColor
            self.HostButton.configurationUpdateHandler = buttonHandler
            
            [AudienceButton, arRoomButton, realityRoomButton, mediaPlayerRoomButton].forEach { btn in
                btn?.configuration?.baseBackgroundColor = ThemeDefault.secondaryColor
                btn?.configurationUpdateHandler = buttonHandler
            }
        } else {
            // Fallback on earlier versions
            self.HostButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.AudienceButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.arRoomButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.realityRoomButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.mediaPlayerRoomButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        }
        
        self.versionLabel.text = AppInfo.fullVersionString
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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

extension LocalKitViewController {
    @IBAction private func onHostButtonClicked(_ sender: UIButton?) {
        // select seat
        Logger.debug("EnterRoomAsHost")
        if checkChannelName() {
            self.performSegue(withIdentifier: "EnterRoomAsHost", sender: self)
        }
    }
    
    @IBAction private func onMultiPlayerHostButtonClicked(_ sender: UIButton?) {
        // select seat
        Logger.debug("EnterMultiPlayerHostRoom")
        if checkChannelName() {
            self.performSegue(withIdentifier: "EnterMultiPlayerHostRoom", sender: self)
        }
    }
    
    ///
    @IBAction private func onEnterARRoomClicked(_ sender: UIButton?) {
        Logger.debug("onEnterARRoomClicked")
        if checkChannelName() {
            self.performSegue(withIdentifier: "EnterARRoom", sender: self)
        }
    }
    
    @IBAction private func onAudienceButtonClicked(_ sender: UIButton?) {
        Logger.debug("EnterRoomAsAudience")
        if checkChannelName() {
            self.performSegue(withIdentifier: "EnterNineSeatsRoom", sender: self)
        }
    }
    
    @IBAction private func onRealityRoomButtonClicked(_ sender: UIButton) {
        Logger.debug("onRealityRoomButtonClicked")
        if checkChannelName() {
            self.performSegue(withIdentifier: "EnterRealityRoom", sender: self)
        }
    }
    
    @IBAction private func onMultiPlayerRoomButtonClicked(_ sender: UIButton) {
        Logger.debug("onMultiPlayerRoomButtonClicked")
        if checkChannelName() {
            self.performSegue(withIdentifier: "EnterLocalMultiPlayerRoom", sender: self)
        }
    }
    
    @IBAction private func onViewTapped(_ sender: UITapGestureRecognizer) {
        self.channelNameField.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case SceneType.hostRoom.segueName:
            if let destinationVC = segue.destination as? HostViewController {
                destinationVC.channelName = channelNameField.text
            }
            break
        case SceneType.multiPlayerHostRoom.segueName:
            if let destinationVC = segue.destination as? MultiMediaHostViewController {
                destinationVC.channelName = channelNameField.text
                //destinationVC.isHost = true
            }
            break
        case SceneType.nineSeat.segueName:
            if let destinationVC = segue.destination as? NineSeatRoomViewController {
                destinationVC.channelName = channelNameField.text
                destinationVC.isHost = false
            }
            break
        case SceneType.arRoom.segueName:
            if let destinationVC = segue.destination as? ARRoomViewController {
                destinationVC.channelName = channelNameField.text
                destinationVC.isHost = false
            }
            break
        case SceneType.localMultiPlayerRoom.segueName:
            if let destinationVC = segue.destination as? LocalMultiPlayerViewController {
                destinationVC.channelName = channelNameField.text
                destinationVC.isHost = true
            }
            break
        default:
            break
        }
    }
    
    /// Check channel name
    private func checkChannelName() -> Bool{
        guard let channelName = channelNameField.text, !channelName.isEmpty else {
            Logger.debug("Please enter channel name.")
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
}
