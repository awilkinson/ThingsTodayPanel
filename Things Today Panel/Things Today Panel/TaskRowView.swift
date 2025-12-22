import SwiftUI
import Combine

struct TaskRowView: View {
    let task: ThingsTask
    @ObservedObject var navigationController: NavigationController
    let onToggle: (ThingsTask) -> Void
    let onTap: (ThingsTask) -> Void
    let onRename: (ThingsTask, String) -> Void
    let onDelete: (ThingsTask) -> Void

    @State private var isHovered = false
    @State private var isEditing = false
    @State private var editedTitle = ""
    @FocusState private var isFocused: Bool
    @FocusState private var isTaskFocused: Bool

    // Computed property to check if this task is selected by keyboard navigation
    private var isSelected: Bool {
        navigationController.selectedTaskId == task.id || isTaskFocused
    }

    var body: some View {
        taskContent
            .padding(.vertical, .spacingSM)    // 8pt - better density
            .padding(.horizontal, .spacingMD)   // 12pt - maintains comfort
            .background(backgroundView)
            .overlay(alignment: .leading) {
                // Subtle left accent bar when selected
                if isSelected {
                    Rectangle()
                        .fill(Color.thingsBlue)
                        .frame(width: 3)
                        .cornerRadius(1.5)
                        .transition(.opacity)
                }
            }
            .focusable()
            .focused($isTaskFocused)
            .focusEffectDisabled() // Disable the harsh blue system focus ring
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .onChange(of: isTaskFocused, perform: updateSelection)
            .onKeyPress(.delete, action: handleDelete)
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ClearFocus"))) { _ in
                isTaskFocused = false
            }
    }

    private var taskContent: some View {
        HStack(alignment: .center, spacing: .spacingMD) {
            // Checkbox - has its own button action
            CheckboxView(isCompleted: task.isCompleted) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onToggle(task)
                }
            }
            .allowsHitTesting(true) // Ensure checkbox can receive clicks
            .zIndex(1) // Keep checkbox above other gesture layers

            // Task content - title (editable on double-click)
            // Apply tap gesture only to the text, not the checkbox
            Group {
                if isEditing {
                    editingField
                } else {
                    taskTitle
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: selectTask)
        }
    }

    private var editingField: some View {
        TextField("Task title", text: $editedTitle, onCommit: {
            saveEdit()
        })
        .focused($isFocused)
        .font(.system(size: 14, weight: .medium))
        .textFieldStyle(PlainTextFieldStyle())
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            editedTitle = task.title
            isFocused = true
        }
        .onExitCommand {
            cancelEdit()
        }
    }

    private var taskTitle: some View {
        Text(task.title)
            .font(.system(size: 14, weight: task.isCompleted ? .regular : .medium))
            .foregroundColor(task.isCompleted ? .secondary : .primary)
            .strikethrough(task.isCompleted, color: .secondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .onTapGesture(count: 2) {
                if !task.isCompleted {
                    isEditing = true
                }
            }
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(isSelected ? Color.thingsBlue.opacity(0.08) : (isHovered ? Color.thingsHover : Color.clear))
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    private func selectTask() {
        isTaskFocused = true
        navigationController.selectedTaskId = task.id
    }

    private func updateSelection(focused: Bool) {
        if focused {
            navigationController.selectedTaskId = task.id
        }
    }

    private func handleDelete() -> KeyPress.Result {
        if isTaskFocused && !isEditing {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                onDelete(task)
            }
            return .handled
        }
        return .ignored
    }

    private func saveEdit() {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && trimmed != task.title {
            onRename(task, trimmed)
        }
        isEditing = false
    }

    private func cancelEdit() {
        isEditing = false
        editedTitle = task.title
    }
}

// MARK: - Checkbox View
struct CheckboxView: View {
    let isCompleted: Bool
    let onToggle: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            print("🔵 CheckboxView button clicked!")
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }

            // Haptic feedback on macOS
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)

            print("🔵 Calling onToggle()")
            onToggle()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }) {
            ZStack {
                Circle()
                    .strokeBorder(
                        isCompleted ? Color.thingsBlue : Color.secondary.opacity(0.3),
                        lineWidth: 2
                    )
                    .background(
                        Circle()
                            .fill(isCompleted ? Color.thingsBlue : Color.clear)
                    )
                    .frame(width: 20, height: 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale(scale: 0.5).combined(with: .opacity))
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isCompleted)
                }
            }
            .scaleEffect(isPressed ? 0.9 : (isHovered ? 1.1 : 1.0))
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .frame(width: 44, height: 44) // Larger button frame
        .contentShape(Rectangle()) // Make entire button area clickable
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Deadline Label
struct DeadlineLabel: View {
    let deadline: Date
    let isOverdue: Bool

    var body: some View {
        Label(formattedDeadline, systemImage: "calendar")
            .font(.system(size: 11))
            .foregroundColor(isOverdue ? .thingsDanger : .thingsSecondary)
    }

    var formattedDeadline: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(deadline) {
            return "Today"
        } else if calendar.isDateInTomorrow(deadline) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: deadline)
        }
    }
}
