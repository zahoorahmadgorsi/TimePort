//
//  Extensios.swift
//  Timeport
//
//  Created by Zahoor Ahmad Gorsi on 11/11/24.
//

import UIKit
import Foundation

//MARK: - UIColor -
extension UIColor {
    // Hex string like "#RRGGBB" or "RRGGBB" or "#RRGGBBAA"
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        var alpha: CGFloat = 1.0
        let length = hexSanitized.count

        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        if length == 6 {
            let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            let blue = CGFloat(rgb & 0x0000FF) / 255.0

            self.init(red: red, green: green, blue: blue, alpha: alpha)
        } else if length == 8 {
            let red = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            let green = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            let blue = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            alpha = CGFloat(rgb & 0x000000FF) / 255.0

            self.init(red: red, green: green, blue: blue, alpha: alpha)
        } else {
            self.init(white: 0.0, alpha: 1.0) // Default color if invalid hex string
        }
    }
}
