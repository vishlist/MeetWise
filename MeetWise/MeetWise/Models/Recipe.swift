import SwiftData
import Foundation

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var name: String
    var prompt: String
    var iconColor: String
    var category: String
    var isBuiltIn: Bool = true
    var position: Int = 0

    init(name: String, prompt: String, iconColor: String, category: String) {
        self.id = UUID()
        self.name = name
        self.prompt = prompt
        self.iconColor = iconColor
        self.category = category
    }
}
