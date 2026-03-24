import SwiftData
import Foundation

@Model
final class Folder {
    @Attribute(.unique) var id: UUID
    var name: String
    var spaceType: String  // "personal", "team"
    var icon: String = "folder"
    var color: String = "#6366f1"
    var position: Int = 0

    @Relationship(deleteRule: .nullify, inverse: \Meeting.folder)
    var meetings: [Meeting]?

    var createdAt: Date

    init(name: String, spaceType: String) {
        self.id = UUID()
        self.name = name
        self.spaceType = spaceType
        self.createdAt = Date()
    }
}
