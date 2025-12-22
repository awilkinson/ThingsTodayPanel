import SwiftUI
import Combine

class NavigationController: ObservableObject {
    @Published var selectedTaskId: String?
    @Published var allTaskIds: [String] = []

    func selectNext() {
        guard !allTaskIds.isEmpty else { return }

        if let current = selectedTaskId,
           let index = allTaskIds.firstIndex(of: current),
           index < allTaskIds.count - 1 {
            // Move to next task
            selectedTaskId = allTaskIds[index + 1]
        } else {
            // Wrap to first task
            selectedTaskId = allTaskIds.first
        }
    }

    func selectPrevious() {
        guard !allTaskIds.isEmpty else { return }

        if let current = selectedTaskId,
           let index = allTaskIds.firstIndex(of: current),
           index > 0 {
            // Move to previous task
            selectedTaskId = allTaskIds[index - 1]
        } else {
            // Wrap to last task
            selectedTaskId = allTaskIds.last
        }
    }

    func clearSelection() {
        selectedTaskId = nil
    }
}
