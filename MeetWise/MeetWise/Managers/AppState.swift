import SwiftUI
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
