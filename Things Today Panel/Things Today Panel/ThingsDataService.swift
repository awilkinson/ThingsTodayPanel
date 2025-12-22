import Foundation
import Combine
import AppKit
import SQLite

class ThingsDataService: ObservableObject {
    @Published var tasks: [ThingsTask] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    // Undo manager for supporting Command+Z
    let undoManager = UndoManager()

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

        // Use data source from configuration
        switch ThingsConfig.dataSource {
        case .sqlite:
            fetchFromSQLite()
        case .appleScript:
            fetchFromThingsAppleScript()
        case .urlScheme, .mcpServer:
            // Future implementation
            DispatchQueue.main.async {
                self.errorMessage = "This data source is not yet implemented"
                self.isLoading = false
                self.tasks = []
            }
        }
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
                    self.tasks = [] // Show empty list instead of mock data
                }
            }
        }
    }

    private func fetchFromSQLite() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            do {
                let tasks = try SQLiteHelper.queryTodayTasks()

                DispatchQueue.main.async {
                    self.tasks = tasks
                    self.isLoading = false
                    self.errorMessage = nil
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to load tasks: \(error.localizedDescription)"
                    self.isLoading = false
                    self.tasks = [] // Show empty list instead of mock data
                }
            }
        }
    }

    private func queryThingsWithAppleScript() throws -> [ThingsTask] {
        // First, make sure Things is running
        let workspace = NSWorkspace.shared
        let thingsRunning = workspace.runningApplications.contains { app in
            app.bundleIdentifier == "com.culturedcode.ThingsMac"
        }

        if !thingsRunning {
            // Launch Things
            if let thingsURL = workspace.urlForApplication(withBundleIdentifier: "com.culturedcode.ThingsMac") {
                do {
                    try workspace.openApplication(at: thingsURL, configuration: NSWorkspace.OpenConfiguration())
                    // Give Things a moment to launch
                    Thread.sleep(forTimeInterval: 1.0)
                } catch {
                    throw NSError(
                        domain: "ThingsDataService",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to launch Things: \(error.localizedDescription)"]
                    )
                }
            } else {
                throw NSError(
                    domain: "ThingsDataService",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Things 3 is not installed. Please install Things from the Mac App Store."]
                )
            }
        }

        // AppleScript to get today's tasks from Things
        // Note: We activate Things first to ensure it's ready to respond
        let script = """
        tell application "Things3"
            activate
            delay 0.5

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
                // Extract meaningful error message
                let errorCode = error["NSAppleScriptErrorNumber"] as? Int ?? 0
                let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"

                var friendlyMessage = errorMessage
                if errorCode == -600 || errorCode == -1743 {
                    friendlyMessage = "Permission needed: Open System Settings → Privacy & Security → Automation → Enable 'Things Today Panel' to control Things3. Then restart this app."
                }

                throw NSError(
                    domain: "ThingsDataService",
                    code: 2,
                    userInfo: [NSLocalizedDescriptionKey: friendlyMessage]
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
        // Capture current state for undo
        let taskId = task.id
        let wasCompleted = task.isCompleted
        let taskTitle = task.title
        let taskStatus = task.status

        // Register undo action BEFORE performing toggle
        undoManager.registerUndo(withTarget: self) { service in
            // Create a mock task with the previous state to toggle back
            let undoTask = ThingsTask(
                id: taskId,
                title: taskTitle,
                notes: nil,
                status: taskStatus,
                project: nil,
                area: nil,
                tags: [],
                deadline: nil,
                when: "today",
                checklist: nil
            )
            service.performToggle(undoTask)
        }
        undoManager.setActionName(wasCompleted ? "Uncomplete Task" : "Complete Task")

        // Perform the actual toggle
        performToggle(task)
    }

    private func performToggle(_ task: ThingsTask) {
        print("🟢 performToggle called for: \(task.title), isCompleted: \(task.isCompleted)")
        // Use Things URL scheme to complete/uncomplete task
        let urlString: String
        if task.isCompleted {
            // Uncomplete the task
            urlString = "things:///update?id=\(task.id)&completed=false&auth-token=\(ThingsConfig.authToken)"
            print("🟢 Uncompleting task with URL: \(urlString)")
        } else {
            // Complete the task
            urlString = "things:///update?id=\(task.id)&completed=true&auth-token=\(ThingsConfig.authToken)"
            print("🟢 Completing task with URL: \(urlString)")
        }

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
            print("🟢 Opened Things URL")

            // Immediately hide Things and keep our panel focused
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                // Find Things app and hide it
                if let thingsApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.culturedcode.ThingsMac").first {
                    thingsApp.hide()
                    print("🟢 Hid Things app")
                }

                // Re-activate our app to keep panel visible
                NSApp.activate(ignoringOtherApps: true)
            }

            // Refresh tasks after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                print("🟢 Refreshing tasks...")
                self?.fetchTasks()
            }
        } else {
            print("🔴 Failed to create URL from: \(urlString)")
        }
    }

    func deleteTask(_ task: ThingsTask) {
        // Use Things URL scheme to delete (move to trash) task
        let urlString = "things:///update?id=\(task.id)&canceled=true&auth-token=\(ThingsConfig.authToken)"

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)

            // Immediately hide Things and keep our panel focused
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let thingsApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.culturedcode.ThingsMac").first {
                    thingsApp.hide()
                }
                NSApp.activate(ignoringOtherApps: true)
            }

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

    func renameTask(_ task: ThingsTask, newTitle: String) {
        // Use Things URL scheme to update task title
        let encodedTitle = newTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? newTitle
        if let url = URL(string: "things:///update?id=\(task.id)&title=\(encodedTitle)&auth-token=\(ThingsConfig.authToken)") {
            NSWorkspace.shared.open(url)

            // Immediately hide Things and keep our panel focused
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let thingsApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.culturedcode.ThingsMac").first {
                    thingsApp.hide()
                }
                NSApp.activate(ignoringOtherApps: true)
            }

            // Refresh tasks after a brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.fetchTasks()
            }
        }
    }

    func addTask(title: String, when: String = "today", list: String? = nil) {
        // Use Things URL scheme to create new task
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title

        var urlString = "things:///add?title=\(encodedTitle)&when=\(when)"

        // Add project/area if specified
        if let list = list, !list.isEmpty {
            let encodedList = list.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? list
            urlString += "&list=\(encodedList)"
        }

        urlString += "&auth-token=\(ThingsConfig.authToken)"

        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)

            // Immediately hide Things and keep our panel focused
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                if let thingsApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.culturedcode.ThingsMac").first {
                    thingsApp.hide()
                }
                NSApp.activate(ignoringOtherApps: true)
            }

            // Refresh tasks after a delay to allow Things to write to database
            // Multiple refreshes to catch the task as soon as it appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.fetchTasks()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.fetchTasks()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.fetchTasks()
            }
        }
    }
}

// MARK: - SQLite Error
enum SQLiteError: LocalizedError {
    case databaseNotFound
    case databaseLocked
    case queryFailed(String)

    var errorDescription: String? {
        switch self {
        case .databaseNotFound:
            return "Things database not found. Please make sure Things 3 is installed and has been launched at least once."
        case .databaseLocked:
            return "Things database is busy. Please try again in a moment."
        case .queryFailed(let message):
            return "Failed to query database: \(message)"
        }
    }
}

// MARK: - SQLite Helper
class SQLiteHelper {
    // MARK: - Table and Column Definitions
    private static let tasks = Table("TMTask")
    private static let tags = Table("TMTag")
    private static let taskTags = Table("TMTaskTag")
    private static let checklistItems = Table("TMChecklistItem")
    private static let areas = Table("TMArea")

    // TMTask columns
    private static let uuid = Expression<String>("uuid")
    private static let title = Expression<String>("title")
    private static let notes = Expression<String?>("notes")
    private static let status = Expression<Int64>("status")
    private static let start = Expression<Int64>("start")
    private static let todayIndex = Expression<Int64>("todayIndex")
    private static let todayIndexReferenceDate = Expression<Int64?>("todayIndexReferenceDate")
    private static let deadline = Expression<Int64?>("deadline")
    private static let projectUuid = Expression<String?>("project")
    private static let areaUuid = Expression<String?>("area")
    private static let trashed = Expression<Int64>("trashed")

    // Tag table columns
    private static let tagUuid = Expression<String>("uuid")
    private static let tagTitle = Expression<String>("title")

    // Junction table columns
    private static let taskTagTasks = Expression<String>("tasks")
    private static let taskTagTags = Expression<String>("tags")

    // Checklist columns
    private static let checklistUuid = Expression<String>("uuid")
    private static let checklistTitle = Expression<String>("title")
    private static let checklistStatus = Expression<Int64>("status")
    private static let checklistTask = Expression<String>("task")
    private static let checklistIndex = Expression<Int64>("stopIndex")

    // Area columns
    private static let areaUuidCol = Expression<String>("uuid")
    private static let areaTitleCol = Expression<String>("title")

    // MARK: - Database Path Discovery
    static func thingsDatabasePath() -> String? {
        // Direct hardcoded path to Things database
        // We know the exact path exists from testing
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let dbPath = "\(homeDir)/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac/ThingsData-RIMFH/Things Database.thingsdatabase/main.sqlite"

        // Verify the file exists
        if FileManager.default.fileExists(atPath: dbPath) {
            return dbPath
        }

        // Fallback: try to find it dynamically
        let basePath = "\(homeDir)/Library/Group Containers/JLMPQHK86H.com.culturedcode.ThingsMac"
        let fileManager = FileManager.default

        guard let contents = try? fileManager.contentsOfDirectory(atPath: basePath) else {
            return nil
        }

        // Find directory starting with "ThingsData-"
        for item in contents {
            if item.hasPrefix("ThingsData-") {
                let foundPath = "\(basePath)/\(item)/Things Database.thingsdatabase/main.sqlite"
                if fileManager.fileExists(atPath: foundPath) {
                    return foundPath
                }
            }
        }

        return nil
    }

    // MARK: - Main Query Method
    static func queryTodayTasks(retries: Int = 3) throws -> [ThingsTask] {
        var lastError: Error?

        for attempt in 0..<retries {
            do {
                return try performQuery()
            } catch let error as NSError where error.code == 5 { // SQLITE_BUSY
                lastError = error
                if attempt < retries - 1 {
                    Thread.sleep(forTimeInterval: 0.1) // Wait 100ms before retry
                }
            } catch {
                throw error // Rethrow non-lock errors immediately
            }
        }

        throw lastError ?? SQLiteError.queryFailed("Max retries exceeded")
    }

    private static func performQuery() throws -> [ThingsTask] {
        guard let dbPath = thingsDatabasePath() else {
            throw SQLiteError.databaseNotFound
        }

        let db = try Connection(dbPath, readonly: true)

        // Query today's tasks (tasks with a todayIndexReferenceDate are in the Today list)
        // Sort by todayIndex ascending (natural Things order - new tasks appear at bottom)
        let query = tasks
            .filter(status == 0 && trashed == 0 && todayIndexReferenceDate > 0)
            .order(todayIndex)

        var result: [ThingsTask] = []

        for row in try db.prepare(query) {
            let taskUuid = row[uuid]

            // Fetch related data
            let taskTags = try fetchTags(for: taskUuid, db: db)
            let checklist = try fetchChecklist(for: taskUuid, db: db)
            let areaTitle = try fetchAreaTitle(for: row[areaUuid], db: db)
            let projectTitle = try fetchProjectTitle(for: row[projectUuid], db: db)

            // Convert deadline timestamp (Core Data Reference Date: 2001-01-01)
            let deadlineDate = row[deadline].map { timestamp in
                Date(timeIntervalSinceReferenceDate: TimeInterval(timestamp))
            }

            // Map status code to enum
            let taskStatus: ThingsTask.TaskStatus
            switch row[status] {
            case 0: taskStatus = .incomplete
            case 3: taskStatus = .completed
            case 2: taskStatus = .canceled
            default: taskStatus = .incomplete
            }

            let task = ThingsTask(
                id: taskUuid,
                title: row[title],
                notes: row[notes],
                status: taskStatus,
                project: projectTitle,
                area: areaTitle,
                tags: taskTags,
                deadline: deadlineDate,
                when: "today",
                checklist: checklist
            )

            result.append(task)
        }

        return result
    }

    // MARK: - Helper Query Methods
    private static func fetchTags(for taskUuid: String, db: Connection) throws -> [String] {
        let query = tags
            .select(tagTitle)
            .join(taskTags, on: tagUuid == taskTagTags)
            .filter(taskTagTasks == taskUuid)

        return try db.prepare(query).map { $0[tagTitle] }
    }

    private static func fetchChecklist(for taskUuid: String, db: Connection) throws -> [ChecklistItem]? {
        let query = checklistItems
            .filter(checklistTask == taskUuid)
            .order(checklistIndex)

        let items = try db.prepare(query).map { row in
            ChecklistItem(
                id: row[checklistUuid],
                title: row[checklistTitle],
                completed: row[checklistStatus] == 3 // 3 = completed
            )
        }

        return items.isEmpty ? nil : items
    }

    private static func fetchAreaTitle(for uuid: String?, db: Connection) throws -> String? {
        guard let uuid = uuid else { return nil }

        let query = areas
            .select(areaTitleCol)
            .filter(areaUuidCol == uuid)

        if let row = try db.prepare(query).makeIterator().next() {
            return row[areaTitleCol]
        }
        return nil
    }

    private static func fetchProjectTitle(for uuid: String?, db: Connection) throws -> String? {
        guard let uuid = uuid else { return nil }

        // Projects are also stored in TMTask table
        let projectQuery = tasks
            .select(title)
            .filter(self.uuid == uuid)

        if let row = try db.prepare(projectQuery).makeIterator().next() {
            return row[title]
        }
        return nil
    }

    // MARK: - Mock Data (for testing/fallback)
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
