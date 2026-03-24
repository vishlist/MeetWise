import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var sessionManager = MeetingSessionManager()

    var body: some View {
        @Bindable var state = appState

        NavigationSplitView(columnVisibility: .constant(.all)) {
            SidebarView(sessionManager: sessionManager)
                .navigationSplitViewColumnWidth(min: 200, ideal: Theme.sidebarWidth, max: 280)
        } detail: {
            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.bgPrimary)
        }
        .background(Theme.bgPrimary)
        .preferredColorScheme(.dark)
        .onAppear {
            setupInitialData()
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
