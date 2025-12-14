import SwiftUI

struct TaskRowView: View {
    let task: ThingsTask
    let onToggle: (ThingsTask) -> Void
    let onTap: (ThingsTask) -> Void
    let onRename: (ThingsTask, String) -> Void
    let onDelete: (ThingsTask) -> Void

    @State private var isHovered = false
    @State private var isPressed = false
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var isSelected = false
    @FocusState private var isFocused: Bool
    @FocusState private var isTaskFocused: Bool

    var body: some View {
        taskContent
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(backgroundView)
            .overlay(selectionBorder)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .focusable()
            .focused($isTaskFocused)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHovered = hovering
                }
            }
            .simultaneousGesture(pressGesture)
            .onTapGesture(perform: selectTask)
            .onChange(of: isTaskFocused, perform: updateSelection)
            .onKeyPress(.delete, action: handleDelete)
    }

    private var taskContent: some View {
        HStack(alignment: .top, spacing: 12) {
            // Checkbox
            CheckboxView(isCompleted: task.isCompleted) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    onToggle(task)
                }
            }

            // Task content - title (editable on double-click)
            if isEditing {
                editingField
            } else {
                taskTitle
            }
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
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    private var selectionBorder: some View {
        RoundedRectangle(cornerRadius: 6)
            .stroke(Color.thingsBlue.opacity(isSelected ? 0.3 : 0), lineWidth: isSelected ? 1.5 : 0)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var pressGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in isPressed = true }
            .onEnded { _ in isPressed = false }
    }

    private func selectTask() {
        isTaskFocused = true
        isSelected = true
    }

    private func updateSelection(focused: Bool) {
        isSelected = focused
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }

            // Haptic feedback on macOS
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)

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
