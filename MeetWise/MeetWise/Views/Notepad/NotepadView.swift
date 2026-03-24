import SwiftUI
import SwiftData

struct NotepadView: View {
    let meeting: Meeting
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    var sessionManager: MeetingSessionManager
    @State private var userNotes: String
    @State private var chatInput = ""
    @State private var isEnhancing = false
    @State private var showChatSidebar = false
    @State private var showTemplateSelector = false
    @State private var selectedTemplate: NoteTemplate = .auto
    @State private var chatMessages: [(role: String, content: String)] = []
    @State private var chatService = ChatService()
    @State private var copiedToClipboard = false

    init(meeting: Meeting, sessionManager: MeetingSessionManager) {
        self.meeting = meeting
        self.sessionManager = sessionManager
        self._userNotes = State(initialValue: meeting.userNotes)
    }

    private var isActiveRecording: Bool {
        sessionManager.isRecording && sessionManager.currentMeeting?.id == meeting.id
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main note area
            mainContent

            // CMD+J Chat sidebar
            if showChatSidebar {
                Divider().background(Theme.divider)
                chatSidebar
                    .frame(width: 320)
                    .transition(.move(edge: .trailing))
            }
        }
        .background(Theme.bgPrimary)
        .onChange(of: userNotes) { _, newValue in
            meeting.userNotes = newValue
            try? modelContext.save()
        }
        .onKeyPress(keys: [.init("j")], phases: .down) { press in
            if press.modifiers.contains(.command) {
                withAnimation(.easeInOut(duration: 0.2)) { showChatSidebar.toggle() }
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            topBar
            Divider().background(Theme.divider)

            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        meetingHeader
                            .padding(.horizontal, 48)
                            .padding(.top, 32)

                        metadataPills
                            .padding(.horizontal, 48)
                            .padding(.top, 12)

                        if let enhanced = meeting.enhancedNotes, !enhanced.isEmpty {
                            enhancedContent(enhanced)
                                .padding(.horizontal, 48)
                                .padding(.top, 24)
                        } else {
                            noteEditor
                                .padding(.horizontal, 44)
                                .padding(.top, 16)
                        }

                        Spacer(minLength: 80)
                    }
                }

