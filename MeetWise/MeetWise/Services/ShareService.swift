import AppKit
import Foundation

final class ShareService {
    /// Copy formatted meeting notes to clipboard
    static func copyNotesToClipboard(meeting: Meeting) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let content = meeting.enhancedNotes ?? meeting.userNotes
        let title = meeting.title
        let date = meeting.formattedDate

        let formatted = """
        \(title)
        \(date)
        \(String(repeating: "─", count: 40))

        \(content)
        """

        pasteboard.setString(formatted, forType: .string)
    }

    /// Copy as markdown
    static func copyAsMarkdown(meeting: Meeting) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let content = meeting.enhancedNotes ?? meeting.userNotes
        let markdown = """
        # \(meeting.title)

        **Date:** \(meeting.formattedDate)
        **Duration:** \(meeting.formattedDuration)

        ---

        \(content)
        """

        pasteboard.setString(markdown, forType: .string)
    }

    /// Copy transcript to clipboard
    static func copyTranscript(meeting: Meeting) {
        guard let transcript = meeting.transcriptRaw else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(transcript, forType: .string)
    }

    /// Export as plain text file
    static func exportAsText(meeting: Meeting) -> String {
        let content = meeting.enhancedNotes ?? meeting.userNotes
        return """
        \(meeting.title)
        \(meeting.formattedDate)
        Duration: \(meeting.formattedDuration)

        \(content)

        ---
        Transcript:
        \(meeting.transcriptRaw ?? "No transcript available")
        """
    }
}
