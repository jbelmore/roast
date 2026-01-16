import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentStep = 0
    @State private var apiKey = ""
    let onComplete: () -> Void

    private let steps = ["Welcome", "Permissions", "API Key", "Ready"]

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)

            // Content
            TabView(selection: $currentStep) {
                WelcomeStep(onNext: nextStep)
                    .tag(0)

                PermissionsStep(onNext: nextStep)
                    .tag(1)

                APIKeyStep(apiKey: $apiKey, onNext: nextStep)
                    .tag(2)

                ReadyStep(onComplete: completeOnboarding)
                    .tag(3)
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 500, height: 600)
    }

    private func nextStep() {
        withAnimation {
            currentStep += 1
        }
    }

    private func completeOnboarding() {
        // Save API key if provided
        if !apiKey.isEmpty {
            _ = KeychainHelper.saveAPIKey(apiKey)
            appState.apiKeyConfigured = true
        }

        // Mark onboarding complete
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        UserDefaults.standard.set(true, forKey: "trackingEnabled")

        onComplete()
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "eye.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            VStack(spacing: 12) {
                Text("Welcome to Roast")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("A brutally honest productivity analyzer that tells you the truth about your computer usage patterns.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "clock", title: "Track Patterns", description: "Monitor which apps you use and how you switch between them")

                FeatureRow(icon: "brain", title: "Detect Behaviors", description: "Identify compulsive checking, fragmented hours, and deep work")

                FeatureRow(icon: "sparkles", title: "AI Analysis", description: "Get weekly reports with honest, actionable insights")

                FeatureRow(icon: "lock.shield", title: "100% Private", description: "All data stays on your Mac. Nothing leaves your computer.")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button(action: onNext) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Permissions Step

struct PermissionsStep: View {
    let onNext: () -> Void
    @State private var hasAccessibility = AccessibilityHelper.hasAccessibilityPermission

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.raised.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            VStack(spacing: 12) {
                Text("Permission Required")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Roast needs accessibility permission to accurately track which app is active.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 16) {
                HStack {
                    Image(systemName: hasAccessibility ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(hasAccessibility ? .green : .secondary)

                    Text("Accessibility Access")
                        .font(.callout)

                    Spacer()

                    if !hasAccessibility {
                        Button("Grant") {
                            AccessibilityHelper.requestAccessibilityPermission()
                            // Check again after a delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                hasAccessibility = AccessibilityHelper.hasAccessibilityPermission
                            }
                        }
                        .controlSize(.small)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                )
            }
            .padding(.horizontal, 40)

            Text("This permission allows the app to detect which application is currently active. It does not read your keystrokes or screen content.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: onNext) {
                Text(hasAccessibility ? "Continue" : "Skip for Now")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .onAppear {
            // Start a timer to check permissions periodically
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                hasAccessibility = AccessibilityHelper.hasAccessibilityPermission
                if hasAccessibility {
                    timer.invalidate()
                }
            }
        }
    }
}

// MARK: - API Key Step

struct APIKeyStep: View {
    @Binding var apiKey: String
    let onNext: () -> Void
    @State private var isKeyVisible = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)

            VStack(spacing: 12) {
                Text("Claude API Key")
                    .font(.title)
                    .fontWeight(.bold)

                Text("To generate AI-powered weekly reports, you'll need a Claude API key from Anthropic.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(spacing: 12) {
                HStack {
                    if isKeyVisible {
                        TextField("sk-ant-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("sk-ant-...", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }

                    Button(action: { isKeyVisible.toggle() }) {
                        Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }

                Link("Get an API key from Anthropic Console",
                     destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                    .font(.caption)
            }
            .padding(.horizontal, 40)

            Text("Your API key is stored securely in the macOS Keychain and is only used to communicate with the Claude API.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button(action: onNext) {
                Text(apiKey.isEmpty ? "Skip for Now" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Ready Step

struct ReadyStep: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Roast is ready to start tracking your computer usage. Look for the eye icon in your menu bar.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            VStack(alignment: .leading, spacing: 12) {
                TipRow(icon: "clock", tip: "Check the Today tab for real-time stats")
                TipRow(icon: "doc.text", tip: "Generate your first weekly report after a few days of use")
                TipRow(icon: "gear", tip: "Customize excluded apps in Settings")
            }
            .padding(.horizontal, 40)

            Spacer()

            Button(action: onComplete) {
                Text("Start Using Roast")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

struct TipRow: View {
    let icon: String
    let tip: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)

            Text(tip)
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
        .environmentObject(AppState.shared)
}
