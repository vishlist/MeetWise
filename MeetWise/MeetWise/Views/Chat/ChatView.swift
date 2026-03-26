import SwiftUI
import SwiftData

struct ChatView: View {
    @State private var chatInput = ""
    @State private var selectedScope = "My notes"
    @Environment(AppState.self) private var appState
    @Query(sort: \Meeting.startedAt, order: .reverse) private var meetings: [Meeting]
    @Query(sort: \Recipe.position) private var recipes: [Recipe]
    @Query(sort: \Folder.position) private var folders: [Folder]
    @State private var messages: [(role: String, content: String)] = []

    // Issue 12: Filter/sort state
    @State private var selectedFolderFilter: Folder?
    @State private var selectedSort = "Most recent"
    @State private var selectedDateRange = "All time"

    private var chatService: ChatService {
        appState.chatService
    }

    // Issue 12: Filtered and sorted meetings
    private var scopedMeetings: [Meeting] {
        var result: [Meeting]

        switch selectedScope {
        case "My notes":
            result = meetings.filter { !$0.userNotes.isEmpty || $0.enhancedNotes != nil }
        default:
            result = Array(meetings)
        }

        // Issue 9: Exclude empty drafts
        result = result.filter { !$0.isDraft || $0.hasContent }

        // Issue 12: Filter by folder
        if let folder = selectedFolderFilter {
            result = result.filter { $0.folder?.id == folder.id }
        }

        // Issue 12: Date range filter
        let now = Date()
        let calendar = Calendar.current
        switch selectedDateRange {
        case "This week":
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
            result = result.filter { $0.startedAt >= startOfWeek }
        case "This month":
            let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
            result = result.filter { $0.startedAt >= startOfMonth }
        case "Last 3 months":
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            result = result.filter { $0.startedAt >= threeMonthsAgo }
        default:
            break // "All time"
        }

        // Issue 12: Sort
        switch selectedSort {
        case "Oldest first":
            result.sort { $0.startedAt < $1.startedAt }
        case "Most relevant":
            // Sort by those with enhanced notes first, then by date
            result.sort { a, b in
                let aHasEnhanced = a.enhancedNotes != nil
                let bHasEnhanced = b.enhancedNotes != nil
                if aHasEnhanced != bHasEnhanced { return aHasEnhanced }
                return a.startedAt > b.startedAt
            }
        default: // "Most recent"
            result.sort { $0.startedAt > $1.startedAt }
        }

        return result
    }

    // Issue 12: Active filter count
    private var activeFilterCount: Int {
        var count = 0
        if selectedFolderFilter != nil { count += 1 }
        if selectedDateRange != "All time" { count += 1 }
        if selectedSort != "Most recent" { count += 1 }
        return count
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
            }

            Text("Ask anything")
                .font(.heading(32))
                .foregroundStyle(Theme.textHeading)

