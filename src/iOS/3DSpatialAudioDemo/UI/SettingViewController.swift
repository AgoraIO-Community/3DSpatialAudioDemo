//
//  SettingViewController.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/07/06.
//

import UIKit

class SettingViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

extension SettingViewController {
    @IBAction private func onLanguageSelectorChanged(_ sender: UISegmentedControl) {
        //
        switch sender.selectedSegmentIndex {
        case 0:
            break
        default:
            break
        }
    }
}
