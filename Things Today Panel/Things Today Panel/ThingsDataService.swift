import Foundation
import Combine
import AppKit

class ThingsDataService: ObservableObject {
    @Published var tasks: [ThingsTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
        fetchTasks()

        // Auto-refresh based on configuration
        Timer.publish(every: ThingsConfig.refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchTasks()
            }
            .store(in: &cancellables)
    }

    func fetchTasks() {
        isLoading = true
        errorMessage = nil

        // Use AppleScript to get today's tasks from Things
        fetchFromThingsAppleScript()
    }

    private func fetchFromThingsAppleScript() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let tasks = try self.queryThingsWithAppleScript()

                DispatchQueue.main.async {
                    self.tasks = tasks
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load tasks: \(error.localizedDescription)"
                    self.isLoading = false

                    // Fallback to mock data for testing
                    self.tasks = SQLiteHelper.mockTasks()
                }
            }
        }
    }

    private func queryThingsWithAppleScript() throws -> [ThingsTask] {
        // AppleScript to get today's tasks from Things
        let script = """
        tell application "Things3"
            set todayTodos to to dos of list "Today"
            set taskList to {}

            repeat with aTodo in todayTodos
                set todoData to {¬
                    id:id of aTodo, ¬
                    name:name of aTodo, ¬
                    notes:notes of aTodo, ¬
                    status:status of aTodo, ¬
                    project:project of aTodo, ¬
                    area:area of aTodo, ¬
                    tags:tag names of aTodo ¬
                }
                set end of taskList to todoData
            end repeat

            return taskList
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            let output = scriptObject.executeAndReturnError(&error)

            if let error = error {
                throw NSError(
                    domain: "ThingsDataService",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: "AppleScript error: \(error)"]
                )
            }

            // Parse AppleScript output into ThingsTask objects
            return try parseAppleScriptOutput(output)
        } else {
            throw NSError(
                domain: "ThingsDataService",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to create AppleScript"]
            )
        }
    }

    private func parseAppleScriptOutput(_ output: NSAppleEventDescriptor) throws -> [ThingsTask] {
        var tasks: [ThingsTask] = []

        // Parse the AppleScript list descriptor
        for i in 1...output.numberOfItems {
            guard let item = output.atIndex(i) else { continue }

            // Extract properties from the record
            let id = item.forKeyword(AEKeyword("id  ".fourCharCodeValue))?.stringValue ?? UUID().uuidString
            let name = item.forKeyword(AEKeyword("name".fourCharCodeValue))?.stringValue ?? "Untitled"
            let notes = item.forKeyword(AEKeyword("note".fourCharCodeValue))?.stringValue
            let status = item.forKeyword(AEKeyword("stat".fourCharCodeValue))?.stringValue ?? "incomplete"
            let project = item.forKeyword(AEKeyword("proj".fourCharCodeValue))?.stringValue
            let area = item.forKeyword(AEKeyword("area".fourCharCodeValue))?.stringValue

            // Parse tags
            var tags: [String] = []
            if let tagsList = item.forKeyword(AEKeyword("tags".fourCharCodeValue)) {
                for j in 1...tagsList.numberOfItems {
                    if let tag = tagsList.atIndex(j)?.stringValue {
                        tags.append(tag)
                    }
                }
            }

            let taskStatus: ThingsTask.TaskStatus = status == "completed" ? .completed : .incomplete

            let task = ThingsTask(
                id: id,
                title: name,
                notes: notes,
                status: taskStatus,
                project: project,
                area: area,
                tags: tags,
                deadline: nil, // AppleScript doesn't easily expose deadline
                when: "today",
                checklist: nil
            )

            tasks.append(task)
        }

        return tasks
    }

    func toggleTask(_ task: ThingsTask) {
        // Use Things URL scheme to complete/uncomplete task
        let action = task.isCompleted ? "open" : "update"
        let status = task.isCompleted ? "" : "&completed=true"

        if let url = URL(string: "things:///\(action)?id=\(task.id)\(status)&auth-token=\(ThingsConfig.authToken)") {
            NSWorkspace.shared.open(url)

            // Refresh tasks after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.fetchTasks()
            }
        }
    }

    func openTaskInThings(_ task: ThingsTask) {
        // Use Things URL scheme to open task
        if let url = URL(string: "things:///show?id=\(task.id)&auth-token=\(ThingsConfig.authToken)") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - SQLite Helper
class SQLiteHelper {
    static func queryTodayTasks(at dbPath: URL) throws -> [ThingsTask] {
        // This is a simplified version - you'll need to use SQLite.swift or similar
        // to properly query the database

        // Sample query structure (Things database schema):
        // SELECT * FROM TMTask WHERE status = 0 AND start = 1 ORDER BY todayIndex

        // For now, return mock data to test the UI
        return mockTasks()
    }

    static func mockTasks() -> [ThingsTask] {
        return [
            ThingsTask(
                id: "1",
                title: "Review design mockups",
                notes: "Check the new landing page designs",
                status: .incomplete,
                project: "Website Redesign",
                area: nil,
                tags: ["design", "urgent"],
                deadline: Date().addingTimeInterval(86400),
                when: "today",
                checklist: nil
            ),
            ThingsTask(
                id: "2",
                title: "Write quarterly report",
                notes: nil,
                status: .incomplete,
                project: nil,
                area: "Work",
                tags: [],
                deadline: nil,
                when: "today",
                checklist: [
                    ChecklistItem(id: "c1", title: "Gather data", completed: true),
                    ChecklistItem(id: "c2", title: "Write summary", completed: false)
                ]
            ),
            ThingsTask(
                id: "3",
                title: "Call mom",
                notes: "Don't forget to wish her happy birthday!",
                status: .incomplete,
                project: nil,
                area: "Personal",
                tags: ["family"],
                deadline: Date(),
                when: "today",
                checklist: nil
            ),
            ThingsTask(
                id: "4",
                title: "Buy groceries",
                notes: nil,
                status: .incomplete,
                project: nil,
                area: nil,
                tags: [],
                deadline: nil,
                when: "today",
                checklist: nil
            ),
            ThingsTask(
                id: "5",
                title: "Finish presentation",
                notes: "Team meeting at 3pm",
                status: .incomplete,
                project: "Q1 Planning",
                area: "Work",
                tags: ["presentation"],
                deadline: Date().addingTimeInterval(-3600),
                when: "today",
                checklist: nil
            )
        ]
    }
}
