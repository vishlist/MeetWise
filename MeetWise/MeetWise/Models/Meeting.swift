import SwiftData
import Foundation

@Model
final class Meeting {
    @Attribute(.unique) var id: UUID
    var title: String
    var platform: String?
    var meetingURL: String?
    var calendarEventID: String?
    var status: String  // "recording", "processing", "completed", "failed"
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int?

    // Content
    var userNotes: String
    var enhancedNotes: String?
    var transcriptRaw: String?
    var transcriptSegmentsData: Data?

    // Summary (stored as JSON)
    var summaryJSON: Data?

    var language: String = "en"
    var templateID: String = "auto"

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \MeetingParticipant.meeting)
    var participants: [MeetingParticipant]?

    var folder: Folder?

    @Relationship(deleteRule: .cascade, inverse: \TranscriptChunk.meeting)
    var transcriptChunks: [TranscriptChunk]?

    var createdAt: Date
    var updatedAt: Date

    // Supabase sync
    var supabaseID: String?
    var isSynced: Bool = false

    init(title: String, startedAt: Date) {
        self.id = UUID()
        self.title = title
        self.userNotes = ""
        self.status = "recording"
        self.startedAt = startedAt
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var meetingStatus: MeetingStatus {
        MeetingStatus(rawValue: status) ?? .recording
    }

    var formattedDuration: String {
        guard let seconds = durationSeconds else { return "" }
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: startedAt)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startedAt)
    }
}

enum MeetingStatus: String, Codable {
    case recording, processing, completed, failed
}
