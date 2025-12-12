import Foundation

// MARK: - UserDefaults Extension for Things Today Panel
extension UserDefaults {
    enum Keys {
        static let thingsAuthToken = "thingsAuthToken"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let refreshInterval = "refreshInterval"
        static let windowPosition = "panelFrame"
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
}
