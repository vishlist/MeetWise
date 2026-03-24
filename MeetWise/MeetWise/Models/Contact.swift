import SwiftData
import Foundation

@Model
final class Contact {
    @Attribute(.unique) var id: UUID
    var name: String
    var email: String?
    var company: Company?
    var avatarURL: String?
    var meetingCount: Int = 0
    var lastMetAt: Date?
    var notes: String?

    init(name: String, email: String? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
    }

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
}
