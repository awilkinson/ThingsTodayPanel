import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var authToken: String = UserDefaults.standard.thingsAuthToken ?? ""
    @State private var refreshInterval: Double = UserDefaults.standard.refreshInterval
    @State private var showSaved: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.system(size: 20, weight: .bold))
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)

            Divider()

            // Settings content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Things Integration Section
                    SettingsSection(title: "Things Integration") {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Authentication Token")
                                .font(.system(size: 13, weight: .medium))

                            TextField("Paste your Things auth token", text: $authToken)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(size: 12, design: .monospaced))

                            Text("Get your token from Things → Settings → General → Enable Things URLs → Manage")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Refresh Settings Section
                    SettingsSection(title: "Refresh Settings") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Auto-refresh interval")
                                    .font(.system(size: 13, weight: .medium))
                                Spacer()
                                Text("\(Int(refreshInterval))s")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }

                            Slider(value: $refreshInterval, in: 30...300, step: 30)
                                .controlSize(.small)

                            Text("Tasks will automatically refresh every \(Int(refreshInterval)) seconds")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }

                    // About Section
                    SettingsSection(title: "About") {
                        VStack(alignment: .leading, spacing: 8) {
                            InfoRow(label: "Version", value: "1.0.0")
                            InfoRow(label: "Author", value: "Andrew Wilkinson")

                            Link(destination: URL(string: "https://github.com/awilkinson/ThingsTodayPanel")!) {
                                HStack {
                                    Text("GitHub Repository")
                                        .font(.system(size: 13))
                                    Image(systemName: "arrow.up.forward")
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(.thingsBlue)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }

            Divider()

            // Footer actions
            HStack {
                if showSaved {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Saved!")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity)
                }

                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveSettings()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
        }
        .frame(width: 480, height: 500)
    }

    private func saveSettings() {
        // Save to UserDefaults
        UserDefaults.standard.thingsAuthToken = authToken.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.refreshInterval = refreshInterval

        // Show saved indicator
        withAnimation {
            showSaved = true
        }

        // Hide after 2 seconds and close
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSaved = false
            }
            dismiss()
        }
    }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            content
        }
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
    }
}
