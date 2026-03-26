import SwiftUI
import SwiftData

struct ChatView: View {
    @State private var chatInput = ""
    @State private var selectedScope = "My notes"
    @Environment(AppState.self) private var appState
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @Query(sort: \Recipe.position) private var recipes: [Recipe]
    @State private var messages: [(role: String, content: String)] = []

    private var chatService: ChatService {
        appState.chatService
    }

    private var scopedMeetings: [Meeting] {
        switch selectedScope {
        case "My notes":
            return meetings.filter { !$0.userNotes.isEmpty || $0.enhancedNotes != nil }
        default:
            return meetings
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        if messages.isEmpty {
                            emptyStateHeader
                        }

                        // Chat messages
                        if !messages.isEmpty {
                            ForEach(Array(messages.enumerated()), id: \.offset) { index, msg in
                                chatBubble(role: msg.role, content: msg.content)
                                    .id(index)
                            }

                            if chatService.isLoading {
                                HStack(alignment: .top, spacing: 10) {
                                    botAvatar
                                    TypingIndicator()
                                        .padding(.top, 8)
                                }
                                .padding(.leading, 4)
                                .id("loading")
                            }
                        }

                        // Chat input card (always visible)
                        chatInputCard

                        // Recipes (show when no messages)
                        if messages.isEmpty {
                            recipesSection
                        }
                    }
                    .padding(.horizontal, 48)
                    .padding(.top, messages.isEmpty ? 60 : 24)
                    .padding(.bottom, 40)
                }
                .onChange(of: messages.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo(messages.count - 1, anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }

    // MARK: - Empty State Header
    private var emptyStateHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                botAvatar
                Text("MeetWise AI")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }

            Text("Ask anything")
                .font(.heading(32))
                .foregroundStyle(Theme.textHeading)

            Text("I can help you search across your meetings, find action items, write follow-ups, and more.")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
        }
    }

    // MARK: - Bot Avatar
    private var botAvatar: some View {
        Circle()
            .fill(Color(hex: "#333333"))
            .frame(width: 32, height: 32)
            .overlay(
                Text("MW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Theme.textPrimary)
            )
    }

    // MARK: - Chat Input Card
    private var chatInputCard: some View {
        VStack(spacing: 0) {
            // Scope tabs
            HStack(spacing: 12) {
                scopeTab("My notes", isSelected: selectedScope == "My notes")
                scopeTab("All meetings", isSelected: selectedScope == "All meetings")
                Spacer()

                if !meetings.isEmpty {
                    Text("\(scopedMeetings.count) meetings")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                }
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

                if chatService.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Button { sendMessage() } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(chatInput.isEmpty ? Theme.textMuted : Theme.accent)
                    }
                    .buttonStyle(.plain)
                    .disabled(chatInput.isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Bottom toolbar
            HStack(spacing: 12) {
                Spacer()
                Text("Powered by Claude")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)
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
            Text("Suggested")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Theme.textSecondary)

            let displayRecipes = recipes.isEmpty ? defaultRecipePills : recipes.map { ($0.name, Theme.accent) }

            FlowLayout(spacing: 8) {
                ForEach(Array(displayRecipes.enumerated()), id: \.offset) { _, recipe in
                    recipePill(recipe.0, color: recipe.1)
                }
            }
        }
    }

    private var defaultRecipePills: [(String, Color)] {
        [
            ("List action items", Theme.accent),
            ("Show pending tasks", Theme.accent),
            ("Write follow up email", Theme.accentOrange),
            ("Coach me", Theme.accent),
            ("Weekly recap", Theme.accentYellow),
            ("Blind spots", Theme.accent),
            ("Streamline my calendar", Theme.accentOrange),
            ("Summarize last meeting", Theme.accent),
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
            if let recipe = recipes.first(where: { $0.name == title }) {
                executeRecipe(recipe)
            } else {
                chatInput = title
                sendMessage()
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
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusPill)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .hoverScale(1.03)
    }

    private func chatBubble(role: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if role == "assistant" {
                Circle()
                    .fill(Color(hex: "#333333"))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("MW")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    )
            }

            Text(content)
                .font(.system(size: 14))
                .foregroundStyle(role == "user" ? Theme.textPrimary : Theme.textSecondary)
                .textSelection(.enabled)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(role == "user" ? Theme.bgCard : Color(hex: "#1a1a1a"))
                .cornerRadius(Theme.radiusMD)

            if role == "user" {
                Circle()
                    .fill(Theme.textMuted)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(appState.currentUser?.initials ?? "U")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.bgPrimary)
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
            let response = await chatService.askAcrossMeetings(question, meetings: scopedMeetings)
            messages.append((role: "assistant", content: response))
        }
    }

    private func executeRecipe(_ recipe: Recipe) {
        messages.append((role: "user", content: "/\(recipe.name)"))
        chatInput = ""
        Task {
            let response = await chatService.executeRecipe(recipe, meetings: scopedMeetings)
            messages.append((role: "assistant", content: response))
        }
    }
}
