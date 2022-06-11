//
//  UIViewController+Alert.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/01/18.
//

import UIKit

extension UIViewController {
    /// Show error alert
    func showAlert(title: String, message: String?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "OK", style: .default) { action in
            //
        }
        alert.addAction(closeAction)
        self.present(alert, animated: true) {
            //
        }
    }
}
