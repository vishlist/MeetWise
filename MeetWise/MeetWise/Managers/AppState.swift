import SwiftUI
import SwiftData
import Foundation

@MainActor @Observable
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
    var showChatSidebar = false

    // User
    var currentUser: UserProfile?
    var isAuthenticated = false

    // Pricing
    var showPricing = false

    // Profile menu
    var showProfileMenu = false

    // Settings tab
    var settingsTab: SettingsTab = .account

    // Menu bar
    var recentMeetingTitle: String?

    // Services
    var meetingDetectionService = MeetingDetectionService()
    var calendarService = CalendarService()
    var chatService = ChatService()

    // Meeting detection
    var detectedMeetingPlatform: String?
    var detectedMeetingTitle: String?
    var showMeetingDetectionBanner = false

    // Onboarding
    var onboardingComplete: Bool {
        UserDefaults.standard.bool(forKey: "onboardingComplete")
    }

    var showOnboarding: Bool {
        !onboardingComplete
    }

    /// The currently detected meeting (convenience accessor)
    var detectedMeetingBanner: MeetingDetectionService.DetectedMeeting? {
        meetingDetectionService.detectedMeeting
    }

    /// Initialize meeting detection and calendar on app launch
    func initializeServices() {
        meetingDetectionService.onMeetingStarted = { [weak self] detected in
            guard let self else { return }
            self.detectedMeetingPlatform = detected.platform.rawValue
            self.detectedMeetingTitle = detected.windowTitle
            self.showMeetingDetectionBanner = true
        }

        meetingDetectionService.onMeetingEnded = { [weak self] in
            guard let self else { return }
            self.detectedMeetingPlatform = nil
            self.detectedMeetingTitle = nil
            self.showMeetingDetectionBanner = false
        }

        meetingDetectionService.startMonitoring()

        Task {
            await calendarService.requestAccess()
        }
    }

    /// Sign out: clear all user state
    func signOut(modelContext: ModelContext) {
        // Clear onboarding
        UserDefaults.standard.set(false, forKey: "onboardingComplete")
        UserDefaults.standard.removeObject(forKey: "userPlan")

        // Delete user profiles from SwiftData
        let descriptor = FetchDescriptor<UserProfile>()
        if let profiles = try? modelContext.fetch(descriptor) {
            for profile in profiles {
                modelContext.delete(profile)
            }
            try? modelContext.save()
        }

        // Reset state
        currentUser = nil
        isAuthenticated = false
        selectedNavItem = .home
        selectedMeeting = nil
        selectedFolder = nil
        showChatSidebar = false
        showPricing = false
        showProfileMenu = false
        isRecording = false
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

enum SettingsTab: String, CaseIterable {
    case account = "Account"
    case preferences = "Preferences"
    case shortcuts = "Shortcuts"
    case about = "About"

    var icon: String {
        switch self {
        case .account: return "person.circle"
        case .preferences: return "gearshape"
        case .shortcuts: return "keyboard"
        case .about: return "info.circle"
        }
    }
}
