import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var sessionManager = MeetingSessionManager()
    @State private var showSearch = false
    @State private var onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var autoRecordCountdown: Int = 0
    @State private var autoRecordTimer: Timer?

    var body: some View {
        @Bindable var state = appState

        Group {
            if onboardingComplete {
                mainAppView
            } else {
                OnboardingView(isComplete: $onboardingComplete)
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $state.showPricing) {
            PricingView()
                .environment(appState)
        }
        // Issue 3: Upgrade prompt alert
        .alert("Upgrade to Pro", isPresented: $state.showUpgradePrompt) {
            Button("Upgrade") {
                appState.showPricing = true
            }
            Button("Later", role: .cancel) { }
        } message: {
            Text(appState.upgradePromptMessage)
        }
        .onAppear {
            setupInitialData()
            appState.initializeServices()
            wireMeetingDetection()
        }
        .onChange(of: onboardingComplete) { _, newValue in
            if newValue {
                setupInitialData()
            }
        }
        .onChange(of: appState.isSearchPresented) { _, newValue in
            showSearch = newValue
        }
        .onChange(of: showSearch) { _, newValue in
            appState.isSearchPresented = newValue
        }
    }

    private var mainAppView: some View {
        ZStack {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView(sessionManager: sessionManager, toggleSidebar: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        columnVisibility = columnVisibility == .all ? .detailOnly : .all
                    }
                })
                    .navigationSplitViewColumnWidth(min: 200, ideal: Theme.sidebarWidth, max: 280)
            } detail: {
                ZStack(alignment: .topTrailing) {
                    detailView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.bgPrimary)

                    if appState.selectedMeeting == nil {
                        quickNoteHeaderButton
                            .padding(.top, 8)
                            .padding(.trailing, 16)
                    }
                }
            }
            .background(Theme.bgPrimary)

            // Meeting detection banner
            if appState.showMeetingDetectionBanner,
               let detected = appState.meetingDetectionService.detectedMeeting {
                VStack {
                    meetingDetectionBanner(
                        platform: detected.platform.rawValue,
                        windowTitle: detected.windowTitle
                    )
                    .padding(.top, 4)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // CMD+K search overlay
            if showSearch {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .onTapGesture { showSearch = false }

                SearchOverlay(isPresented: $showSearch)
                    .padding(.top, 80)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .onKeyPress(keys: [.init("k")], phases: .down) { press in
            if press.modifiers.contains(.command) {
                showSearch.toggle()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.init("j")], phases: .down) { press in
            if press.modifiers.contains(.command) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    appState.showChatSidebar.toggle()
                }
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.init("n")], phases: .down) { press in
            if press.modifiers.contains(.command) {
                let meeting = sessionManager.startQuickNote(modelContext: modelContext)
                appState.selectedMeeting = meeting
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Meeting Detection Banner (improved with platform icon + countdown)
    private func meetingDetectionBanner(platform: String, windowTitle: String) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Platform icon
                Image(systemName: platformIcon(for: platform))
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32, height: 32)
                    .background(Theme.accentSoft)
                    .cornerRadius(Theme.radiusSM)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Meeting detected: \(platform)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(windowTitle)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                // Auto-record countdown (if active)
                if autoRecordCountdown > 0 {
                    HStack(spacing: 6) {
                        Text("Recording in \(autoRecordCountdown)s")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.accentRed)
                        Button {
                            cancelAutoRecord()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.bgCard)
                                .cornerRadius(Theme.radiusPill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.radiusPill)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Button {
                        Task {
                            await sessionManager.startRecording(
                                modelContext: modelContext,
                                title: windowTitle,
                                platform: platform
                            )
                            if let meeting = sessionManager.currentMeeting {
                                appState.selectedMeeting = meeting
                            }
                            withAnimation { appState.showMeetingDetectionBanner = false }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle().fill(Theme.accentRed).frame(width: 6, height: 6)
                            Text("Record this meeting")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Theme.accent)
                        .cornerRadius(Theme.radiusPill)
                    }
                    .buttonStyle(.plain)

                    Button {
                        cancelAutoRecord()
                        withAnimation { appState.showMeetingDetectionBanner = false }
                    } label: {
                        Text("Dismiss")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Theme.textMuted)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        .padding(.horizontal, 20)
    }

    private func platformIcon(for platform: String) -> String {
        switch platform.lowercased() {
        case let p where p.contains("zoom"): return "video.fill"
        case let p where p.contains("meet"): return "video.circle.fill"
        case let p where p.contains("teams"): return "person.3.fill"
        default: return "video.fill"
        }
    }

    private func startAutoRecordCountdown(platform: String, windowTitle: String) {
        autoRecordCountdown = 5
        autoRecordTimer?.invalidate()
        autoRecordTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [self] _ in
            Task { @MainActor in
                if self.autoRecordCountdown > 1 {
                    self.autoRecordCountdown -= 1
                } else {
                    self.autoRecordTimer?.invalidate()
                    self.autoRecordTimer = nil
                    self.autoRecordCountdown = 0
                    // Auto-start recording
                    await self.sessionManager.startRecording(
                        modelContext: self.modelContext,
                        title: windowTitle,
                        platform: platform
                    )
                    if let meeting = self.sessionManager.currentMeeting {
                        self.appState.selectedMeeting = meeting
                    }
                    withAnimation { self.appState.showMeetingDetectionBanner = false }
                }
            }
        }
    }

    private func cancelAutoRecord() {
        autoRecordTimer?.invalidate()
        autoRecordTimer = nil
        autoRecordCountdown = 0
    }

    // MARK: - Quick Note Header Button
    private var quickNoteHeaderButton: some View {
        Button {
            let meeting = sessionManager.startQuickNote(modelContext: modelContext)
            appState.selectedMeeting = meeting
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus").font(.system(size: 12, weight: .medium))
                Text("Quick note").font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusSM)
            .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var detailView: some View {
        if let meeting = appState.selectedMeeting {
            NotepadView(meeting: meeting, sessionManager: sessionManager)
        } else {
            switch appState.selectedNavItem {
            case .home:
                HomeView(sessionManager: sessionManager)
            case .sharedWithMe:
                SharedWithMeView()
            case .chat:
                ChatView()
            case .folder(let id):
                FolderView(folderID: id, sessionManager: sessionManager)
            case .people:
                PeopleView()
            case .companies:
                CompaniesView()
            case .settings:
                SettingsView()
            }
        }
    }

    // MARK: - Setup
    private func setupInitialData() {
        let descriptor = FetchDescriptor<UserProfile>()
        let profiles = (try? modelContext.fetch(descriptor)) ?? []
        if profiles.isEmpty {
            let profile = UserProfile()
            profile.fullName = "Vishal Adhlakha"
            modelContext.insert(profile)
            appState.currentUser = profile
        } else {
            appState.currentUser = profiles.first
        }

        appState.isAuthenticated = true

        // Seed recipes if needed
        RecipeService.seedRecipes(modelContext: modelContext)
    }

    private func wireMeetingDetection() {
        // Wire up meeting detection to auto-create meetings
        appState.meetingDetectionService.onMeetingStarted = { [self] detected in
            appState.detectedMeetingPlatform = detected.platform.rawValue
            appState.detectedMeetingTitle = detected.windowTitle
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                appState.showMeetingDetectionBanner = true
            }

            // Auto-record with 5-second countdown if user preference is on
            if appState.currentUser?.autoRecord == true {
                startAutoRecordCountdown(
                    platform: detected.platform.rawValue,
                    windowTitle: detected.windowTitle
                )
            }
        }

        appState.meetingDetectionService.onMeetingEnded = { [self] in
            cancelAutoRecord()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                appState.showMeetingDetectionBanner = false
            }
            appState.detectedMeetingPlatform = nil
            appState.detectedMeetingTitle = nil
        }
    }
}
