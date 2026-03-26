import SwiftData
import Foundation

@Model
final class UserProfile {
    var id: UUID
    var fullName: String?
    var email: String?
    var role: String?
    var focusAreas: String?
    var avatarURL: String?
    var googleRefreshToken: String?
    var supabaseUserId: String?
    var supabaseAccessToken: String?

    // Auth
    var passwordHash: Int = 0
    var isEmailVerified: Bool = false

    // Plan
    var plan: String = "free"
    var planExpiresAt: Date?
    var stripeCustomerId: String?

    // Usage tracking (Issue 3: Pro Plan Enforcement)
    var meetingsThisMonth: Int = 0
    var enhancementsThisMonth: Int = 0
    var chatQuestionsToday: Int = 0
    var lastMonthlyResetDate: Date?
    var lastDailyResetDate: Date?

    // Settings stored as individual fields for simplicity
    var autoRecord: Bool = true
    var defaultLanguage: String = "en"
    var darkMode: Bool = true
    var transcriptNotifications: Bool = true
    var aiModelTrainingOptOut: Bool = false
    var headsUpEnabled: Bool = false
    var startAtLogin: Bool = false
    var audioQuality: String = "standard"

    init() {
        self.id = UUID()
    }

    var displayName: String {
        fullName ?? email ?? "User"
    }

    var initials: String {
        guard let name = fullName else { return "U" }
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var isPro: Bool {
        plan == "pro" || plan == "team"
    }

    var isTeam: Bool {
        plan == "team"
    }

    var planDisplayName: String {
        switch plan {
        case "pro": return "Pro"
        case "team": return "Team"
        default: return "Free Plan"
        }
    }

    // MARK: - Plan Limits
    static let freeMeetingLimit = 5
    static let freeEnhancementLimit = 3
    static let freeChatLimit = 2
    static let freeRecipeLimit = 3
}
