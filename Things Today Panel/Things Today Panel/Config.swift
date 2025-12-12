import Foundation

// MARK: - Configuration
struct ThingsConfig {
    // Get Things authentication token from UserDefaults
    // Users set this via onboarding or settings
    static var authToken: String {
        UserDefaults.standard.thingsAuthToken ?? ""
    }

    // Check if user has configured auth token
    static var hasAuthToken: Bool {
        guard let token = UserDefaults.standard.thingsAuthToken else { return false }
        return !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // Data source preference
    enum DataSource {
        case appleScript  // Uses AppleScript to query Things directly
        case sqlite       // Uses direct SQLite database access (recommended)
        case urlScheme    // Uses Things URL scheme (limited functionality)
        case mcpServer    // Uses Things MCP server (if available)
    }

    static let dataSource: DataSource = .sqlite

    // Refresh interval in seconds (from UserDefaults, default 60)
    static var refreshInterval: TimeInterval {
        UserDefaults.standard.refreshInterval
    }

    // Auto-refresh on app activation
    static let refreshOnActivation = true
}
