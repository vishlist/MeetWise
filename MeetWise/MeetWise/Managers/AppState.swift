import SwiftUI
import Foundation

@Observable
final class AppState {
    // Navigation
    var selectedNavItem: NavItem = .home
    var selectedFolder: Folder?
    var selectedMeeting: Meeting?

    // Recording
    var isRecording = false
    var recordingMeeting: Meeting?
    var recordingDuration: TimeInterval = 0
    var audioLevel: Float = 0.0

    // Search
    var isSearchPresented = false
    var searchQuery = ""

    // Chat
    var isChatSidebarOpen = false

    // User
    var currentUser: UserProfile?
    var isAuthenticated = false

    // Menu bar
    var recentMeetingTitle: String?

    // Onboarding
    var onboardingComplete: Bool {
        UserDefaults.standard.bool(forKey: "onboardingComplete")
    }
}

enum NavItem: Hashable {
    case home
    case sharedWithMe
    case chat
    case folder(UUID)
    case people
    case companies
    case settings
}
