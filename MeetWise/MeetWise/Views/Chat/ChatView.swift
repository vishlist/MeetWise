import SwiftUI
import SwiftData

struct ChatView: View {
    @State private var chatInput = ""
    @State private var selectedScope = "My notes"
    @State private var chatService = ChatService()
    @State private var messages: [(role: String, content: String)] = []
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @Query(sort: \Recipe.position) private var recipes: [Recipe]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("Ask anything")
                        .font(.heading(32))
                        .foregroundStyle(Theme.textHeading)
                        .padding(.top, 40)

                    // Chat messages
                    if !messages.isEmpty {
                        ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                            chatBubble(role: msg.role, content: msg.content)
                        }
                    }

                    // Chat input card
                    chatInputCard

                    // Recipes
                    if messages.isEmpty {
                        recipesSection
                    }
                }
                .padding(.horizontal, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }

    // MARK: - Chat Input Card
    private var chatInputCard: some View {
        VStack(spacing: 0) {
            // Scope tabs
            HStack(spacing: 12) {
                scopeTab("My notes", isSelected: selectedScope == "My notes")
                scopeTab("All meetings", isSelected: selectedScope == "All meetings")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Input field
            HStack(spacing: 12) {
                TextField("Transcribe a meeting to start asking questions", text: $chatInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .onSubmit { sendMessage() }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Bottom toolbar
            HStack(spacing: 12) {
                Button { } label: {
                    Image(systemName: "paperclip")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)

                Button { } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)

                Spacer()

                if chatService.isLoading {
                    ProgressView()
                        .controlSize(.small)
                }

                Button { } label: {
                    Image(systemName: "mic")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusLG)
                .stroke(Theme.bgCardBorder, lineWidth: 1)
        )
    }

    // MARK: - Recipes Section
    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipes")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textSecondary)

            let displayRecipes = recipes.isEmpty ? defaultRecipePills : recipes.map { ($0.name, Color(hex: $0.iconColor)) }

            FlowLayout(spacing: 8) {
                ForEach(Array(displayRecipes.enumerated()), id: \.offset) { _, recipe in
                    recipePill(recipe.0, color: recipe.1)
                }

                Button { } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2")
                            .font(.system(size: 11))
                        Text("See all")
                            .font(.system(size: 13))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                    }
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusPill)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var defaultRecipePills: [(String, Color)] {
        [
            ("List recent todos", Theme.accentGreen),
            ("Coach me", Theme.accentGreen),
            ("Write weekly recap", Theme.accentOrange),
            ("Streamline my calendar", Theme.accentGreen),
            ("Blind spots", Theme.accentYellow)
        ]
    }

    // MARK: - Components
    private func scopeTab(_ title: String, isSelected: Bool) -> some View {
        Button { selectedScope = title } label: {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle().fill(Theme.textPrimary).frame(height: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func recipePill(_ title: String, color: Color) -> some View {
        Button {
            chatInput = "/\(title)"
            // Find matching recipe and execute
            if let recipe = recipes.first(where: { $0.name == title }) {
                executeRecipe(recipe)
            }
        } label: {
            HStack(spacing: 6) {
                Text("/")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusPill)
        }
        .buttonStyle(.plain)
    }

    private func chatBubble(role: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if role == "assistant" {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.accentGreen)
                    .frame(width: 28, height: 28)
                    .background(Theme.accentGreen.opacity(0.15))
                    .cornerRadius(14)
            }

            Text(content)
                .font(.system(size: 14))
                .foregroundStyle(role == "user" ? Theme.textPrimary : Theme.textSecondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(role == "user" ? Theme.bgCard : Theme.bgCard.opacity(0.5))
                .cornerRadius(Theme.radiusMD)

            if role == "user" {
                Circle()
                    .fill(Theme.accentGreen)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("VA").font(.system(size: 10, weight: .medium)).foregroundStyle(.white)
                    )
            }
        }
    }

    // MARK: - Actions
    private func sendMessage() {
        guard !chatInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let question = chatInput
        chatInput = ""
        messages.append((role: "user", content: question))

        Task {
            let response = await chatService.askAcrossMeetings(question, meetings: meetings)
            messages.append((role: "assistant", content: response))
        }
    }

    private func executeRecipe(_ recipe: Recipe) {
        messages.append((role: "user", content: "/\(recipe.name)"))
        chatInput = ""
        Task {
            let response = await chatService.executeRecipe(recipe, meetings: meetings)
            messages.append((role: "assistant", content: response))
        }
    }
}
