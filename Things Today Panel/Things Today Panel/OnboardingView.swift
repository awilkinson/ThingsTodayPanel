import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var authToken: String = ""
    @State private var showError: Bool = false
    @FocusState private var isTokenFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.thingsBlue)
                    .padding(.top, 40)

                Text("Welcome to Things Today Panel")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("Your Things tasks, always visible")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)

            // Instructions
            VStack(alignment: .leading, spacing: 20) {
                InstructionStep(
                    number: "1",
                    title: "Open Things 3",
                    description: "Launch the Things app on your Mac"
                )

                InstructionStep(
                    number: "2",
                    title: "Get Your Auth Token",
                    description: "Settings → General → Enable Things URLs → Manage → Copy token"
                )

                InstructionStep(
                    number: "3",
                    title: "Paste Below",
                    description: "Enter your authentication token to connect"
                )
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)

            // Token input
            VStack(alignment: .leading, spacing: 8) {
                Text("Authentication Token")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)

                TextField("Paste your Things auth token here", text: $authToken)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 13, design: .monospaced))
                    .focused($isTokenFieldFocused)
                    .onAppear {
                        // Auto-focus the text field
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isTokenFieldFocused = true
                        }
                    }

                if showError {
                    Label("Please enter a valid token", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 32)

            Spacer()

            // Actions
            HStack(spacing: 12) {
                Button("Skip for Now") {
                    skipOnboarding()
                }
                .buttonStyle(SecondaryButtonStyle())

                Button("Continue") {
                    completeOnboarding()
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(authToken.isEmpty)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(width: 520, height: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func completeOnboarding() {
        guard !authToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError = true
            return
        }

        // Save token to UserDefaults
        UserDefaults.standard.thingsAuthToken = authToken.trimmingCharacters(in: .whitespacesAndNewlines)
        UserDefaults.standard.hasCompletedOnboarding = true

        // Close onboarding
        isPresented = false
    }

    private func skipOnboarding() {
        // Mark onboarding as complete but no token
        UserDefaults.standard.hasCompletedOnboarding = true
        isPresented = false
    }
}

// MARK: - Instruction Step Component
struct InstructionStep: View {
    let number: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Number badge
            ZStack {
                Circle()
                    .fill(Color.thingsBlue.opacity(0.1))
                    .frame(width: 32, height: 32)

                Text(number)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.thingsBlue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.thingsBlue)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
