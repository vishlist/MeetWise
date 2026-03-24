import Foundation

final class EnhancementService {

    struct EnhancedNote {
        let content: String            // markdown with [USER]/[AI] markers
        let summary: MeetingSummary
    }

    struct MeetingSummary: Codable {
        let title: String
        let overview: String
        let keyPoints: [String]
        let actionItems: [ActionItem]
        let decisions: [String]
        let questionsRaised: [String]
        let sentiment: String
        let topics: [String]

        struct ActionItem: Codable {
            let task: String
            let assignee: String?
            let deadline: String?
        }

        enum CodingKeys: String, CodingKey {
            case title, overview, decisions, sentiment, topics
            case keyPoints = "key_points"
            case actionItems = "action_items"
            case questionsRaised = "questions_raised"
        }
    }

    /// Enhance user notes with meeting transcript context
    func enhanceNotes(
        userNotes: String,
        transcript: String,
        attendees: [String],
        meetingTitle: String
    ) async throws -> EnhancedNote {

        let systemPrompt = """
        You are MeetWise, an AI meeting notes enhancer. You take a user's rough notes and a meeting transcript, and produce polished, structured meeting notes.

        CRITICAL RULES:
        1. The user's original notes are SACRED. Keep them intact but clean up typos and expand abbreviations.
        2. Mark user-written content with [USER] tags and AI-added content with [AI] tags.
        3. Organize by topic, not chronologically.
        4. Extract action items, decisions, and key points.
        5. Be concise — bullet points, not paragraphs.

        MEETING CONTEXT:
        - Title: \(meetingTitle)
        - Attendees: \(attendees.joined(separator: ", "))
        """

        let userMessage = """
        USER'S NOTES:
        \(userNotes.isEmpty ? "(No notes taken)" : userNotes)

        MEETING TRANSCRIPT:
        \(transcript)

        Enhance these notes. Return the enhanced notes with [USER]/[AI] markers. Then on a new line after "---SUMMARY---", return a JSON summary object with keys: title, overview, key_points, action_items, decisions, questions_raised, sentiment, topics.
        """

        let response = try await callClaudeAPI(system: systemPrompt, message: userMessage, maxTokens: 4096)

        // Parse response: split enhanced notes from summary JSON
        let parts = response.components(separatedBy: "---SUMMARY---")
        let enhancedContent = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)

        var summary: MeetingSummary
        if parts.count > 1 {
            let jsonStr = parts[1]
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if let jsonData = jsonStr.data(using: .utf8) {
                summary = try JSONDecoder().decode(MeetingSummary.self, from: jsonData)
            } else {
                summary = defaultSummary(title: meetingTitle)
            }
        } else {
            summary = defaultSummary(title: meetingTitle)
        }

        return EnhancedNote(content: enhancedContent, summary: summary)
    }

    /// Generate just a summary from transcript (no user notes needed)
    func generateSummary(transcript: String, meetingTitle: String) async throws -> MeetingSummary {
        let systemPrompt = "You are a meeting summarization AI. Given a meeting transcript, produce a structured JSON summary. Return ONLY valid JSON with no other text."

        let userMessage = """
        Summarize this meeting transcript into structured JSON:

        \(transcript)

        Return this exact JSON structure:
        {
            "title": "Short descriptive title (max 60 chars)",
            "overview": "2-3 sentence summary",
            "key_points": ["Array of main discussion points"],
            "action_items": [{"task": "description", "assignee": "person or null", "deadline": "deadline or null"}],
            "decisions": ["Array of decisions made"],
            "questions_raised": ["Array of unresolved questions"],
            "sentiment": "positive | neutral | negative | mixed",
            "topics": ["Array of topic tags"]
        }
        """

        let response = try await callClaudeAPI(system: systemPrompt, message: userMessage, maxTokens: 2048)

        let cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            return defaultSummary(title: meetingTitle)
        }

        return try JSONDecoder().decode(MeetingSummary.self, from: data)
    }

    // MARK: - Claude API
    private func callClaudeAPI(system: String, message: String, maxTokens: Int = 2048) async throws -> String {
        guard !Constants.anthropicAPIKey.isEmpty else {
            throw EnhancementError.missingAPIKey
        }

        let url = URL(string: Constants.anthropicURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(Constants.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": Constants.anthropicModel,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [
                ["role": "user", "content": message]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        // Check for HTTP errors
        if let http = httpResponse as? HTTPURLResponse, http.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[Claude API] HTTP \(http.statusCode): \(errorBody)")
            throw EnhancementError.apiError("HTTP \(http.statusCode): \(String(errorBody.prefix(200)))")
        }

        do {
            let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
            return response.content.first?.text ?? ""
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "nil"
            print("[Claude API] Decode error: \(error). Raw: \(String(raw.prefix(500)))")
            throw EnhancementError.apiError("Response parse failed: \(error.localizedDescription)")
        }
    }

    private func defaultSummary(title: String) -> MeetingSummary {
        MeetingSummary(
            title: title,
            overview: "Meeting summary not available.",
            keyPoints: [],
            actionItems: [],
            decisions: [],
            questionsRaised: [],
            sentiment: "neutral",
            topics: []
        )
    }
}

struct ClaudeResponse: Codable {
    let content: [ClaudeContent]

    struct ClaudeContent: Codable {
        let type: String
        let text: String?
    }
}

enum EnhancementError: Error, LocalizedError {
    case missingAPIKey
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Anthropic API key not configured"
        case .apiError(let msg): return "Claude API error: \(msg)"
        }
    }
}
