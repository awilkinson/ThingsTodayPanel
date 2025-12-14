import SwiftUI

struct ContentView: View {
    @StateObject private var dataService = ThingsDataService()
    @State private var searchText = ""

    var filteredTasks: [ThingsTask] {
        if searchText.isEmpty {
            return dataService.tasks
        }
        return dataService.tasks.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var incompleteTasks: [ThingsTask] {
        filteredTasks.filter { task in
            !task.isCompleted && (task.project == "💻 Computer" || task.project == "⏳ Deep Work")
        }
    }

    var completedTasks: [ThingsTask] {
        filteredTasks.filter { $0.isCompleted }
    }

    // Group incomplete tasks by project
    var tasksByProject: [String: [ThingsTask]] {
        Dictionary(grouping: incompleteTasks) { task in
            task.project ?? task.area ?? "No Project"
        }
    }

    var sortedProjectNames: [String] {
        let customOrder = ["💻 Computer", "⏳ Deep Work", "🏠 Home", "🚗 Out and About", "Calls"]
        let projectNames = Array(tasksByProject.keys)

        // Sort with custom order first, then alphabetically for others
        return projectNames.sorted { proj1, proj2 in
            let index1 = customOrder.firstIndex(of: proj1)
            let index2 = customOrder.firstIndex(of: proj2)

            switch (index1, index2) {
            case let (i1?, i2?):
                return i1 < i2  // Both in custom order
            case (_?, nil):
                return true     // proj1 in custom order, proj2 not
            case (nil, _?):
                return false    // proj2 in custom order, proj1 not
            case (nil, nil):
                return proj1 < proj2  // Neither in custom order, sort alphabetically
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
                // Header
                HeaderView(taskCount: incompleteTasks.count, onRefresh: {
                    withAnimation {
                        dataService.fetchTasks()
                    }
                })

                Divider()
                    .opacity(0.3)

                // Error banner
                if let errorMessage = dataService.errorMessage {
                    ErrorBannerView(message: errorMessage, onDismiss: {
                        dataService.errorMessage = nil
                    })
                }

                // Task list
                if dataService.isLoading && dataService.tasks.isEmpty {
                    LoadingView()
                } else if filteredTasks.isEmpty {
                    EmptyStateView(hasSearch: !searchText.isEmpty)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            // Tasks grouped by project
                            if !incompleteTasks.isEmpty {
                                ForEach(sortedProjectNames, id: \.self) { projectName in
                                    if let tasks = tasksByProject[projectName] {
                                        TasksSection(
                                            title: projectName,
                                            tasks: tasks,
                                            dataService: dataService
                                        )
                                    }
                                }
                            }

                            // Completed tasks (collapsible)
                            if !completedTasks.isEmpty {
                                CompletedTasksSection(
                                    tasks: completedTasks,
                                    dataService: dataService
                                )
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.bottom, 60)  // Add space for sticky footer
                    }
                }

                // Sticky "New Task" button at bottom
                StickyNewTaskButton(dataService: dataService)
            }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let taskCount: Int
    let onRefresh: () -> Void

    @State private var isRefreshing = false
    @State private var showSettings = false

    var body: some View {
        HStack(spacing: 8) {
            // Title
            VStack(alignment: .leading, spacing: 1) {
                Text("Today")
                    .font(.system(size: 20, weight: .bold, design: .default))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if taskCount > 0 {
                    Text("\(taskCount) task\(taskCount == 1 ? "" : "s")")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            // Settings button
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Settings")
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }

            // Refresh button
            Button(action: {
                isRefreshing = true
                onRefresh()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isRefreshing = false
                }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(.linear(duration: 0.5).repeatCount(isRefreshing ? 10 : 1, autoreverses: false), value: isRefreshing)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Refresh tasks")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Tasks Section
struct TasksSection: View {
    let title: String
    let tasks: [ThingsTask]
    let dataService: ThingsDataService

    @State private var deletedTaskIds: Set<String> = []

    var visibleTasks: [ThingsTask] {
        tasks.filter { !deletedTaskIds.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Project name header
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 4)

            ForEach(visibleTasks) { task in
                TaskRowView(
                    task: task,
                    onToggle: { task in
                        dataService.toggleTask(task)
                    },
                    onTap: { task in
                        dataService.openTaskInThings(task)
                    },
                    onRename: { task, newTitle in
                        dataService.renameTask(task, newTitle: newTitle)
                    },
                    onDelete: { task in
                        // Optimistic deletion - remove from UI immediately
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            deletedTaskIds.insert(task.id)
                        }
                        dataService.deleteTask(task)

                        // Clear deleted IDs after refresh completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            deletedTaskIds.remove(task.id)
                        }
                    }
                )
                .padding(.horizontal, 4)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
    }
}

// MARK: - Completed Tasks Section
struct CompletedTasksSection: View {
    let tasks: [ThingsTask]
    let dataService: ThingsDataService

    @State private var isExpanded = false
    @State private var deletedTaskIds: Set<String> = []

    var visibleTasks: [ThingsTask] {
        tasks.filter { !deletedTaskIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Section header (collapsible)
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)

                    Text("Completed")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)

                    Spacer()

                    Text("\(visibleTasks.count)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                ForEach(visibleTasks) { task in
                    TaskRowView(
                        task: task,
                        onToggle: { task in
                            dataService.toggleTask(task)
                        },
                        onTap: { task in
                            dataService.openTaskInThings(task)
                        },
                        onRename: { task, newTitle in
                            dataService.renameTask(task, newTitle: newTitle)
                        },
                        onDelete: { task in
                            // Optimistic deletion - remove from UI immediately
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                deletedTaskIds.insert(task.id)
                            }
                            dataService.deleteTask(task)

                            // Clear deleted IDs after refresh completes
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                deletedTaskIds.remove(task.id)
                            }
                        }
                    )
                    .padding(.horizontal, 4)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.95)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
                }
            }
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let hasSearch: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.thingsBlue.opacity(0.5))

            VStack(spacing: 4) {
                Text(hasSearch ? "No tasks found" : "All done for today!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(hasSearch ? "Try a different search" : "Enjoy your day")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(0.8)

            Text("Loading tasks...")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Footer View
struct FooterView: View {
    @EnvironmentObject var dataService: ThingsDataService
    @State private var newTaskTitle = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(isFocused ? .thingsBlue : .secondary)

            TextField("New To-Do", text: $newTaskTitle, onCommit: {
                addTask()
            })
            .focused($isFocused)
            .font(.system(size: 13, weight: .medium))
            .textFieldStyle(PlainTextFieldStyle())
            .frame(maxWidth: .infinity)

            if !newTaskTitle.isEmpty {
                Button(action: {
                    addTask()
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.thingsBlue)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isFocused ? Color.thingsHover.opacity(0.5) : Color.clear)
    }

    private func addTask() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            dataService.addTask(title: trimmed)
            newTaskTitle = ""
        }
    }
}

// MARK: - Error Banner View
struct ErrorBannerView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Error Loading Tasks")
                        .font(.system(size: 12, weight: .semibold))

                    Text(message)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Show "Open Settings" button if it's a permission error
            if message.contains("Permission needed") {
                Button(action: {
                    // Open System Settings to Privacy & Security
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    Text("Open System Settings")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange)
                        .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.1))
    }
}

