import Foundation
import SwiftData

@MainActor @Observable
final class ChatService {
    var isLoading = false
    var error: String?

    /// Ask a question about a single meeting
    func askAboutMeeting(_ question: String, meeting: Meeting) async -> String {
        let transcript = meeting.transcriptRaw ?? ""
        let userNotes = meeting.userNotes
        let enhanced = meeting.enhancedNotes ?? ""

        let context = """
        Meeting: \(meeting.title)
        Date: \(meeting.formattedDate)
        Duration: \(meeting.formattedDuration)

        User's Notes:
        \(userNotes)

        Enhanced Notes:
        \(enhanced)

        Transcript:
        \(transcript)
        """

        return await callClaude(
            system: """
            You are MeetWise AI, a meeting assistant. Answer questions based on the meeting content provided.
            Be specific and quote relevant parts. If the answer isn't in the content, say so clearly.
            Keep answers concise — use bullet points when listing multiple items.
            """,
            userMessage: "\(question)\n\nMEETING CONTEXT:\n\(context)"
        )
    }

    /// Ask across all meetings
    func askAcrossMeetings(_ question: String, meetings: [Meeting]) async -> String {
        // Build context from recent meetings (limit to avoid token overflow)
        let recentMeetings = Array(meetings.prefix(10))
        let context = recentMeetings.map { meeting in
            """
            ---
            Meeting: \(meeting.title) (\(meeting.formattedDate))
            Notes: \(meeting.enhancedNotes ?? meeting.userNotes)
            Transcript snippet: \(String((meeting.transcriptRaw ?? "").prefix(500)))
            ---
            """
        }.joined(separator: "\n")

        return await callClaude(
            system: """
            You are MeetWise AI. Answer questions based on the user's meeting notes and transcripts.
            When referencing a specific meeting, cite it as [Meeting: "title" | Date].
            Synthesize across meetings when relevant. Be concise with bullet points.
            """,
            userMessage: "\(question)\n\nMEETINGS:\n\(context)"
        )
    }

    /// Execute a recipe prompt
    func executeRecipe(_ recipe: Recipe, meetings: [Meeting]) async -> String {
        let recentMeetings = Array(meetings.prefix(10))
        let context = recentMeetings.map { meeting in
            "[\(meeting.formattedDate)] \(meeting.title): \(meeting.enhancedNotes ?? meeting.userNotes)"
        }.joined(separator: "\n\n")

        return await callClaude(
            system: recipe.prompt,
            userMessage: "Based on these meetings:\n\n\(context)"
        )
    }

    /// Ask about a specific person across meetings
    func askAboutPerson(_ question: String, personName: String, meetings: [Meeting]) async -> String {
        let relevantMeetings = meetings.filter { meeting in
            meeting.participants?.contains(where: { $0.name.localizedCaseInsensitiveContains(personName) }) ?? false ||
            (meeting.transcriptRaw?.localizedCaseInsensitiveContains(personName) ?? false)
        }

        let context = relevantMeetings.prefix(10).map { meeting in
            "[\(meeting.formattedDate)] \(meeting.title): \(meeting.enhancedNotes ?? meeting.userNotes)"
        }.joined(separator: "\n\n")

        return await callClaude(
            system: "You are MeetWise AI. Answer questions about \(personName) based on meeting notes. Cite specific meetings.",
            userMessage: "\(question)\n\nMeetings involving \(personName):\n\(context)"
        )
    }

    // MARK: - Claude API
    private func callClaude(system: String, userMessage: String) async -> String {
        guard !Constants.anthropicAPIKey.isEmpty else {
            return "Anthropic API key not configured. Set it in Settings."
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let url = URL(string: Constants.anthropicURL)!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(Constants.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

            let body: [String: Any] = [
                "model": Constants.anthropicModel,
                "max_tokens": 2048,
                "system": system,
                "messages": [["role": "user", "content": userMessage]]
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)

            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            return response.content.first?.text ?? "No response"
        } catch {
            self.error = error.localizedDescription
            return "Error: \(error.localizedDescription)"
        }
    }
}
