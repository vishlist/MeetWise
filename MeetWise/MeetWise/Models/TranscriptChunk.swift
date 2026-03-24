import SwiftData
import Foundation

@Model
final class TranscriptChunk {
    var id: UUID
    var meeting: Meeting?
    var chunkIndex: Int
    var content: String
    var speaker: String?
    var startTimeSeconds: Double
    var endTimeSeconds: Double
    var wordCount: Int
    var supabaseID: String?

    init(content: String, chunkIndex: Int, startTime: Double, endTime: Double) {
        self.id = UUID()
        self.content = content
        self.chunkIndex = chunkIndex
        self.startTimeSeconds = startTime
        self.endTimeSeconds = endTime
        self.wordCount = content.split(separator: " ").count
    }
}
