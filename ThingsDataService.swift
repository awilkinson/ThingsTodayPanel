import Foundation
import Combine

class ThingsDataService: ObservableObject {
    @Published var tasks: [ThingsTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()
    private let mcpServerURL = "http://localhost:3000" // Adjust based on your MCP server setup

    init() {
        fetchTasks()

        // Auto-refresh every 60 seconds
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.fetchTasks()
            }
            .store(in: &cancellables)
    }

    func fetchTasks() {
        isLoading = true
        errorMessage = nil

        // Call the Things MCP server endpoint
        // This is a placeholder - actual implementation depends on your MCP server setup
        fetchFromMCPServer()
    }

    private func fetchFromMCPServer() {
        // Option 1: Call MCP server via HTTP
        // This requires your MCP server to expose an HTTP endpoint

        // Option 2: Direct Things URL Scheme
        // Use Things URL scheme to get data (limited)

        // Option 3: Direct SQLite access (most reliable)
        fetchFromSQLite()
    }

    private func fetchFromSQLite() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let tasks = try self.queryThingsDatabase()

                DispatchQueue.main.async {
                    self.tasks = tasks
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load tasks: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func queryThingsDatabase() throws -> [ThingsTask] {
        // Find Things database
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let groupContainer = homeDir.appendingPathComponent("Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac")

        // Find the database file
        guard let thingsDataDir = try? FileManager.default.contentsOfDirectory(
            at: groupContainer,
            includingPropertiesForKeys: nil
        ).first(where: { $0.lastPathComponent.hasPrefix("ThingsData-") }) else {
            throw NSError(domain: "ThingsDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Things database not found"])
        }

        let dbPath = thingsDataDir
            .appendingPathComponent("Things Database.thingsdatabase")
            .appendingPathComponent("main.sqlite")

        // Query database using SQLite
        let tasks = try SQLiteHelper.queryTodayTasks(at: dbPath)

        return tasks
    }

    func toggleTask(_ task: ThingsTask) {
        // Update task status in Things
        // This requires calling Things URL scheme or updating database
        openTaskInThings(task)
    }

    func openTaskInThings(_ task: ThingsTask) {
        // Use Things URL scheme to open/complete task
        if let url = URL(string: "things:///show?id=\(task.id)") {
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
