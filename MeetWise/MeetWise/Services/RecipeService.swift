import Foundation
import SwiftData

/// Built-in AI recipe templates
struct RecipeService {
    /// Seed built-in recipes into SwiftData if none exist
    static func seedRecipes(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Recipe>()
        let existing = (try? modelContext.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        for (index, template) in builtInRecipes.enumerated() {
            let recipe = Recipe(
                name: template.name,
                prompt: template.prompt,
                iconColor: "#ffffff",
                category: "builtin"
            )
            recipe.position = index
            modelContext.insert(recipe)
        }
        try? modelContext.save()
    }

    static let builtInRecipes: [RecipeTemplate] = [
        RecipeTemplate(name: "List recent todos", icon: "checklist", prompt: "Extract ALL action items and todos from the provided meetings. Format as a checklist with assignees and deadlines where mentioned. Group by meeting."),
        RecipeTemplate(name: "Coach me", icon: "figure.mind.and.body", prompt: "Act as a meeting coach. Review the meeting and provide feedback on: communication effectiveness, areas for improvement, talking vs listening ratio, and specific suggestions for the next meeting."),
        RecipeTemplate(name: "Write weekly recap", icon: "calendar.badge.clock", prompt: "Write a concise weekly recap email summarizing all meetings from this week. Include: key decisions, action items, blockers, and what's planned next. Format as a professional email."),
        RecipeTemplate(name: "Streamline my calendar", icon: "calendar.badge.minus", prompt: "Analyze the meeting patterns and suggest: which recurring meetings could be shorter, which could be emails instead, and how to optimize the calendar for deep work blocks."),
        RecipeTemplate(name: "Blind spots", icon: "eye.slash", prompt: "Identify potential blind spots from these meetings: topics that were mentioned but not fully discussed, questions that went unanswered, risks that were acknowledged but not addressed, and people who weren't heard enough."),
        RecipeTemplate(name: "Write follow up email", icon: "envelope", prompt: "Write a SHORT, professional follow-up email (max 150 words). Include only: 1 sentence summary of what was discussed, 3-5 bullet point action items with owners, next steps in 1 sentence. Keep the tone warm but brief. No fluff, no pleasantries beyond 'Hi team'. Sign off with just 'Best, [Name]'."),
        RecipeTemplate(name: "Summarize decisions", icon: "checkmark.seal", prompt: "List every decision that was made in these meetings. For each decision include: what was decided, who made the decision, the rationale if mentioned, and any conditions or caveats."),
        RecipeTemplate(name: "Extract key metrics", icon: "chart.bar", prompt: "Extract all numbers, metrics, KPIs, dates, and quantitative information mentioned in the meetings. Present in a clean table format."),
        RecipeTemplate(name: "Identify risks", icon: "exclamationmark.triangle", prompt: "Identify all risks, concerns, blockers, and potential issues mentioned in these meetings. Categorize by severity (high/medium/low) and suggest mitigation strategies."),
        RecipeTemplate(name: "Meeting effectiveness score", icon: "star", prompt: "Rate this meeting's effectiveness on a scale of 1-10 based on: clear agenda, actionable outcomes, time efficiency, participant engagement, and follow-up clarity. Provide specific improvement suggestions."),
        RecipeTemplate(name: "Prepare for next meeting", icon: "arrow.right.circle", prompt: "Based on the previous meetings, prepare a brief for the next meeting with: unresolved items, pending action items, topics to follow up on, and suggested agenda items."),
        RecipeTemplate(name: "Stakeholder update", icon: "person.3", prompt: "Write a brief stakeholder update based on these meetings. Keep it high-level, focus on progress, blockers, and decisions. Suitable for sharing with leadership.")
    ]
}

struct RecipeTemplate: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let prompt: String
}