                bottomBar
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                appState.selectedMeeting = nil
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12))
                    Image(systemName: "house")
                        .font(.system(size: 14))
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(6)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
            }
            .buttonStyle(.plain)

            Spacer()

            if isActiveRecording {
                HStack(spacing: 6) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text(sessionManager.formattedDuration)
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.15))
                .cornerRadius(Theme.radiusPill)
            }

            // Enhanced badge
            if meeting.enhancedNotes != nil {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text("Enhanced")
                        .font(.system(size: 13))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
            }

            // Share
            Button {
                ShareService.copyNotesToClipboard(meeting: meeting)
                copiedToClipboard = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedToClipboard = false }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "lock")
                        .font(.system(size: 11))
                    Text(copiedToClipboard ? "Copied!" : "Share")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Link (copy markdown)
            Button {
                ShareService.copyAsMarkdown(meeting: meeting)
            } label: {
                Image(systemName: "link")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(6)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
            }
            .buttonStyle(.plain)

            // Chat sidebar toggle (CMD+J)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showChatSidebar.toggle() }
            } label: {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 13))
                    .foregroundStyle(showChatSidebar ? Theme.accentGreen : Theme.textSecondary)
                    .padding(6)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
            }
            .buttonStyle(.plain)

            // More
            Button { } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(6)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Meeting Header
    private var meetingHeader: some View {
        Text(meeting.title)
            .font(.heading(28))
            .foregroundStyle(Theme.textHeading)
            .textSelection(.enabled)
    }

    // MARK: - Metadata Pills
    private var metadataPills: some View {
        HStack(spacing: 8) {
            metadataPill(icon: "calendar", text: isToday(meeting.startedAt) ? "Today" : meeting.formattedDate)

            if let participants = meeting.participants, !participants.isEmpty {
                metadataPill(icon: "person.2", text: participants.map(\.name).joined(separator: ", "))
            } else {
                metadataPill(icon: "person.2", text: "Me")
            }

            // Template selector
            Button { showTemplateSelector.toggle() } label: {
                HStack(spacing: 4) {
                    Image(systemName: selectedTemplate.icon)
                        .font(.system(size: 10))
                    Text(selectedTemplate.rawValue)
                        .font(.system(size: 12))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusPill)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusPill).stroke(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showTemplateSelector) {
                templatePopover
            }

            Button { } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus").font(.system(size: 10))
                    Text("Add to folder").font(.system(size: 12))
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusPill)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusPill).stroke(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    // MARK: - Template Popover
    private var templatePopover: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Template")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(NoteTemplate.allCases) { template in
                Button {
                    selectedTemplate = template
                    meeting.templateID = template.rawValue
                    showTemplateSelector = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: template.icon)
                            .font(.system(size: 12))
                            .frame(width: 20)
                        Text(template.rawValue)
                            .font(.system(size: 13))
                        Spacer()
                        if selectedTemplate == template {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.accentGreen)
                        }
                    }
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(width: 220)
        .padding(.vertical, 4)
        .background(Theme.bgCard)
    }

    private func metadataPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11))
            Text(text).font(.system(size: 12))
        }
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusPill)
        .overlay(RoundedRectangle(cornerRadius: Theme.radiusPill).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: - Note Editor
    private var noteEditor: some View {
        TextEditor(text: $userNotes)
            .font(.system(size: 15))
            .foregroundStyle(Theme.textPrimary)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 400)
            .overlay(alignment: .topLeading) {
                if userNotes.isEmpty {
                    Text("Start taking notes...")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.textMuted)
                        .padding(.leading, 5)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
    }

    // MARK: - Enhanced Content
    private func enhancedContent(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            let lines = content.components(separatedBy: "\n")
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                enhancedLine(line)
            }
        }
    }

    @ViewBuilder
    private func enhancedLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            Spacer().frame(height: 8)
        } else if trimmed.hasPrefix("# ") {
            HStack(spacing: 6) {
                Text("#").font(.system(size: 14)).foregroundStyle(Theme.textMuted)
                Text(String(trimmed.dropFirst(2)))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.top, 12)
        } else if trimmed.hasPrefix("## ") {
            HStack(spacing: 6) {
                Text("#").font(.system(size: 13)).foregroundStyle(Theme.textMuted)
                Text(String(trimmed.dropFirst(3)))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.top, 8)
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("• ") {
            bulletLine(String(trimmed.dropFirst(2)), isAI: line.contains("[AI]"), indent: 0)
        } else if trimmed.hasPrefix("  - ") || trimmed.hasPrefix("  • ") || trimmed.hasPrefix("  ○ ") {
            bulletLine(String(trimmed.dropFirst(4)), isAI: line.contains("[AI]"), indent: 1)
        } else if trimmed.hasPrefix("    - ") || trimmed.hasPrefix("    ○ ") {
            bulletLine(String(trimmed.dropFirst(6)), isAI: line.contains("[AI]"), indent: 2)
        } else {
            let isAI = line.contains("[AI]")
            let cleaned = line
                .replacingOccurrences(of: "[AI]", with: "")
                .replacingOccurrences(of: "[/AI]", with: "")
                .replacingOccurrences(of: "[USER]", with: "")
                .replacingOccurrences(of: "[/USER]", with: "")
                .trimmingCharacters(in: .whitespaces)
            Text(cleaned)
                .font(.system(size: 14, weight: isAI ? .regular : .medium))
                .foregroundStyle(isAI ? Theme.textSecondary : Theme.textPrimary)
        }
    }

    private func bulletLine(_ text: String, isAI: Bool, indent: Int) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(indent == 0 ? "•" : "○")
                .font(.system(size: indent == 0 ? 14 : 12))
                .foregroundStyle(Theme.textMuted)
            Text(text
                .replacingOccurrences(of: "[AI]", with: "")
                .replacingOccurrences(of: "[/AI]", with: "")
                .replacingOccurrences(of: "[USER]", with: "")
                .replacingOccurrences(of: "[/USER]", with: ""))
                .font(.system(size: 14))
                .foregroundStyle(isAI ? Theme.textSecondary : Theme.textPrimary)
        }
        .padding(.leading, CGFloat(indent) * 20)
    }

    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(Theme.divider)
            HStack(spacing: 12) {
                if !isActiveRecording && meeting.meetingStatus == .completed && meeting.enhancedNotes == nil {
                    Button {
                        isEnhancing = true
                        Task {
                            await sessionManager.enhanceNotes(meeting: meeting, modelContext: modelContext)
                            isEnhancing = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if isEnhancing {
                                ProgressView().controlSize(.small)
                            } else {
                                Image(systemName: "sparkles").font(.system(size: 12))
                            }
                            Text(isEnhancing ? "Enhancing..." : "Enhance Notes")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Theme.accentGreen)
                        .cornerRadius(Theme.radiusPill)
                    }
                    .buttonStyle(.plain)
                    .disabled(isEnhancing)
                }

                if isActiveRecording {
                    Button {
                        Task { await sessionManager.stopRecording(modelContext: modelContext) }
                    } label: {
                        HStack(spacing: 6) {
                            Circle().fill(.red).frame(width: 8, height: 8)
                            Text("Stop recording").font(.system(size: 13, weight: .medium))
                        }
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.15))
                        .cornerRadius(Theme.radiusPill)
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    TextField("Ask anything", text: $chatInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textPrimary)
                        .onSubmit {
                            if !chatInput.isEmpty {
                                withAnimation { showChatSidebar = true }
                                sendChatMessage()
                            }
                        }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusPill)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusPill).stroke(Theme.border, lineWidth: 1))

                Button { } label: {
                    HStack(spacing: 4) {
                        Text("/").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.accentGreen)
                        Text("Write follow up email").font(.system(size: 12)).foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusPill)
                }
                .buttonStyle(.plain)

                if let error = sessionManager.error {
                    Text(error).font(.system(size: 11)).foregroundStyle(.red).lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.bgPrimary)
        }
    }

    // MARK: - Chat Sidebar (CMD+J)
    private var chatSidebar: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Ask about this meeting")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Button { withAnimation { showChatSidebar = false } } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
            .padding(12)

            Divider().background(Theme.divider)

            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if chatMessages.isEmpty {
                        Text("Ask anything about this meeting.\nTry: \"What were the action items?\"")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textMuted)
                            .padding(12)
                    }

                    ForEach(Array(chatMessages.enumerated()), id: \.offset) { _, msg in
                        VStack(alignment: msg.role == "user" ? .trailing : .leading, spacing: 4) {
                            Text(msg.content)
                                .font(.system(size: 13))
                                .foregroundStyle(msg.role == "user" ? Theme.textPrimary : Theme.textSecondary)
                                .padding(10)
                                .background(msg.role == "user" ? Theme.bgCard : Theme.bgCard.opacity(0.5))
                                .cornerRadius(Theme.radiusMD)
                                .textSelection(.enabled)
                        }
                        .frame(maxWidth: .infinity, alignment: msg.role == "user" ? .trailing : .leading)
                    }

                    if chatService.isLoading {
                        HStack(spacing: 6) {
                            ProgressView().controlSize(.small)
                            Text("Thinking...").font(.system(size: 12)).foregroundStyle(Theme.textMuted)
                        }
                        .padding(10)
                    }
                }
                .padding(12)
            }

            Divider().background(Theme.divider)

            // Input
            HStack(spacing: 8) {
                TextField("Ask about this meeting...", text: $chatInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { sendChatMessage() }

                Button { sendChatMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(chatInput.isEmpty ? Theme.textMuted : Theme.accentGreen)
                }
                .buttonStyle(.plain)
                .disabled(chatInput.isEmpty)
            }
            .padding(12)
        }
        .background(Theme.bgPrimary)
    }

    // MARK: - Actions
    private func sendChatMessage() {
        guard !chatInput.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let question = chatInput
        chatInput = ""
        chatMessages.append((role: "user", content: question))

        Task {
            let response = await chatService.askAboutMeeting(question, meeting: meeting)
            chatMessages.append((role: "assistant", content: response))
        }
    }

    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
