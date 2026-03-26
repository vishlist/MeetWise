import Foundation

final class EnhancementService {

    struct EnhancedNote {
        let content: String
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

        // If both notes and transcript are empty, return a helpful default
        if userNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return EnhancedNote(
                content: "# \(meetingTitle)\n\n*No notes or transcript available. Start recording a meeting or type notes to enhance.*",
                summary: defaultSummary(title: meetingTitle)
            )
        }

        let systemPrompt = """
        You are MeetWise, an AI meeting notes enhancer. You take a user's rough notes and a meeting transcript, and produce polished, structured meeting notes in markdown format.

        RULES:
        1. Keep user's original notes intact but clean up formatting.
        2. Organize by topic with clear headings.
        3. Extract action items, decisions, and key points.
        4. Use bullet points, not paragraphs.
        5. Be concise and professional.
        6. For action items, extract REAL names from the transcript for assignees (not generic labels like "Speaker 0"). Look for who volunteered, who was asked to do something, or who is clearly responsible.
        7. Extract specific dates/deadlines mentioned in the conversation. Format deadlines as readable dates (e.g., "Friday", "March 28", "End of week", "Next Monday").
        8. If no specific assignee is mentioned, use null. If no deadline is mentioned, use null.

        MEETING: \(meetingTitle)
        ATTENDEES: \(attendees.isEmpty ? "Unknown" : attendees.joined(separator: ", "))
        """

        let hasTranscript = !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasNotes = !userNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        var userMessage = ""
        if hasNotes {
            userMessage += "USER'S NOTES:\n\(userNotes)\n\n"
        }
        if hasTranscript {
            userMessage += "MEETING TRANSCRIPT:\n\(transcript)\n\n"
        }
        userMessage += """
        Produce enhanced meeting notes in clean markdown. After the notes, add exactly this separator on its own line:
        ---SUMMARY_JSON---
        Then return ONLY a valid JSON object (no markdown fences) with these keys:
        {"title":"string","overview":"string","key_points":["string"],"action_items":[{"task":"string","assignee":null,"deadline":null}],"decisions":["string"],"questions_raised":["string"],"sentiment":"neutral","topics":["string"]}
        """

        let response = try await callClaudeAPI(system: systemPrompt, message: userMessage, maxTokens: 4096)

        // Parse response: split enhanced notes from summary JSON
        let separator = "---SUMMARY_JSON---"
        let parts = response.components(separatedBy: separator)
        let enhancedContent = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)

        var summary: MeetingSummary
        if parts.count > 1 {
            let jsonStr = parts[1]
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            summary = parseJSONSummary(jsonStr, fallbackTitle: meetingTitle)
        } else {
            // Try to find JSON in the response itself
            summary = extractJSONFromResponse(response, fallbackTitle: meetingTitle)
        }

        return EnhancedNote(content: enhancedContent, summary: summary)
    }

    /// Generate just a summary from transcript
    func generateSummary(transcript: String, meetingTitle: String) async throws -> MeetingSummary {
        if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return defaultSummary(title: meetingTitle)
        }

        let systemPrompt = "You are a meeting summarization AI. Return ONLY valid JSON, no other text, no markdown fences. For action items, extract REAL names from the transcript as assignees (not 'Speaker 0'). Extract specific deadlines mentioned (e.g., 'Friday', 'March 28', 'End of week')."

        let userMessage = """
        Summarize this meeting transcript as JSON:

        \(transcript.prefix(8000))

        Return exactly this structure:
        {"title":"string","overview":"string","key_points":["string"],"action_items":[{"task":"string","assignee":"real name or null","deadline":"readable date or null"}],"decisions":["string"],"questions_raised":["string"],"sentiment":"neutral","topics":["string"]}
        """

        let response = try await callClaudeAPI(system: systemPrompt, message: userMessage, maxTokens: 2048)
        return parseJSONSummary(response, fallbackTitle: meetingTitle)
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
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": Constants.anthropicModel,
            "max_tokens": maxTokens,
            "system": system,
            "messages": [
                ["role": "user", "content": message]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        print("[EnhancementService] Calling Claude API...")

        let (data, httpResponse) = try await URLSession.shared.data(for: request)

        if let http = httpResponse as? HTTPURLResponse, http.statusCode != 200 {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("[EnhancementService] HTTP \(http.statusCode): \(errorBody)")
            throw EnhancementError.apiError("HTTP \(http.statusCode)")
        }

        // Parse the Claude response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstBlock = content.first,
              let text = firstBlock["text"] as? String else {
            // Fallback: try Codable
            do {
                let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
                return response.content.first?.text ?? ""
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "nil"
                print("[EnhancementService] Parse error. Raw response: \(raw.prefix(500))")
                throw EnhancementError.apiError("Failed to parse response")
            }
        }

        print("[EnhancementService] Got response: \(text.prefix(100))...")
        return text
    }

    // MARK: - JSON Parsing Helpers

    private func parseJSONSummary(_ str: String, fallbackTitle: String) -> MeetingSummary {
        let cleaned = str
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            return defaultSummary(title: fallbackTitle)
        }

        // Try strict decode first
        if let summary = try? JSONDecoder().decode(MeetingSummary.self, from: data) {
            return summary
        }

        // Try extracting JSON object from string (Claude sometimes adds text before/after)
        if let startIdx = cleaned.firstIndex(of: "{"),
           let endIdx = cleaned.lastIndex(of: "}") {
            let jsonOnly = String(cleaned[startIdx...endIdx])
            if let jsonData = jsonOnly.data(using: .utf8),
               let summary = try? JSONDecoder().decode(MeetingSummary.self, from: jsonData) {
                return summary
            }
        }

        // Manual parse as last resort
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return manualParseSummary(json, fallbackTitle: fallbackTitle)
        }

        return defaultSummary(title: fallbackTitle)
    }

    private func extractJSONFromResponse(_ response: String, fallbackTitle: String) -> MeetingSummary {
        // Find the last JSON object in the response
        if let startIdx = response.lastIndex(of: "{"),
           let endIdx = response.lastIndex(of: "}"),
           startIdx < endIdx {
            let jsonStr = String(response[startIdx...endIdx])
            return parseJSONSummary(jsonStr, fallbackTitle: fallbackTitle)
        }
        return defaultSummary(title: fallbackTitle)
    }

    private func manualParseSummary(_ json: [String: Any], fallbackTitle: String) -> MeetingSummary {
        MeetingSummary(
            title: json["title"] as? String ?? fallbackTitle,
            overview: json["overview"] as? String ?? "",
            keyPoints: json["key_points"] as? [String] ?? [],
            actionItems: (json["action_items"] as? [[String: Any]])?.compactMap { item in
                guard let task = item["task"] as? String else { return nil }
                return MeetingSummary.ActionItem(
                    task: task,
                    assignee: item["assignee"] as? String,
                    deadline: item["deadline"] as? String
                )
            } ?? [],
            decisions: json["decisions"] as? [String] ?? [],
            questionsRaised: json["questions_raised"] as? [String] ?? [],
            sentiment: json["sentiment"] as? String ?? "neutral",
            topics: json["topics"] as? [String] ?? []
        )
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
    case noContent

    var errorDescription: String? {
        switch self {
        case .missingAPIKey: return "Anthropic API key not configured. Set it in Settings."
        case .apiError(let msg): return "Enhancement failed: \(msg)"
        case .noContent: return "No notes or transcript to enhance"
        }
    }
}
