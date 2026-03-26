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

    // Issue 9: Draft flag — empty quick notes are drafts until content is added
    var isDraft: Bool = false

    // Issue 4: Speaker name mapping (stored as JSON: {"Speaker 0": "Alice", "Speaker 1": "Bob"})
    var speakerNameMapData: Data?

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

    /// Check if this meeting has any real content
    var hasContent: Bool {
        !userNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !(transcriptRaw ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        enhancedNotes != nil
    }

    // MARK: - Speaker Name Mapping (Issue 4)

    var speakerNameMap: [String: String] {
        get {
            guard let data = speakerNameMapData else { return [:] }
            return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
        }
        set {
            speakerNameMapData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Returns the display name for a speaker label, falling back to "Speaker A", "Speaker B" etc.
    func displayName(for speakerLabel: String) -> String {
        if let mapped = speakerNameMap[speakerLabel], !mapped.isEmpty {
            return mapped
        }
        // Convert "Speaker 0" -> "Speaker A", "Speaker 1" -> "Speaker B", etc.
        if speakerLabel.hasPrefix("Speaker "), let numStr = speakerLabel.split(separator: " ").last, let num = Int(numStr) {
            let letter = String(UnicodeScalar(65 + (num % 26))!) // A, B, C...
            return "Speaker \(letter)"
        }
        return speakerLabel
    }
}

enum MeetingStatus: String, Codable {
    case recording, processing, completed, failed
}
