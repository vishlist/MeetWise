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

    // Upgrade prompt
    var showUpgradePrompt = false
    var upgradePromptMessage = ""

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

        // Reset usage counters if needed
        resetCountsIfNeeded()
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

    // MARK: - Pro Plan Enforcement (Issue 3)

    func resetCountsIfNeeded() {
        guard let user = currentUser else { return }
        let calendar = Calendar.current
        let now = Date()

        // Monthly reset
        if let lastReset = user.lastMonthlyResetDate {
            if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
                user.meetingsThisMonth = 0
                user.enhancementsThisMonth = 0
                user.lastMonthlyResetDate = now
            }
        } else {
            user.lastMonthlyResetDate = now
        }

        // Daily reset
        if let lastDaily = user.lastDailyResetDate {
            if !calendar.isDateInToday(lastDaily) {
                user.chatQuestionsToday = 0
                user.lastDailyResetDate = now
            }
        } else {
            user.lastDailyResetDate = now
        }
    }

    func checkMeetingLimit() -> Bool {
        guard let user = currentUser, !user.isPro else { return true }
        resetCountsIfNeeded()
        return user.meetingsThisMonth < UserProfile.freeMeetingLimit
    }

    func checkEnhancementLimit() -> Bool {
        guard let user = currentUser, !user.isPro else { return true }
        resetCountsIfNeeded()
        return user.enhancementsThisMonth < UserProfile.freeEnhancementLimit
    }

    func checkChatLimit() -> Bool {
        guard let user = currentUser, !user.isPro else { return true }
        resetCountsIfNeeded()
        return user.chatQuestionsToday < UserProfile.freeChatLimit
    }

    func incrementMeetingCount() {
        guard let user = currentUser else { return }
        resetCountsIfNeeded()
        user.meetingsThisMonth += 1
    }

    func incrementEnhancementCount() {
        guard let user = currentUser else { return }
        resetCountsIfNeeded()
        user.enhancementsThisMonth += 1
    }

    func incrementChatCount() {
        guard let user = currentUser else { return }
        resetCountsIfNeeded()
        user.chatQuestionsToday += 1
    }

    func showUpgrade(_ message: String) {
        upgradePromptMessage = message
        showUpgradePrompt = true
    }

    /// Check if a recipe is available on the free plan (first 3 only)
    func isRecipeAvailable(index: Int) -> Bool {
        guard let user = currentUser, !user.isPro else { return true }
        return index < UserProfile.freeRecipeLimit
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
