import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State private var editableName: String = ""
    @State private var editableEmail: String = ""
    @State private var showSignOutAlert = false

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            appState.settingsTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 12))
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: appState.settingsTab == tab ? .medium : .light))
                        }
                        .foregroundStyle(appState.settingsTab == tab ? Color.white : Theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: Theme.radiusSM)
                                .fill(appState.settingsTab == tab ? Theme.accent : .clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 8)

            Divider().background(Theme.divider)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch appState.settingsTab {
                    case .account:
                        accountTab
                    case .preferences:
                        preferencesTab
                    case .shortcuts:
                        shortcutsTab
                    case .about:
                        aboutTab
                    }
                }
                .padding(.horizontal, 48)
                .padding(.top, 32)
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
        .onAppear {
            editableName = appState.currentUser?.fullName ?? ""
            editableEmail = appState.currentUser?.email ?? ""
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                appState.signOut(modelContext: modelContext)
            }
        } message: {
            Text("Are you sure you want to sign out? You will need to complete onboarding again.")
        }
    }

    // MARK: - Account Tab
    private var accountTab: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Avatar + name
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Theme.accentSoft)
                        .frame(width: 72, height: 72)
                    Text(appState.currentUser?.initials ?? "U")
                        .font(.custom("IBMPlexSerif-Bold", size: 24))
                        .foregroundStyle(Theme.accent)
                }

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Full Name")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        TextField("Your name", text: $editableName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(10)
                            .background(Theme.bgCard)
                            .cornerRadius(Theme.radiusSM)
                            .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
                            .onChange(of: editableName) { _, newValue in
                                appState.currentUser?.fullName = newValue
                                try? modelContext.save()
                            }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textSecondary)
                        TextField("your@email.com", text: $editableEmail)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Theme.textPrimary)
                            .padding(10)
                            .background(Theme.bgCard)
                            .cornerRadius(Theme.radiusSM)
                            .shadow(color: Color.black.opacity(0.03), radius: 2, y: 1)
                            .onChange(of: editableEmail) { _, newValue in
                                appState.currentUser?.email = newValue
                                try? modelContext.save()
                            }
                    }
                }
            }

            // Plan card
            settingsSection("Your Plan") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.currentUser?.planDisplayName ?? "Free Plan")
                            .font(.custom("IBMPlexSerif-Bold", size: 16))
                            .foregroundStyle(Theme.textPrimary)
                        Text(planDescription)
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    if !(appState.currentUser?.isPro ?? false) {
                        Button {
                            appState.showPricing = true
                        } label: {
                            Text("Upgrade")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.accent)
                                .cornerRadius(Theme.radiusSM)
                        }
                        .buttonStyle(.plain)
                        .hoverScale(1.05)
                    }
                }
                .padding(16)
            }

            // Issue 3: Usage stats for free plan
            if !(appState.currentUser?.isPro ?? false) {
                settingsSection("Usage This Month") {
                    VStack(spacing: 12) {
                        usageRow(
                            label: "Meetings",
                            used: appState.currentUser?.meetingsThisMonth ?? 0,
                            limit: UserProfile.freeMeetingLimit
                        )
                        Divider().background(Theme.divider)
                        usageRow(
                            label: "AI Enhancements",
                            used: appState.currentUser?.enhancementsThisMonth ?? 0,
                            limit: UserProfile.freeEnhancementLimit
                        )
                        Divider().background(Theme.divider)
                        usageRow(
                            label: "Chat Questions (today)",
                            used: appState.currentUser?.chatQuestionsToday ?? 0,
                            limit: UserProfile.freeChatLimit
                        )
                    }
                    .padding(16)
                }
            }

            // Issue 2: Calendar Connection
            settingsSection("Calendar") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Google Calendar")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(appState.calendarService.hasGoogleCalendar
                                 ? "Connected via macOS Calendar"
                                 : "Add your Google account to macOS to sync your calendar")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        if appState.calendarService.hasGoogleCalendar {
                            PillTag("Connected", icon: "checkmark.circle.fill", color: Theme.accentGreen)
                        }
                    }

                    if !appState.calendarService.hasGoogleCalendar {
                        HStack(spacing: 12) {
                            Button {
                                CalendarService.openInternetAccountsSettings()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 12))
                                    Text("Add Google Account")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundStyle(Color.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Theme.accent)
                                .cornerRadius(Theme.radiusSM)
                            }
                            .buttonStyle(.plain)
                            .hoverScale(1.05)

                            Text("Opens Internet Accounts in System Settings")
                                .font(.system(size: 11, weight: .light))
                                .foregroundStyle(Theme.textMuted)
                        }
                    }

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Calendar Access")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(appState.calendarService.isAuthorized
                                 ? "MeetWise can read your calendar"
                                 : "Grant calendar access to see upcoming meetings")
                                .font(.system(size: 12, weight: .light))
                                .foregroundStyle(Theme.textSecondary)
                        }
                        Spacer()
                        if appState.calendarService.isAuthorized {
                            PillTag("Authorized", icon: "checkmark.circle.fill", color: Theme.accentGreen)
                        } else {
                            Button {
                                Task { await appState.calendarService.requestAccess() }
                            } label: {
                                Text("Grant Access")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Theme.accent)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Theme.accentSoft)
                                    .cornerRadius(Theme.radiusSM)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }

            // Sign Out
            Button {
                showSignOutAlert = true
            } label: {
                Text("Sign Out")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.accentRed)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.accentRed.opacity(0.08))
                    .cornerRadius(Theme.radiusSM)
            }
            .buttonStyle(.plain)
            .hoverScale(1.02)
        }
    }

    private var planDescription: String {
        switch appState.currentUser?.plan ?? "free" {
        case "pro": return "Unlimited meetings, AI-enhanced notes, all recipes"
        case "team": return "Everything in Pro plus collaboration features"
        default: return "5 meetings/month, 3 AI enhancements/month, basic recipes"
        }
    }

    // Issue 3: Usage progress row
    private func usageRow(label: String, used: Int, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(used)/\(limit)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(used >= limit ? Theme.accentRed : Theme.textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Theme.accentSoft)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(used >= limit ? Theme.accentRed : Theme.accent)
                        .frame(width: geo.size.width * CGFloat(min(used, limit)) / CGFloat(limit), height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Preferences Tab
    private var preferencesTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsSection("Recording") {
                VStack(spacing: 0) {
                    settingsToggle("Auto-record meetings", isOn: Binding(
                        get: { appState.currentUser?.autoRecord ?? true },
                        set: { newVal in appState.currentUser?.autoRecord = newVal; try? modelContext.save() }
                    ))
                    Divider().background(Theme.divider)
                    settingsToggle("Transcript notifications", isOn: Binding(
                        get: { appState.currentUser?.transcriptNotifications ?? true },
                        set: { newVal in appState.currentUser?.transcriptNotifications = newVal; try? modelContext.save() }
                    ))
                }
            }

            settingsSection("General") {
                VStack(spacing: 0) {
                    settingsToggle("Start at login", isOn: Binding(
                        get: { appState.currentUser?.startAtLogin ?? false },
                        set: { newVal in appState.currentUser?.startAtLogin = newVal; try? modelContext.save() }
                    ))
                    Divider().background(Theme.divider)
                    settingsPicker("Default Language", selection: Binding(
                        get: { appState.currentUser?.defaultLanguage ?? "en" },
                        set: { newVal in appState.currentUser?.defaultLanguage = newVal; try? modelContext.save() }
                    ), options: [
                        ("en", "English"),
                        ("es", "Spanish"),
                        ("fr", "French"),
                        ("de", "German"),
                        ("ja", "Japanese")
                    ])
                    Divider().background(Theme.divider)
                    settingsPicker("Audio Quality", selection: Binding(
                        get: { appState.currentUser?.audioQuality ?? "standard" },
                        set: { newVal in appState.currentUser?.audioQuality = newVal; try? modelContext.save() }
                    ), options: [
                        ("standard", "Standard"),
                        ("high", "High")
                    ])
                }
            }
        }
    }

    // MARK: - Shortcuts Tab
    private var shortcutsTab: some View {
        VStack(alignment: .leading, spacing: 20) {
            settingsSection("Keyboard Shortcuts") {
                VStack(spacing: 0) {
                    shortcutRow(keys: "N", description: "New quick note")
                    Divider().background(Theme.divider)
                    shortcutRow(keys: "J", description: "Toggle chat sidebar")
                    Divider().background(Theme.divider)
                    shortcutRow(keys: "K", description: "Search")
                    Divider().background(Theme.divider)
                    shortcutRow(keys: "R", description: "Start/stop recording")
                    Divider().background(Theme.divider)
                    HStack {
                        Text("Esc")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Theme.accentSoft)
                            .cornerRadius(4)
                        Spacer()
                        Text("Close overlay")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    // MARK: - About Tab (IBM Plex Serif for app name)
    private var aboutTab: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Logo area
            VStack(spacing: 12) {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accent)

                Text("MeetWise")
                    .font(.custom("IBMPlexSerif-Bold", size: 24))
                    .foregroundStyle(Theme.textHeading)

                Text("Version 1.0.0")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Theme.textSecondary)

                Text("Made by Vishal")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Theme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)

            settingsSection("Links") {
                VStack(spacing: 0) {
                    linkRow(icon: "globe", label: "Website", url: "https://meetwise.app")
                    Divider().background(Theme.divider)
                    linkRow(icon: "bird", label: "Twitter", url: "https://twitter.com/meetwise")
                    Divider().background(Theme.divider)
                    linkRow(icon: "questionmark.circle", label: "Support", url: "https://meetwise.app/support")
                }
            }
        }
    }

    // MARK: - Helpers
    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.custom("IBMPlexSerif-Bold", size: 12))
                .foregroundStyle(Theme.textMuted)
                .textCase(.uppercase)
                .tracking(1)
            VStack(spacing: 0) {
                content()
            }
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusMD)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
    }

    private func settingsToggle(_ label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .tint(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func settingsPicker(_ label: String, selection: Binding<String>, options: [(String, String)]) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(options, id: \.0) { value, display in
                    Text(display).tag(value)
                }
            }
            .pickerStyle(.menu)
            .tint(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func shortcutRow(keys: String, description: String) -> some View {
        HStack {
            HStack(spacing: 4) {
                Text("Cmd")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.accentSoft)
                    .cornerRadius(4)
                Text(keys)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Theme.accentSoft)
                    .cornerRadius(4)
            }
            Spacer()
            Text(description)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func linkRow(icon: String, label: String, url: String) -> some View {
        Button {
            if let linkURL = URL(string: url) {
                NSWorkspace.shared.open(linkURL)
            }
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(width: 20)
                Text(label)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverHighlight()
    }
}