            Text("I can help you search across your meetings, find action items, write follow-ups, and more.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Theme.textSecondary)
                .lineSpacing(3)
        }
    }

    // MARK: - Bot Avatar (dark charcoal circle with white MW)
    private var botAvatar: some View {
        Circle()
            .fill(Theme.accent)
            .frame(width: 32, height: 32)
            .overlay(
                Text("MW")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white)
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
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Issue 12: Filter/Sort controls
            HStack(spacing: 8) {
                // Filter by folder
                Menu {
                    Button {
                        selectedFolderFilter = nil
                    } label: {
                        HStack {
                            Text("All Folders")
                            if selectedFolderFilter == nil {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    Divider()
                    ForEach(folders) { folder in
                        Button {
                            selectedFolderFilter = folder
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                Text(folder.name)
                                if selectedFolderFilter?.id == folder.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "folder").font(.system(size: 10))
                        Text(selectedFolderFilter?.name ?? "All Folders")
                            .font(.system(size: 11, weight: .light))
                    }
                    .foregroundStyle(selectedFolderFilter != nil ? Theme.textPrimary : Theme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedFolderFilter != nil ? Theme.accentSoft : Theme.bgHover)
                    .cornerRadius(Theme.radiusPill)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                // Sort by
                Menu {
                    ForEach(["Most recent", "Oldest first", "Most relevant"], id: \.self) { option in
                        Button {
                            selectedSort = option
                        } label: {
                            HStack {
                                Text(option)
                                if selectedSort == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down").font(.system(size: 10))
                        Text(selectedSort)
                            .font(.system(size: 11, weight: .light))
                    }
                    .foregroundStyle(selectedSort != "Most recent" ? Theme.textPrimary : Theme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedSort != "Most recent" ? Theme.accentSoft : Theme.bgHover)
                    .cornerRadius(Theme.radiusPill)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                // Date range
                Menu {
                    ForEach(["All time", "This week", "This month", "Last 3 months"], id: \.self) { option in
                        Button {
                            selectedDateRange = option
                        } label: {
                            HStack {
                                Text(option)
                                if selectedDateRange == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar").font(.system(size: 10))
                        Text(selectedDateRange)
                            .font(.system(size: 11, weight: .light))
                    }
                    .foregroundStyle(selectedDateRange != "All time" ? Theme.textPrimary : Theme.textMuted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedDateRange != "All time" ? Theme.accentSoft : Theme.bgHover)
                    .cornerRadius(Theme.radiusPill)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                // Issue 12: Active filter badge
                if activeFilterCount > 0 {
                    Button {
                        // Reset all filters
                        selectedFolderFilter = nil
                        selectedSort = "Most recent"
                        selectedDateRange = "All time"
                    } label: {
                        HStack(spacing: 3) {
                            Text("\(activeFilterCount) filter\(activeFilterCount > 1 ? "s" : "")")
                                .font(.system(size: 10, weight: .medium))
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundStyle(Theme.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Theme.accentSoft)
                        .cornerRadius(Theme.radiusPill)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)

            // Input field
            HStack(spacing: 12) {
                TextField("Transcribe a meeting to start asking questions", text: $chatInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .light))
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
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusLG)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }

    // MARK: - Recipes Section (warm gray bg)
    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Suggested")
                .font(.custom("IBMPlexSerif-Bold", size: 14))
                .foregroundStyle(Theme.textSecondary)

            let displayRecipes = recipes.isEmpty ? defaultRecipePills : recipes.map { ($0.name, Theme.accent) }

            FlowLayout(spacing: 8) {
                ForEach(Array(displayRecipes.enumerated()), id: \.offset) { index, recipe in
                    // Issue 3: Check if recipe is available on free plan
                    let isAvailable = appState.isRecipeAvailable(index: index)
                    recipePill(recipe.0, tintColor: Theme.tintColors[index % Theme.tintColors.count], isLocked: !isAvailable)
                }
            }
        }
    }

    private var defaultRecipePills: [(String, Color)] {
        [
            ("List action items", Theme.accent),
            ("Show pending tasks", Theme.accent),
            ("Write follow up email", Theme.accent),
            ("Coach me", Theme.accent),
            ("Weekly recap", Theme.accent),
            ("Blind spots", Theme.accent),
            ("Streamline my calendar", Theme.accent),
            ("Summarize last meeting", Theme.accent),
        ]
    }

    // MARK: - Components
    private func scopeTab(_ title: String, isSelected: Bool) -> some View {
        Button { selectedScope = title } label: {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .medium : .light))
                .foregroundStyle(isSelected ? Theme.textPrimary : Theme.textSecondary)
                .padding(.bottom, 4)
                .overlay(alignment: .bottom) {
                    if isSelected {
                        Rectangle().fill(Theme.accent).frame(height: 2)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    private func recipePill(_ title: String, tintColor: Color, isLocked: Bool = false) -> some View {
        Button {
            if isLocked {
                appState.showUpgrade("This recipe requires a Pro plan. Upgrade to access all 12 recipes.")
                return
            }
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
                    .foregroundStyle(isLocked ? Theme.textMuted : Theme.textSecondary)
                Text(title)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(isLocked ? Theme.textMuted : Theme.textPrimary)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isLocked ? Theme.bgHover : tintColor)
            .cornerRadius(Theme.radiusPill)
        }
        .buttonStyle(.plain)
        .hoverScale(1.03)
    }

    private func chatBubble(role: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if role == "assistant" {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text("MW")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Color.white)
                    )
            }

            Text(content)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Theme.textPrimary)
                .textSelection(.enabled)
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(role == "user" ? Theme.tintWarm : Theme.bgCard)
                .cornerRadius(Theme.radiusMD)
                .shadow(color: role == "assistant" ? Color.black.opacity(0.04) : .clear, radius: 4, x: 0, y: 1)

            if role == "user" {
                Circle()
                    .fill(Theme.accentSoft)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Text(appState.currentUser?.initials ?? "U")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Theme.textPrimary)
                    )
            }
        }
    }

    // MARK: - Actions
    private func sendMessage() {
        guard !chatInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        // Issue 3: Check chat limit
        if !appState.checkChatLimit() {
            let used = appState.currentUser?.chatQuestionsToday ?? 0
            messages.append((role: "assistant", content: "You've used \(used)/\(UserProfile.freeChatLimit) free chat questions today. Upgrade to Pro for unlimited."))
            return
        }

        let question = chatInput
        chatInput = ""
        messages.append((role: "user", content: question))

        appState.incrementChatCount()

        Task {
            let response = await chatService.askAcrossMeetings(question, meetings: scopedMeetings)
            messages.append((role: "assistant", content: response))
        }
    }

    private func executeRecipe(_ recipe: Recipe) {
        messages.append((role: "user", content: "/\(recipe.name)"))
        chatInput = ""

        appState.incrementChatCount()

        Task {
            let response = await chatService.executeRecipe(recipe, meetings: scopedMeetings)
            messages.append((role: "assistant", content: response))
        }
    }
}
