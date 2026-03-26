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
    @State private var screenRecordingGranted = false
    @State private var microphoneGranted = false
    @State private var calendarGranted = false
    @State private var notificationsGranted = false

    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Theme.accent : Theme.accentSoft)
                        .frame(width: 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
                }
            }
            .padding(.top, 40)

            Spacer()

            switch currentStep {
            case 0: welcomeStep
            case 1: permissionsStep
            case 2: calendarStep
            case 3: profileStep
            case 4: tipsStep
            default: tipsStep
            }

            Spacer()

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { currentStep -= 1 }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Button {
                    if currentStep < totalSteps - 1 {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { currentStep += 1 }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentStep == totalSteps - 1 ? "Get Started" : "Continue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Theme.accent)
                        .cornerRadius(Theme.radiusPill)
                }
                .buttonStyle(.plain)
                .hoverScale(1.05)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 40)
        }
        .frame(width: 550, height: 550)
        .background(Theme.bgPrimary)
    }

    // MARK: - Step 1: Welcome (Georgia Bold serif)
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)

            Text("Welcome to MeetWise")
                .font(.heading(28))
                .foregroundStyle(Theme.textHeading)

            Text("AI-powered meeting notes that work in the background.\nNo bots, no recordings visible to participants.")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Step 2: Permissions
    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Permissions")
                .font(.heading(24))
                .foregroundStyle(Theme.textHeading)

            Text("MeetWise needs a couple of permissions to capture meeting audio.")
                .font(.system(size: 14, weight: .light))
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
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Theme.textMuted)
            }

            Button {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
            } label: {
                Text("Open System Settings")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Theme.accentSoft)
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
                .font(.system(size: 14, weight: .light))
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

    // MARK: - Step 4: Profile
    private var profileStep: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("About you")
                .font(.heading(24))
                .foregroundStyle(Theme.textHeading)

            Text("What should we call you?")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 6) {
                Text("Full Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                TextField("e.g. Vishal Adhlakha", text: $fullName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(10)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
                    .shadow(color: Color.black.opacity(0.04), radius: 4, y: 1)
            }
        }
        .padding(.horizontal, 48)
    }

    // MARK: - Step 5: Tips
    private var tipsStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accentGreen)

            Text("You're all set!")
                .font(.heading(28))
                .foregroundStyle(Theme.textHeading)

            Text("Join a meeting and MeetWise will automatically\nstart capturing and transcribing.")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 10) {
                Text("Keyboard Shortcuts")
                    .font(.custom("Georgia", size: 13))
                    .foregroundStyle(Theme.textSecondary)

                shortcutRow(keys: "N", description: "Create quick note")
                shortcutRow(keys: "J", description: "Toggle AI chat sidebar")
                shortcutRow(keys: "K", description: "Search all meetings")
                shortcutRow(keys: "R", description: "Start/stop recording")
            }
            .padding(20)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusMD)
            .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)

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
                    .background(Theme.accentSoft)
                    .cornerRadius(3)
                Text("+")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)
                Text(keys)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Theme.accentSoft)
                    .cornerRadius(3)
            }
            Text(description)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
            Text(text)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Permission Row
    private func permissionRow(icon: String, title: String, description: String, isGranted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isGranted ? Theme.accentGreen : Theme.textSecondary)
                .frame(width: 32, height: 32)
                .background(isGranted ? Theme.tintSage : Theme.bgCard)
                .cornerRadius(Theme.radiusSM)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Text(description)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Theme.accentGreen)
            } else {
                Button("Grant") { action() }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Theme.accent)
                    .cornerRadius(Theme.radiusSM)
                    .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .shadow(color: Color.black.opacity(0.03), radius: 4, y: 1)
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
        // Save profile
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        if let profile = profiles.first {
            profile.fullName = fullName.isEmpty ? "User" : fullName
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
                iconColor: "#2C2C2E",
                category: "builtin"
            )
            recipe.position = index
            modelContext.insert(recipe)
        }
        try? modelContext.save()
    }
}
