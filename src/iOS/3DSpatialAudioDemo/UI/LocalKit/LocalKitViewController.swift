//
//  LocalKitViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2021/10/14.
//

import UIKit
import DarkEggKit

enum SceneType: String {
    case host
    case nineSeat
    case arRoom
    case imageRoom
    case multiPlayerRoom
    case nineSeatsARRoom
    
    case multiPlayerHostRoom
    case multiPlayerAudienceRoom
    
    var segueName: String {
        switch self {
        case .host:
            return "Host"
        case .nineSeat:
            return "EnterRoomAsAudience"
        case .arRoom:
            return "EnterARRoom"
        case .imageRoom:
            return "EnterRoomImage"
        case .multiPlayerRoom:
            return "EnterMultiPlayerRoom"
        case .nineSeatsARRoom:
            return "Enter9SeatsARRoom"
        case .multiPlayerHostRoom:
            return "EnterMultiPlayerHostRoom"
        case .multiPlayerAudienceRoom:
            return "EnterMultiPlayerAudienceRoom"
        }
    }
    
    var menuName: String {
        switch self {
        case .host:
            return "Host"
        case .nineSeat:
            return "Audience - Nine seat room"
        case .arRoom:
            return "Audience - AR room(ARKit)"
        case .imageRoom:
            return "Audience - Image room"
        case .multiPlayerRoom:
            return "Audience - MultiPlayerRoom"
        case .nineSeatsARRoom:
            return "Audience - Nine seat AR room"
        case .multiPlayerHostRoom:
            return "Multi Player - Host"
        case .multiPlayerAudienceRoom:
            return "Multi Player - Audience"
        }
    }
}

class LocalKitViewController: UIViewController {
    @IBOutlet weak var channelNameField: UITextField!
    @IBOutlet weak var HostButton: UIButton!
    @IBOutlet weak var MultiPlayerHostButton: UIButton!
    @IBOutlet weak var AudienceButton: UIButton!
    @IBOutlet weak var arRoomButton: UIButton!
    @IBOutlet weak var imageRoomButton: UIButton!
    @IBOutlet weak var realityRoomButton: UIButton!
    @IBOutlet weak var mediaPlayerRoomButton: UIButton!
    @IBOutlet weak var nineSeatsARButton: UIButton!
    
    @IBOutlet weak var versionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        if #available(iOS 15, *) {
            self.HostButton.configuration?.baseBackgroundColor = ThemeDefault.primaryColor
            self.HostButton.configurationUpdateHandler = buttonHandler
            
            [AudienceButton, imageRoomButton, arRoomButton, realityRoomButton, mediaPlayerRoomButton, nineSeatsARButton].forEach { btn in
                btn?.configuration?.baseBackgroundColor = ThemeDefault.secondaryColor
                btn?.configurationUpdateHandler = buttonHandler
            }
        } else {
            // Fallback on earlier versions
            self.HostButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.AudienceButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.imageRoomButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.arRoomButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.realityRoomButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.mediaPlayerRoomButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.nineSeatsARButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
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
            self.performSegue(withIdentifier: "EnterRoomAsAudience", sender: self)
        }
    }
    
    @IBAction private func onImageRoomButtonClicked(_ sender: UIButton?) {
        Logger.debug("EnterImageRoomAsAudience")
        if checkChannelName() {
            self.performSegue(withIdentifier: "EnterRoomImage", sender: self)
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
            self.performSegue(withIdentifier: "EnterMultiPlayerRoom", sender: self)
        }
    }
    
    @IBAction private func onNineSeatsARButtonClicked(_ sender: UIButton) {
        Logger.debug("onNineSeatsARButtonClicked")
        if checkChannelName() {
            self.performSegue(withIdentifier: "Enter9SeatsARRoom", sender: self)
        }
    }
    
    @IBAction private func onViewTapped(_ sender: UITapGestureRecognizer) {
        self.channelNameField.endEditing(true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EnterRoomAsHost" {
            if let destinationVC = segue.destination as? HostViewController {
                destinationVC.channelName = channelNameField.text
            }
        }
        else if segue.identifier == "EnterRoomAsAudience" {
            if let destinationVC = segue.destination as? NineSeatRoomViewController {
                destinationVC.channelName = channelNameField.text
                destinationVC.isHost = false
            }
        }
        else if segue.identifier == "EnterARRoom" {
            if let destinationVC = segue.destination as? ARRoomViewController {
                destinationVC.channelName = channelNameField.text
                destinationVC.isHost = false
            }
        }
        else if segue.identifier == "EnterRoomImage" {
            if let destinationVC = segue.destination as? RoomImageViewController {
                destinationVC.channelName = channelNameField.text
                destinationVC.isHost = false
            }
        }
        else if segue.identifier == "EnterRealityRoom" {
            if let destinationVC = segue.destination as? RealityKitViewController {
                destinationVC.channelName = channelNameField.text
                destinationVC.isHost = false
            }
        }
        else if segue.identifier == "EnterMultiPlayerRoom" {
            if let destinationVC = segue.destination as? MultiPlayerViewController {
                destinationVC.channelName = channelNameField.text
                destinationVC.isHost = true
            }
        }
        else if segue.identifier == "Enter9SeatsARRoom" {
            if let destinationVC = segue.destination as? NineSeatsARViewController {
                destinationVC.channelName = channelNameField.text
                destinationVC.isHost = true
            }
        }
        else if segue.identifier == "EnterMultiPlayerHostRoom" {
            if let destinationVC = segue.destination as? MultiMediaHostViewController {
                destinationVC.channelName = channelNameField.text
                //destinationVC.isHost = true
            }
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
