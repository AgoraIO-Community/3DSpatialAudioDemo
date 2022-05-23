//
//  UIColor+Darkzero.swift
//  3DSpatialAudioDemo
//
//  Created by Yuhua Hu on 2022/01/13.
//

import UIKit

protocol Theme {
    static var name: String { get }
    
    static var primaryColor: UIColor { get }
    static var secondaryColor: UIColor { get }
}

struct ThemeDefault: Theme {
    static var name: String = "DefaultTheme"
    
    static var primaryColor     = UIColor.systemOrange
    static var secondaryColor   = UIColor.systemTeal
}

class ThemeManager {
    let shared: ThemeManager = {ThemeManager()}()
    var theme: Theme = ThemeDefault()
    
    func loadTheme(_ name: String) -> Theme {
        guard !name.isEmpty else {
            // return default theme
            return theme
        }
        //TODO: load theme
        return theme
    }
}
