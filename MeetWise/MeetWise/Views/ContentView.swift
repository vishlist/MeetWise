import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var sessionManager = MeetingSessionManager()
    @State private var showSearch = false
    @State private var onboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")

    var body: some View {
        @Bindable var state = appState

        Group {
            if onboardingComplete {
                mainAppView
            } else {
                OnboardingView(isComplete: $onboardingComplete)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $state.showPricing) {
            PricingView()
                .environment(appState)
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
    }

    private var mainAppView: some View {
        ZStack {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                SidebarView(sessionManager: sessionManager)
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
                Color.black.opacity(0.4)
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

    // MARK: - Meeting Detection Banner
    private func meetingDetectionBanner(platform: String, windowTitle: String) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Theme.accent)
                .frame(width: 8, height: 8)

            Image(systemName: "video.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)

            Text("\(platform) detected")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Theme.textPrimary)

            Text(windowTitle)
                .font(.system(size: 12))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(1)

            Spacer()

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
                    Image(systemName: "record.circle")
                        .font(.system(size: 11))
                    Text("Record")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Color.white)
                .cornerRadius(Theme.radiusPill)
            }
            .buttonStyle(.plain)

            Button {
                withAnimation { appState.showMeetingDetectionBanner = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusMD).stroke(Theme.border, lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .padding(.horizontal, 20)
    }

    // MARK: - Quick Note Header Button
    private var quickNoteHeaderButton: some View {
        HStack(spacing: 12) {
            Button { } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus").font(.system(size: 12))
                    Text("Invite").font(.system(size: 13))
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

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
                FolderView(folderID: id)
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
            withAnimation { appState.showMeetingDetectionBanner = true }

            // Auto-record if user preference is on
            if appState.currentUser?.autoRecord == true {
                Task {
                    await sessionManager.handleMeetingDetected(
                        detected,
                        autoRecord: true,
                        modelContext: modelContext
                    )
                    if let meeting = sessionManager.currentMeeting {
                        appState.selectedMeeting = meeting
                    }
                }
            }
        }

        appState.meetingDetectionService.onMeetingEnded = { [self] in
            withAnimation { appState.showMeetingDetectionBanner = false }
            appState.detectedMeetingPlatform = nil
            appState.detectedMeetingTitle = nil
        }
    }
}
