import SwiftData
import Foundation

@Model
final class Company {
    @Attribute(.unique) var id: UUID
    var name: String
    var domain: String?
    @Relationship(deleteRule: .nullify, inverse: \Contact.company)
    var contacts: [Contact]?
    var meetingCount: Int = 0

    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}
