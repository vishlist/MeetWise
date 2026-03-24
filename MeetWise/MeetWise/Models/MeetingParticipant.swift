import SwiftData
import Foundation

@Model
final class MeetingParticipant {
    var id: UUID
    var name: String
    var email: String?
    var speakerLabel: String?
    var contact: Contact?
    var meeting: Meeting?

    init(name: String, email: String? = nil) {
        self.id = UUID()
        self.name = name
        self.email = email
    }
}
