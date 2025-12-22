import Foundation
import SwiftUI

// MARK: - Things Task Model
struct ThingsTask: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let notes: String?
    var status: TaskStatus
    let project: String?
    let area: String?
    let tags: [String]
    let deadline: Date?
    let when: String?
    let checklist: [ChecklistItem]?

    enum TaskStatus: String, Codable {
        case incomplete = "incomplete"
        case completed = "completed"
        case canceled = "canceled"
    }

    var isCompleted: Bool {
        status == .completed
    }

    // Display properties
    var displayProject: String? {
        project ?? area
    }

    var hasDeadline: Bool {
        deadline != nil
    }

    var isOverdue: Bool {
        guard let deadline = deadline else { return false }
        return deadline < Date() && !isCompleted
    }
}

// MARK: - Checklist Item
struct ChecklistItem: Codable, Identifiable, Equatable {
    let id: String
    let title: String
    var completed: Bool
}

// MARK: - Task Group for Sections
struct TaskGroup: Identifiable {
    let id = UUID()
    let title: String?
    let tasks: [ThingsTask]
}

// MARK: - Color Extensions for Things Theme
extension Color {
    // Things-inspired color palette
    static let thingsBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let thingsBackground = Color(nsColor: .controlBackgroundColor)
    static let thingsSecondary = Color.secondary.opacity(0.6)
    static let thingsSuccess = Color.green
    static let thingsWarning = Color.orange
    static let thingsDanger = Color.red

    // Subtle hover state
    static let thingsHover = Color.primary.opacity(0.03)
}

// MARK: - Spacing Design System
extension CGFloat {
    /// Extra small spacing (4pt) - Minimal breathing room between adjacent elements
    static let spacingXS: CGFloat = 4

    /// Small spacing (8pt) - Compact spacing for related groups
    static let spacingSM: CGFloat = 8

    /// Medium spacing (12pt) - Standard content spacing
    static let spacingMD: CGFloat = 12

    /// Large spacing (16pt) - Generous container padding
    static let spacingLG: CGFloat = 16

    /// Extra large spacing (24pt) - Major section separation
    static let spacingXL: CGFloat = 24

    /// 2X large spacing (40pt) - Bottom safe area
    static let spacing2XL: CGFloat = 40
}
