import Foundation
import SwiftData

final class RecipeService {
    static let builtInRecipes: [(name: String, prompt: String, color: String, category: String)] = [
        (
            "List recent todos",
            """
            You are a task extractor. Review the meeting notes and transcripts provided.
            Extract ALL action items, tasks, and to-dos mentioned. For each:
            - State the task clearly
            - Note who is responsible (if mentioned)
            - Note any deadline (if mentioned)
            Format as a numbered checklist. Be thorough — don't miss any commitments.
            """,
            "#6b8f5e", // green
            "productivity"
        ),
        (
            "Coach me",
            """
            You are a meeting coach. Analyze how the user participated in these meetings.
            Consider:
            - Did they speak too much or too little?
            - Did they ask good open-ended questions?
            - Were they an active listener?
            - Did they stay on topic?
            - Were there missed opportunities to contribute?
            Give specific, actionable feedback with examples from the meetings.
            Be encouraging but honest. Format as bullet points under clear categories.
            """,
            "#6b8f5e",
            "coaching"
        ),
        (
            "Write weekly recap",
            """
            You are a professional writer. Create a concise weekly recap email from these meeting notes.
            Structure:
            - **Key Accomplishments** (what was decided/completed)
            - **In Progress** (ongoing items)
            - **Upcoming** (what's next)
            - **Blockers** (if any mentioned)
            Keep it professional, concise, and actionable. Use bullet points.
            """,
            "#c4854a", // orange
            "writing"
        ),
        (
            "Streamline my calendar",
            """
            You are a productivity consultant. Analyze these meetings and suggest:
            - Which recurring meetings could be shorter?
            - Which meetings could be emails instead?
            - Are there redundant meetings covering the same topics?
            - What's the optimal meeting schedule suggestion?
            Be specific with meeting names and concrete time-saving suggestions.
            """,
            "#6b8f5e",
            "productivity"
        ),
        (
            "Blind spots",
            """
            You are a strategic advisor. Analyze these meeting notes for:
            - Topics that were mentioned but never followed up on
            - Decisions that lack clear owners
            - Risks or concerns that were raised but not addressed
            - Important topics that SHOULD have been discussed but weren't
            - Patterns or trends the user might be missing
            Be insightful and specific. Reference particular meetings.
            """,
            "#b8a44a", // yellow
            "coaching"
        ),
        (
            "Write follow up email",
            """
            You are a professional writer. Based on the meeting notes, draft a follow-up email that:
            - Thanks attendees for their time
            - Summarizes key decisions made
            - Lists action items with owners and deadlines
            - Notes any open questions or next steps
            Keep it professional, friendly, and concise. Ready to send.
            """,
            "#6b8f5e",
            "writing"
        ),
        (
            "Extract objections",
            """
            You are a sales analyst. Review these meeting notes for:
            - All objections raised by the prospect/customer
            - Concerns or hesitations expressed
            - Questions that suggest doubt
            - Competitive mentions
            For each, suggest a response strategy. Format clearly.
            """,
            "#c4854a",
            "sales"
        ),
        (
            "Summarize decisions",
            """
            You are a meeting analyst. Extract ALL decisions made across these meetings:
            - What was decided
            - Who made or approved the decision
            - When it was decided
            - Any conditions or caveats
            Format as a clear, numbered list sorted by date.
            """,
            "#6b8f5e",
            "productivity"
        ),
        (
            "Write a Brief",
            """
            You are a product manager. Turn these brainstorming/meeting notes into a structured brief:
            - **Problem Statement**: What are we solving?
            - **Goals**: What does success look like?
            - **Proposed Solution**: Key features/approach
            - **Open Questions**: What still needs answers?
            - **Next Steps**: Immediate actions
            Be concise but thorough. Reference specific discussion points.
            """,
            "#4a7fb8", // blue
            "writing"
        )
    ]

    /// Initialize built-in recipes in SwiftData if they don't exist
    static func seedRecipes(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Recipe>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for (i, r) in builtInRecipes.enumerated() {
            let recipe = Recipe(name: r.name, prompt: r.prompt, iconColor: r.color, category: r.category)
            recipe.isBuiltIn = true
            recipe.position = i
            modelContext.insert(recipe)
        }
        try? modelContext.save()
    }
}
