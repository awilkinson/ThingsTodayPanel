import SwiftUI

struct TaskRowView: View {
    let task: ThingsTask
    let onToggle: (ThingsTask) -> Void
    let onTap: (ThingsTask) -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        Button(action: { onTap(task) }) {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                CheckboxView(isCompleted: task.isCompleted) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        onToggle(task)
                    }
                }

                // Task content - title only
                Text(task.title)
                    .font(.system(size: 14, weight: task.isCompleted ? .regular : .medium))
                    .foregroundColor(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted, color: .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.thingsHover : Color.clear)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Checkbox View
struct CheckboxView: View {
    let isCompleted: Bool
    let onToggle: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: {
            onToggle()
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

                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(isHovered ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
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
