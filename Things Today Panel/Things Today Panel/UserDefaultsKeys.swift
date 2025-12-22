import Foundation
import Carbon

// MARK: - UserDefaults Extension for Things Today Panel
extension UserDefaults {
    enum Keys {
        static let thingsAuthToken = "thingsAuthToken"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let refreshInterval = "refreshInterval"
        static let windowPosition = "panelFrame"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let hasPromptedForAccessibility = "hasPromptedForAccessibility"
    }

    // Things auth token
    var thingsAuthToken: String? {
        get { string(forKey: Keys.thingsAuthToken) }
        set { set(newValue, forKey: Keys.thingsAuthToken) }
    }

    // Has user completed first-time setup?
    var hasCompletedOnboarding: Bool {
        get { bool(forKey: Keys.hasCompletedOnboarding) }
        set { set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }

    // Refresh interval (default 60 seconds)
    var refreshInterval: TimeInterval {
        get {
            let value = double(forKey: Keys.refreshInterval)
            return value > 0 ? value : 60
        }
        set { set(newValue, forKey: Keys.refreshInterval) }
    }

    // Hotkey key code (default: Y key = 16)
    var hotkeyKeyCode: UInt32 {
        get {
            let value = UInt32(integer(forKey: Keys.hotkeyKeyCode))
            return value > 0 ? value : 16 // Default to Y key
        }
        set { set(Int(newValue), forKey: Keys.hotkeyKeyCode) }
    }

    // Hotkey modifiers (default: Command + Shift)
    var hotkeyModifiers: UInt32 {
        get {
            let value = UInt32(integer(forKey: Keys.hotkeyModifiers))
            return value > 0 ? value : UInt32(cmdKey | shiftKey)
        }
        set { set(Int(newValue), forKey: Keys.hotkeyModifiers) }
    }

    // Has user been prompted for accessibility permissions?
    var hasPromptedForAccessibility: Bool {
        get { bool(forKey: Keys.hasPromptedForAccessibility) }
        set { set(newValue, forKey: Keys.hasPromptedForAccessibility) }
    }
}
