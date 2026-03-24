import SwiftData
import Foundation

@Model
final class ChatConversation {
    @Attribute(.unique) var id: UUID
    var title: String = "New Chat"
    var scopeType: String  // "singleMeeting", "folder", "allMeetings", "person", "company"
    var scopeID: UUID?

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.conversation)
    var messages: [ChatMessage]?

    var createdAt: Date
    var updatedAt: Date

    init(scopeType: String, scopeID: UUID? = nil) {
        self.id = UUID()
        self.scopeType = scopeType
        self.scopeID = scopeID
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
