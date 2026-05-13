//
//  GameTypography.swift
//  Walk to Grow Shared
//

import Foundation
#if canImport(UIKit)
    import UIKit
#endif

/// Font pixel (Press Start 2P) — đăng ký qua `UIAppFonts` trong Info.plist.
enum GameTypography {
    static let pixelFontNameCandidates = ["Press Start 2P", "PressStart2P-Regular"]

    #if canImport(UIKit)
        static func uiFont(ofSize size: CGFloat) -> UIFont {
            for name in pixelFontNameCandidates {
                if let font = UIFont(name: name, size: size) {
                    return font
                }
            }
            return UIFont.monospacedSystemFont(ofSize: size, weight: .semibold)
        }
    #endif

    /// Tên font cho `SKLabelNode(fontNamed:)`.
    static var skPixelFontName: String {
        #if canImport(UIKit)
            for name in pixelFontNameCandidates {
                if UIFont(name: name, size: 12) != nil {
                    return name
                }
            }
        #endif
        return "Courier-Bold"
    }
}
