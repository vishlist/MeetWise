import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var sessionManager = MeetingSessionManager()
    @State private var showSearch = false

    var body: some View {
        @Bindable var state = appState

        ZStack {
            NavigationSplitView(columnVisibility: .constant(.all)) {
                SidebarView(sessionManager: sessionManager)
                    .navigationSplitViewColumnWidth(min: 200, ideal: Theme.sidebarWidth, max: 280)
            } detail: {
                ZStack(alignment: .topTrailing) {
                    detailView
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Theme.bgPrimary)

                    // "+ Quick note" and "Invite" buttons (always visible on non-note views)
                    if appState.selectedMeeting == nil {
                        quickNoteHeaderButton
                            .padding(.top, 8)
                            .padding(.trailing, 16)
                    }
                }
            }
            .background(Theme.bgPrimary)

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
        .preferredColorScheme(.dark)
        .onAppear {
            setupInitialData()
        }
        // CMD+K for search
        .keyboardShortcut("k", modifiers: .command)
        .onKeyPress(keys: [.init("k")], phases: .down) { press in
            if press.modifiers.contains(.command) {
                showSearch.toggle()
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Quick Note Header Button
    private var quickNoteHeaderButton: some View {
        HStack(spacing: 12) {
            Button { } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 12))
                    Text("Invite")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusSM)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                Task {
                    await sessionManager.startRecording(modelContext: modelContext)
                    if let meeting = sessionManager.currentMeeting {
                        appState.selectedMeeting = meeting
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                    Text("Quick note")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusSM)
                        .stroke(Theme.border, lineWidth: 1)
                )
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
    }
}