// MARK: - Sticky New Task Button
struct StickyNewTaskButton: View {
    let dataService: ThingsDataService

    @State private var isExpanded = false
    @State private var newTaskTitle = ""
    @State private var selectedProject = "💻 Computer"
    @State private var isSubmitting = false
    @State private var pendingTaskTitle: String?
    @FocusState private var isFocused: Bool

    let availableProjects = ["💻 Computer", "⏳ Deep Work"]

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.3)

            if isExpanded {
                // Expanded state with text field and project picker
                VStack(spacing: 8) {
                    // Text field
                    HStack(spacing: 12) {
                        Circle()
                            .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 2)
                            .frame(width: 20, height: 20)

                        TextField("New task", text: $newTaskTitle, onCommit: {
                            addTask()
                        })
                        .focused($isFocused)
                        .font(.system(size: 14, weight: .medium))
                        .textFieldStyle(PlainTextFieldStyle())
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isFocused = true
                            }
                        }
                        .onChange(of: isFocused) { focused in
                            // If focus is lost and field is empty, collapse
                            if !focused && newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isExpanded = false
                                }
                            }
                        }
                        .onExitCommand {
                            cancelAdd()
                        }
                    }

                    // Project picker
                    HStack(spacing: 8) {
                        Text("Add to:")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)

                        Menu {
                            ForEach(availableProjects, id: \.self) { project in
                                Button(action: {
                                    selectedProject = project
                                }) {
                                    HStack {
                                        Text(project)
                                        if selectedProject == project {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedProject)
                                    .font(.system(size: 11, weight: .medium))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.thingsBlue)
                        }
                        .menuStyle(BorderlessButtonMenuStyle())

                        Spacer()

                        // Submit button
                        if !newTaskTitle.isEmpty {
                            Button(action: {
                                addTask()
                            }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.thingsBlue)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal: .opacity
                ))
            } else {
                // Collapsed state - just a button
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded = true
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.thingsBlue)

                        Text("New Task")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.opacity)
            }
        }
        .background(.ultraThinMaterial)
    }

    private func addTask() {
        guard !isSubmitting else { return }

        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSubmitting = true

        // Show pending task immediately
        pendingTaskTitle = trimmed

        // Add task to the selected project
        dataService.addTask(title: trimmed, when: "today", list: selectedProject)

        // Clear and collapse
        newTaskTitle = ""
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded = false
        }

        // Clear pending task after refresh completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            pendingTaskTitle = nil
            isSubmitting = false
        }
    }

    private func cancelAdd() {
        newTaskTitle = ""
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            isExpanded = false
        }
        pendingTaskTitle = nil
        isSubmitting = false
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .frame(width: 360, height: 520)
    }
}
