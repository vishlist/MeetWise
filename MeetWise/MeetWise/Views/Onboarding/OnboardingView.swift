import SwiftUI
import SwiftData
import AVFoundation
import ScreenCaptureKit
import UserNotifications

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @Environment(\.modelContext) private var modelContext
    @State private var currentStep = 0
    @State private var fullName = ""
    @State private var role = ""
    @State private var focusAreas = ""
    @State private var screenRecordingGranted = false
    @State private var microphoneGranted = false
    @State private var calendarGranted = false
    @State private var notificationsGranted = false
    @State private var deepgramKey = ""
    @State private var anthropicKey = ""
    @State private var openAIKey = ""

    private let totalSteps = 6

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Theme.accent : Theme.bgCard)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 40)

            Spacer()

            switch currentStep {
            case 0: welcomeStep
            case 1: screenRecordingStep
            case 2: calendarStep
            case 3: apiKeysStep
            case 4: profileStep
            case 5: tipsStep
            default: tipsStep
            }

            Spacer()

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation { currentStep -= 1 }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                if currentStep == 3 {
                    Button("Skip") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.trailing, 8)
                }

                Button {
                    if currentStep < totalSteps - 1 {
                        withAnimation { currentStep += 1 }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentStep == totalSteps - 1 ? "Get Started" : "Continue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(Theme.radiusPill)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 40)
        }
        .frame(width: 550, height: 550)
        .background(Theme.bgPrimary)
    }

    // MARK: - Step 1: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)

            Text("Welcome to MeetWise")
                .font(.heading(28))
                .foregroundStyle(Theme.textHeading)

            Text("AI-powered meeting notes that work in the background.\nNo bots, no recordings visible to participants.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Step 2: Screen Recording Permission
    private var screenRecordingStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screen Recording")
                .font(.heading(24))
                .foregroundStyle(Theme.textHeading)

            Text("MeetWise captures system audio from meeting apps. This requires Screen Recording permission.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 12) {
                permissionRow(
                    icon: "rectangle.inset.filled.and.person.filled",
                    title: "Screen Recording",
                    description: "Required to capture system audio from meeting apps",
                    isGranted: screenRecordingGranted,
                    action: requestScreenRecording
                )

                permissionRow(
                    icon: "mic",
                    title: "Microphone",
                    description: "Captures your voice during meetings",
                    isGranted: microphoneGranted,
                    action: requestMicrophone
                )
            }

            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
                Text("You can also grant these in System Settings > Privacy & Security")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
            }

            Button {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            } label: {
                Text("Open System Settings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.1))
                    .cornerRadius(Theme.radiusSM)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Step 3: Calendar Access
    private var calendarStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Calendar Access")
                .font(.heading(24))
                .foregroundStyle(Theme.textHeading)

            Text("MeetWise shows upcoming meetings and auto-detects when you join a call.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 12) {
                permissionRow(
                    icon: "calendar",
                    title: "Calendar",
                    description: "Shows upcoming meetings and attendees",
                    isGranted: calendarGranted,
                    action: requestCalendar
                )

                permissionRow(
                    icon: "bell",
                    title: "Notifications",
                    description: "Alerts you before meetings start",
                    isGranted: notificationsGranted,
                    action: requestNotifications
                )
            }
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Step 4: API Keys
    private var apiKeysStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("API Keys")
                .font(.heading(24))
                .foregroundStyle(Theme.textHeading)

            Text("Enter API keys for transcription and AI features. You can skip this and add them later in Settings.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 16) {
                apiKeyField(title: "Deepgram", placeholder: "dg-...", binding: $deepgramKey, description: "For real-time transcription")
                apiKeyField(title: "Anthropic", placeholder: "sk-ant-...", binding: $anthropicKey, description: "For AI enhancement & chat")
                apiKeyField(title: "OpenAI (optional)", placeholder: "sk-...", binding: $openAIKey, description: "For embeddings search")
            }
        }
        .padding(.horizontal, 48)
    }

    private func apiKeyField(title: String, placeholder: String, binding: Binding<String>, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(description)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
            }
            SecureField(placeholder, text: binding)
                .textFieldStyle(.plain)
                .font(.system(size: 13, design: .monospaced))
                .padding(8)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Theme.border, lineWidth: 1))
        }
    }

    // MARK: - Step 5: Profile
    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About you")
                .font(.heading(24))
                .foregroundStyle(Theme.textHeading)

            Text("This helps MeetWise provide more relevant insights.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Full Name")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    TextField("e.g. Vishal Adhlakha", text: $fullName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(Theme.bgCard)
                        .cornerRadius(Theme.radiusSM)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Role")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    TextField("e.g. Product Designer, CEO, Engineer", text: $role)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(Theme.bgCard)
                        .cornerRadius(Theme.radiusSM)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Focus Areas")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    TextField("e.g. design, strategy, client management", text: $focusAreas)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .padding(10)
                        .background(Theme.bgCard)
                        .cornerRadius(Theme.radiusSM)
                }
            }
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Step 6: Quick Tips
    private var tipsStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)

            Text("You're all set!")
                .font(.heading(28))
                .foregroundStyle(Theme.textHeading)

            Text("Join a meeting and MeetWise will automatically\nstart capturing and transcribing.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 10) {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)

                shortcutRow(keys: "J", description: "Toggle AI chat sidebar")
                shortcutRow(keys: "K", description: "Search all meetings")
                shortcutRow(keys: "N", description: "Create quick note")
            }
            .padding(20)
            .background(Theme.bgCard.opacity(0.5))
            .cornerRadius(Theme.radiusMD)

            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "sparkles", text: "Click \"Enhance Notes\" after meetings")
                tipRow(icon: "waveform", text: "MeetWise auto-detects meeting windows")
                tipRow(icon: "person.2", text: "People are auto-extracted from transcripts")
            }
        }
        .padding(.horizontal, 48)
    }

    private func shortcutRow(keys: String, description: String) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 2) {
                Text("Cmd")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Theme.bgCard)
                    .cornerRadius(3)
                Text("+")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)
                Text(keys)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Theme.bgCard)
                    .cornerRadius(3)
            }
            Text(description)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Permission Row
    private func permissionRow(icon: String, title: String, description: String, isGranted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isGranted ? Theme.accent : Theme.textSecondary)
                .frame(width: 32, height: 32)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(description)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.accent)
            } else {
                Button("Grant") { action() }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Theme.border, lineWidth: 1))
                    .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Theme.bgCard.opacity(0.5))
        .cornerRadius(Theme.radiusMD)
    }

    // MARK: - Permission Requests
    private func requestScreenRecording() {
        Task {
            do {
                _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
                screenRecordingGranted = true
            } catch {
                print("[Onboarding] Screen recording: \(error)")
            }
        }
    }

    private func requestMicrophone() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async { microphoneGranted = granted }
        }
    }

    private func requestCalendar() {
        Task {
            let calService = CalendarService()
            await calService.requestAccess()
            calendarGranted = calService.isAuthorized
        }
    }

    private func requestNotifications() {
        Task {
            await NotificationService.shared.requestPermission()
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            notificationsGranted = settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Complete
    private func completeOnboarding() {
        // Save API keys if provided
        if !deepgramKey.trimmingCharacters(in: .whitespaces).isEmpty {
            UserDefaults.standard.set(deepgramKey.trimmingCharacters(in: .whitespaces), forKey: "deepgramAPIKey")
        }
        if !anthropicKey.trimmingCharacters(in: .whitespaces).isEmpty {
            UserDefaults.standard.set(anthropicKey.trimmingCharacters(in: .whitespaces), forKey: "anthropicAPIKey")
        }
        if !openAIKey.trimmingCharacters(in: .whitespaces).isEmpty {
            UserDefaults.standard.set(openAIKey.trimmingCharacters(in: .whitespaces), forKey: "openAIAPIKey")
        }

        // Save profile
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        if let profile = profiles.first {
            profile.fullName = fullName.isEmpty ? "User" : fullName
            profile.role = role.isEmpty ? nil : role
            profile.focusAreas = focusAreas.isEmpty ? nil : focusAreas
        }
        try? modelContext.save()

        // Seed recipes
        seedRecipesIfNeeded()

        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        isComplete = true
    }

    private func seedRecipesIfNeeded() {
        let descriptor = FetchDescriptor<Recipe>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let builtIn = RecipeService.builtInRecipes
        for (index, template) in builtIn.enumerated() {
            let recipe = Recipe(
                name: template.name,
                prompt: template.prompt,
                iconColor: "#ffffff",
                category: "builtin"
            )
            recipe.position = index
            modelContext.insert(recipe)
        }
        try? modelContext.save()
    }
}
