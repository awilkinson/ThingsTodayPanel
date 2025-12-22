import SwiftUI
import Carbon

struct HotkeyRecorderView: View {
    @Binding var keyCode: UInt32
    @Binding var modifiers: UInt32
    @State private var isRecording = false

    var body: some View {
        Button(action: {
            isRecording = true
        }) {
            HStack {
                Text(isRecording ? "Press keys..." : displayString)
                    .font(.system(size: 13))
                    .foregroundColor(isRecording ? .secondary : .primary)
                    .frame(minWidth: 100, alignment: .center)

                if !isRecording {
                    Image(systemName: "keyboard")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isRecording ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isRecording ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onKeyPress { press in
            guard isRecording else { return .ignored }

            // Capture the key press
            keyCode = UInt32(press.key.character.unicodeScalars.first?.value ?? 0)

            // Convert SwiftUI modifiers to Carbon modifiers
            var carbonModifiers: UInt32 = 0
            if press.modifiers.contains(.command) {
                carbonModifiers |= UInt32(cmdKey)
            }
            if press.modifiers.contains(.shift) {
                carbonModifiers |= UInt32(shiftKey)
            }
            if press.modifiers.contains(.option) {
                carbonModifiers |= UInt32(optionKey)
            }
            if press.modifiers.contains(.control) {
                carbonModifiers |= UInt32(controlKey)
            }

            modifiers = carbonModifiers
            isRecording = false

            // Post notification that hotkey changed
            NotificationCenter.default.post(name: NSNotification.Name("HotkeyChanged"), object: nil)

            return .handled
        }
    }

    var displayString: String {
        var result = ""

        // Build modifier string
        if modifiers & UInt32(controlKey) != 0 {
            result += "⌃"
        }
        if modifiers & UInt32(optionKey) != 0 {
            result += "⌥"
        }
        if modifiers & UInt32(shiftKey) != 0 {
            result += "⇧"
        }
        if modifiers & UInt32(cmdKey) != 0 {
            result += "⌘"
        }

        // Add key character
        if let scalar = UnicodeScalar(keyCode) {
            result += String(Character(scalar)).uppercased()
        }

        return result.isEmpty ? "Click to set" : result
    }
}
