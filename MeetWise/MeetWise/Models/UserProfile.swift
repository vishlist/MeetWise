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
    var supabaseAccessToken: String?

    // Settings stored as individual fields for simplicity
    var autoRecord: Bool = true
    var defaultLanguage: String = "en"
    var darkMode: Bool = true
    var transcriptNotifications: Bool = true
    var aiModelTrainingOptOut: Bool = false
    var headsUpEnabled: Bool = false

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
}
