//
//  HomeViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/02/10.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet private weak var localKitButton: UIButton!
    @IBOutlet private weak var cloudKitButton: UIButton!
    
    @IBOutlet private weak var agoraAppIdField: UITextField!
    @IBOutlet private weak var agoraTokenFielc: UITextField!
    
    enum SegueId: String {
        case localKitScene
        case cloudKitScene
        
        var stringId: String {
            switch self {
            case .localKitScene:
                return "ShowLocalKitScene"
            case .cloudKitScene:
                return "ShowCloudKitScene"
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.agoraAppIdField.text = AppConfig.shared.agora.appId
    }
}

// MARK: - Actions
extension HomeViewController {
    /// LocalKitButton click event handle
    /// - Parameter sender: localKitButton
    @IBAction private func onLocalKitButtonClicked(_ sender: UIButton) {
        // save appId
        if let newAppId = self.agoraAppIdField.text, newAppId.count > 0 {
            AppConfig.shared.agora.appId = newAppId
        }
        self.performSegue(withIdentifier: SegueId.localKitScene.stringId, sender: sender)
    }
    
    
    /// CloudKitButton click event handle
    /// - Parameter sender: cloudKitButton
    @IBAction private func onCloudKitButtonClicked(_ sender: UIButton) {
        self.performSegue(withIdentifier: SegueId.cloudKitScene.stringId, sender: sender)
    }
    
    /// View Tapped
    /// - Parameter sender: UITapGestureRecognizer
    @IBAction private func onViewTapped(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}


// MARK: - Button setting
extension HomeViewController {
    private func setupButtons() {
        self.cloudKitButton.isEnabled = false // The cloud function is not supported `  in NGSDK(4.0)
        // button hancle (>= iOS 15)
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
        
        if #available(iOS 15, *) {
            self.localKitButton.configuration?.baseBackgroundColor = ThemeDefault.primaryColor
            self.localKitButton.configurationUpdateHandler = buttonHandler
            
            self.cloudKitButton.configuration?.baseBackgroundColor = ThemeDefault.secondaryColor
            self.cloudKitButton.configurationUpdateHandler = buttonHandler
        } else {
            // Fallback on earlier versions
            self.localKitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
            self.cloudKitButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        }
    }
}
