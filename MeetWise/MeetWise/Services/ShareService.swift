import AppKit
import Foundation

/// Sharing and export utilities
struct ShareService {

    /// Copy enhanced notes as formatted markdown
    static func copyAsMarkdown(meeting: Meeting) {
        let content = buildMarkdown(meeting: meeting)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }

    /// Copy notes to clipboard (best available format)
    static func copyNotesToClipboard(meeting: Meeting) {
        if meeting.enhancedNotes != nil {
            copyAsMarkdown(meeting: meeting)
        } else {
            copyAsPlainText(meeting: meeting)
        }
    }

    /// Copy as plain text
    static func copyAsPlainText(meeting: Meeting) {
        let content = buildPlainText(meeting: meeting)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
    }

    /// Export transcript as .txt file
    static func exportTranscript(meeting: Meeting) -> URL? {
        let text = meeting.transcriptRaw ?? ""
        guard !text.isEmpty else { return nil }

        let fileName = "\(meeting.title.replacingOccurrences(of: " ", with: "_"))_transcript.txt"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try text.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            return nil
        }
    }

    // MARK: - Private

    private static func buildMarkdown(meeting: Meeting) -> String {
        var md = "# \(meeting.title)\n\n"
        md += "📅 \(meeting.formattedDate) | ⏱ \(meeting.formattedDuration)\n\n"

        if let participants = meeting.participants, !participants.isEmpty {
            md += "👥 \(participants.map(\.name).joined(separator: ", "))\n\n"
        }

        if let enhanced = meeting.enhancedNotes, !enhanced.isEmpty {
            md += enhanced + "\n\n"
        } else if !meeting.userNotes.isEmpty {
            md += meeting.userNotes + "\n\n"
        }

        if let summaryData = meeting.summaryJSON,
           let summary = try? JSONDecoder().decode(EnhancementService.MeetingSummary.self, from: summaryData) {
            md += "---\n\n"
            md += "## Summary\n\(summary.overview)\n\n"
            if !summary.keyPoints.isEmpty {
                md += "## Key Points\n"
                summary.keyPoints.forEach { md += "- \($0)\n" }
                md += "\n"
            }
            if !summary.actionItems.isEmpty {
                md += "## Action Items\n"
                summary.actionItems.forEach { item in
                    md += "- [ ] \(item.task)"
                    if let assignee = item.assignee { md += " (@\(assignee))" }
                    md += "\n"
                }
            }
        }

        return md
    }

    private static func buildPlainText(meeting: Meeting) -> String {
        var text = "\(meeting.title)\n"
        text += "\(meeting.formattedDate) | \(meeting.formattedDuration)\n\n"

        if let enhanced = meeting.enhancedNotes, !enhanced.isEmpty {
            let cleaned = enhanced
                .replacingOccurrences(of: "# ", with: "")
                .replacingOccurrences(of: "## ", with: "")
                .replacingOccurrences(of: "### ", with: "")
                .replacingOccurrences(of: "**", with: "")
            text += cleaned
        } else {
            text += meeting.userNotes
        }

        return text
    }
}
