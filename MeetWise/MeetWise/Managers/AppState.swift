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
    var didSignOut = false

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

    /// Sign out: clear session state only — user data (profile, meetings, folders) persists
    func signOut(modelContext: ModelContext) {
        // Sign out from Supabase (fire-and-forget)
        Task { await SupabaseAuth.shared.signOut() }

        // Clear session flags only
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
        UserDefaults.standard.set(false, forKey: "onboardingComplete")

        // DO NOT delete UserProfile, Meeting, Folder, or any SwiftData records.
        // The user's data persists so they can sign back in and see everything.

        // Reset in-memory navigation state
        currentUser = nil
        isAuthenticated = false
        selectedNavItem = .home
        selectedMeeting = nil
        selectedFolder = nil
        showChatSidebar = false
        showPricing = false
        showProfileMenu = false
        isRecording = false
        didSignOut = true
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

// MARK: - Supabase Authentication Service

final class SupabaseAuth: @unchecked Sendable {
    static let shared = SupabaseAuth()

    private let baseURL = Constants.supabaseURL
    private let apiKey = Constants.supabaseAnonKey

    // MARK: - Token Storage (UserDefaults)

    var accessToken: String? {
        get { UserDefaults.standard.string(forKey: "supabase_access_token") }
        set { UserDefaults.standard.set(newValue, forKey: "supabase_access_token") }
    }

    var refreshToken: String? {
        get { UserDefaults.standard.string(forKey: "supabase_refresh_token") }
        set { UserDefaults.standard.set(newValue, forKey: "supabase_refresh_token") }
    }

    // MARK: - Response Types

    struct SignUpResponse: Decodable {
        let id: String?
        let email: String?
        let confirmation_sent_at: String?
    }

    struct SignInResponse: Decodable {
        let access_token: String
        let refresh_token: String
        let expires_in: Int?
        let token_type: String?
        let user: SupabaseUser?
    }

    struct SupabaseUser: Decodable {
        let id: String
        let email: String?
        let email_confirmed_at: String?
        let created_at: String?

        var isEmailVerified: Bool {
            email_confirmed_at != nil && !(email_confirmed_at?.isEmpty ?? true)
        }
    }

    struct VerifyResponse: Decodable {
        let access_token: String?
        let refresh_token: String?
        let user: SupabaseUser?
    }

    struct AuthErrorResponse: Decodable {
        let error: String?
        let error_description: String?
        let msg: String?
        let message: String?

        var displayMessage: String {
            error_description ?? msg ?? message ?? error ?? "An unknown error occurred"
        }
    }

    struct AuthError: Error, LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String) async throws -> SignUpResponse {
        let url = URL(string: "\(baseURL)/auth/v1/signup")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])

        let (data, response) = try await performRequest(request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode >= 400 {
            let errorMsg = parseError(data: data, statusCode: statusCode)
            throw AuthError(message: errorMsg)
        }

        return try JSONDecoder().decode(SignUpResponse.self, from: data)
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> SignInResponse {
        let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=password")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email,
            "password": password
        ])

        let (data, response) = try await performRequest(request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode >= 400 {
            let errorMsg = parseError(data: data, statusCode: statusCode)
            throw AuthError(message: errorMsg)
        }

        let signInResponse = try JSONDecoder().decode(SignInResponse.self, from: data)
        accessToken = signInResponse.access_token
        refreshToken = signInResponse.refresh_token
        return signInResponse
    }

    // MARK: - Verify OTP (email verification)

    func verifyOTP(email: String, token: String, type: String = "signup") async throws -> VerifyResponse {
        let url = URL(string: "\(baseURL)/auth/v1/verify")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "type": type,
            "token": token,
            "email": email
        ])

        let (data, response) = try await performRequest(request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode >= 400 {
            let errorMsg = parseError(data: data, statusCode: statusCode)
            throw AuthError(message: errorMsg)
        }

        let verifyResponse = try JSONDecoder().decode(VerifyResponse.self, from: data)
        // Save tokens if returned (verification returns tokens on success)
        if let at = verifyResponse.access_token {
            accessToken = at
        }
        if let rt = verifyResponse.refresh_token {
            refreshToken = rt
        }
        return verifyResponse
    }

    // MARK: - Send Password Reset Email

    func sendPasswordReset(email: String) async throws {
        let url = URL(string: "\(baseURL)/auth/v1/recover")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "email": email
        ])

        let (data, response) = try await performRequest(request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode >= 400 {
            let errorMsg = parseError(data: data, statusCode: statusCode)
            throw AuthError(message: errorMsg)
        }
    }

    // MARK: - Reset Password (requires active access_token)

    func resetPassword(newPassword: String) async throws {
        guard let token = accessToken else {
            throw AuthError(message: "Not authenticated. Please sign in first.")
        }

        let url = URL(string: "\(baseURL)/auth/v1/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "password": newPassword
        ])

        let (data, response) = try await performRequest(request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode >= 400 {
            let errorMsg = parseError(data: data, statusCode: statusCode)
            throw AuthError(message: errorMsg)
        }
    }

    // MARK: - Get Current User

    func getUser() async throws -> SupabaseUser {
        guard let token = accessToken else {
            throw AuthError(message: "Not authenticated")
        }

        let url = URL(string: "\(baseURL)/auth/v1/user")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await performRequest(request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode >= 400 {
            // If 401, try refresh
            if statusCode == 401 {
                try await refreshSession()
                return try await getUser()
            }
            let errorMsg = parseError(data: data, statusCode: statusCode)
            throw AuthError(message: errorMsg)
        }

        return try JSONDecoder().decode(SupabaseUser.self, from: data)
    }

    // MARK: - Sign Out

    func signOut() async {
        if let token = accessToken {
            let url = URL(string: "\(baseURL)/auth/v1/logout")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(apiKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await performRequest(request)
        }

        accessToken = nil
        refreshToken = nil
    }

    // MARK: - Refresh Session

    func refreshSession() async throws {
        guard let rt = refreshToken else {
            throw AuthError(message: "No refresh token available. Please sign in again.")
        }

        let url = URL(string: "\(baseURL)/auth/v1/token?grant_type=refresh_token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "refresh_token": rt
        ])

        let (data, response) = try await performRequest(request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        if statusCode >= 400 {
            // Refresh failed — clear tokens
            accessToken = nil
            refreshToken = nil
            let errorMsg = parseError(data: data, statusCode: statusCode)
            throw AuthError(message: errorMsg)
        }

        let refreshResponse = try JSONDecoder().decode(SignInResponse.self, from: data)
        accessToken = refreshResponse.access_token
        refreshToken = refreshResponse.refresh_token
    }

    // MARK: - Validate Session (returns true if user is authenticated)

    func validateSession() async -> Bool {
        guard accessToken != nil else { return false }
        do {
            _ = try await getUser()
            return true
        } catch {
            // Try refresh
            do {
                try await refreshSession()
                _ = try await getUser()
                return true
            } catch {
                return false
            }
        }
    }

    // MARK: - Helpers

    private func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                throw AuthError(message: "Unable to connect. Check your internet connection.")
            default:
                throw AuthError(message: "Network error. Please try again.")
            }
        }
    }

    private func parseError(data: Data, statusCode: Int) -> String {
        if statusCode == 429 {
            return "Too many attempts. Please try again later."
        }

        if let errorResponse = try? JSONDecoder().decode(AuthErrorResponse.self, from: data) {
            let msg = errorResponse.displayMessage.lowercased()
            if msg.contains("already registered") || msg.contains("already been registered") || msg.contains("user already registered") {
                return "An account with this email already exists. Try signing in."
            }
            if msg.contains("invalid login") || msg.contains("invalid email or password") || msg.contains("invalid credentials") {
                return "Invalid email or password"
            }
            if msg.contains("email not confirmed") || msg.contains("not confirmed") {
                return "Please verify your email first. Check your inbox."
            }
            if msg.contains("rate limit") || msg.contains("too many") {
                return "Too many attempts. Please try again later."
            }
            return errorResponse.displayMessage
        }

        return "Something went wrong (error \(statusCode)). Please try again."
    }
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
