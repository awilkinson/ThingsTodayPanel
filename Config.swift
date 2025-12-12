import Foundation

// MARK: - Configuration
struct ThingsConfig {
    // Your Things authentication token from:
    // Things → Settings → General → Enable Things URLs → Manage
    static let authToken = "DLMMAwBgAACAMIFHAQAAAA"

    // Data source preference
    enum DataSource {
        case appleScript  // Uses AppleScript to query Things directly
        case urlScheme    // Uses Things URL scheme (limited functionality)
        case mcpServer    // Uses Things MCP server (if available)
    }

    static let dataSource: DataSource = .appleScript

    // Refresh interval in seconds
    static let refreshInterval: TimeInterval = 60

    // Auto-refresh on app activation
    static let refreshOnActivation = true
}
