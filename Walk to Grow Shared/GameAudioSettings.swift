//
//  GameAudioSettings.swift
//  Walk to Grow Shared
//

import Foundation

enum GameAudioSettings {
    private static let musicKey = "walktogrow.settings.musicEnabled"
    private static let soundEffectsKey = "walktogrow.settings.soundEffectsEnabled"
    private static let vibrationKey = "walktogrow.settings.vibrationEnabled"

    private static let defaults = UserDefaults.standard

    static var isMusicEnabled: Bool {
        get {
            if defaults.object(forKey: musicKey) == nil { return true }
            return defaults.bool(forKey: musicKey)
        }
        set { defaults.set(newValue, forKey: musicKey) }
    }

    static var isSoundEffectsEnabled: Bool {
        get {
            if defaults.object(forKey: soundEffectsKey) == nil { return true }
            return defaults.bool(forKey: soundEffectsKey)
        }
        set { defaults.set(newValue, forKey: soundEffectsKey) }
    }

    static var isVibrationEnabled: Bool {
        get {
            if defaults.object(forKey: vibrationKey) == nil { return false }
            return defaults.bool(forKey: vibrationKey)
        }
        set { defaults.set(newValue, forKey: vibrationKey) }
    }
}
