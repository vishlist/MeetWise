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

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { step in
                    Circle()
                        .fill(step <= currentStep ? Theme.accentGreen : Theme.bgCard)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 40)

            Spacer()

            switch currentStep {
            case 0: welcomeStep
            case 1: permissionsStep
            case 2: profileStep
            case 3: readyStep
            default: readyStep
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

                Button {
                    if currentStep < 3 {
                        withAnimation { currentStep += 1 }
                    } else {
                        completeOnboarding()
                    }
                } label: {
                    Text(currentStep == 3 ? "Get Started" : "Continue")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Theme.accentGreen)
                        .cornerRadius(Theme.radiusPill)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 48)
            .padding(.bottom, 40)
        }
        .frame(width: 550, height: 500)
        .background(Theme.bgPrimary)
    }

    // MARK: - Step 1: Welcome
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accentGreen)

            Text("Welcome to MeetWise")
                .font(.heading(28))
                .foregroundStyle(Theme.textHeading)

            Text("AI-powered meeting notes that work in the background.\nNo bots, no recordings — just smart notes.")
                .font(.system(size: 15))
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

            Text("MeetWise needs a few permissions to capture meeting audio and integrate with your calendar.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)

            VStack(spacing: 12) {
                permissionRow(
                    icon: "rectangle.inset.filled.and.person.filled",
                    title: "Screen Recording",
                    description: "Captures system audio from meeting apps",
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

    private func permissionRow(icon: String, title: String, description: String, isGranted: Bool, action: @escaping () -> Void) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(isGranted ? Theme.accentGreen : Theme.textSecondary)
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
                    .foregroundStyle(Theme.accentGreen)
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

    // MARK: - Step 3: Profile
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

    // MARK: - Step 4: Ready
    private var readyStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accentGreen)

            Text("You're all set!")
                .font(.heading(28))
                .foregroundStyle(Theme.textHeading)

            Text("Join a meeting and MeetWise will automatically\nstart capturing and transcribing.")
                .font(.system(size: 15))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            VStack(alignment: .leading, spacing: 8) {
                tipRow(icon: "keyboard", text: "CMD+K to search all meetings")
                tipRow(icon: "keyboard", text: "CMD+J to ask AI about a meeting")
                tipRow(icon: "sparkles", text: "Click \"Enhance Notes\" after meetings")
            }
            .padding(20)
            .background(Theme.bgCard.opacity(0.5))
            .cornerRadius(Theme.radiusMD)
        }
        .padding(.horizontal, 48)
    }

    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Theme.accentGreen)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Permission Requests
    private func requestScreenRecording() {
        Task {
            do {
                _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
                screenRecordingGranted = true
            } catch {
                // Will show system dialog
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

    private func completeOnboarding() {
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
        RecipeService.seedRecipes(modelContext: modelContext)

        UserDefaults.standard.set(true, forKey: "onboardingComplete")
        isComplete = true
    }
}
