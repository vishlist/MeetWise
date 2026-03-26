import SwiftUI
import SwiftData

// MARK: - Tab Enum for Summary/Transcript/Notes
enum NotepadTab: String, CaseIterable {
    case summary = "Summary"
    case transcript = "Transcript"
    case notes = "Notes"
}

// MARK: - Template Picker Enum
enum NoteTemplateChoice: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case blank = "Blank"
    case meetingNotes = "Meeting Notes"
    case oneOnOne = "1:1 Meeting"
    case standup = "Standup"
    case retrospective = "Retrospective"
    case clientCall = "Client Call"
    case brainstorm = "Brainstorm"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .auto: return "sparkles"
        case .blank: return "doc"
        case .meetingNotes: return "note.text"
        case .oneOnOne: return "person.2"
        case .standup: return "sunrise"
        case .retrospective: return "arrow.counterclockwise"
        case .clientCall: return "phone"
        case .brainstorm: return "lightbulb"
        }
    }
}

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
    @State private var selectedTemplate: NoteTemplateChoice = .auto
    @State private var chatMessages: [(role: String, content: String)] = []
    @State private var chatService = ChatService()
    @State private var copiedToClipboard = false
    @State private var selectedTab: NotepadTab = .notes
    @State private var showDeleteConfirm = false
    @State private var newAttendee = ""
    @State private var showAddAttendee = false

    init(meeting: Meeting, sessionManager: MeetingSessionManager) {
        self.meeting = meeting
        self.sessionManager = sessionManager
        self._userNotes = State(initialValue: meeting.userNotes)
        // Default to summary tab if enhanced
        if meeting.enhancedNotes != nil || meeting.summaryJSON != nil {
            self._selectedTab = State(initialValue: .summary)
        }
    }

    private var isActiveRecording: Bool {
        sessionManager.isRecording && sessionManager.currentMeeting?.id == meeting.id
    }

    var body: some View {
        HStack(spacing: 0) {
            mainContent

            if showChatSidebar {
                Divider().background(Theme.divider)
                chatSidebar
                    .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
                    .transition(.move(edge: .trailing))
            }
        }
        .background(Theme.bgPrimary)
        .onChange(of: userNotes) { _, newValue in
            meeting.userNotes = newValue
            try? modelContext.save()
        }
        .onChange(of: appState.showChatSidebar) { _, newValue in
            withAnimation(.easeInOut(duration: 0.2)) { showChatSidebar = newValue }
        }
        .onKeyPress(keys: [.init("j")], phases: .down) { press in
            if press.modifiers.contains(.command) {
                withAnimation(.easeInOut(duration: 0.2)) { showChatSidebar.toggle() }
                return .handled
            }
            return .ignored
        }
        .alert("Delete Meeting", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                modelContext.delete(meeting)
                try? modelContext.save()
                appState.selectedMeeting = nil
            }
        } message: {
            Text("Are you sure you want to delete this meeting? This cannot be undone.")
        }
    }

    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 0) {
            if isActiveRecording {
                recordingBanner
            }

            topBar
            Divider().background(Theme.divider)

            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Title
                        meetingHeader
                            .padding(.horizontal, 48)
                            .padding(.top, 24)

                        // Date + Attendee pills
                        metadataAndAttendees
                            .padding(.horizontal, 48)
                            .padding(.top, 12)

                        // Tab bar
                        tabBar
                            .padding(.horizontal, 48)
                            .padding(.top, 16)

                        // Tab content
                        switch selectedTab {
                        case .summary:
                            summaryTabContent
                                .padding(.horizontal, 48)
                                .padding(.top, 16)
                        case .transcript:
                            transcriptTabContent
                                .padding(.horizontal, 32)
                                .padding(.top, 16)
                        case .notes:
                            notesTabContent
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

    // MARK: - Recording Banner
    private var recordingBanner: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
                .shadow(color: .red.opacity(0.6), radius: 4)

            HStack(spacing: 2) {
                ForEach(0..<12, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.red.opacity(0.6))
                        .frame(width: 2, height: waveformHeight(index: i))
                }
            }

            Text("Recording")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.red)

            Text(sessionManager.formattedDuration)
                .font(.system(size: 12).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)

            Spacer()

            Button {
                Task { await sessionManager.stopRecording(modelContext: modelContext) }
            } label: {
                Text("Stop")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.12))
                    .cornerRadius(Theme.radiusPill)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.06))
    }

    private func waveformHeight(index: Int) -> CGFloat {
        let base: CGFloat = 4
        let level = CGFloat(sessionManager.audioLevel)
        let variation = CGFloat(abs(sin(Double(index) * 0.8))) * level * 14
        return max(base, base + variation)
    }

    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(NotepadTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { selectedTab = tab }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: selectedTab == tab ? .semibold : .regular))
                        .foregroundStyle(selectedTab == tab ? Theme.textPrimary : Theme.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .overlay(alignment: .bottom) {
                            if selectedTab == tab {
                                Rectangle()
                                    .fill(Theme.textPrimary)
                                    .frame(height: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.border).frame(height: 1)
        }
    }

    // MARK: - Top Bar (Header)
    private var topBar: some View {
        HStack(spacing: 8) {
            // Back + Home
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
            .hoverScale(1.05)

            // Breadcrumb
            HStack(spacing: 4) {
                Text("Meetings")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
                Image(systemName: "chevron.right")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.textMuted)
                Text(meeting.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            // Enhanced badge
            if meeting.enhancedNotes != nil {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text("Enhanced")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
            }

            // Share
            Menu {
                Button {
                    ShareService.copyAsMarkdown(meeting: meeting)
                    showCopiedFeedback()
                } label: {
                    Label("Copy as Markdown", systemImage: "doc.richtext")
                }

                Button {
                    ShareService.copyAsPlainText(meeting: meeting)
                    showCopiedFeedback()
                } label: {
                    Label("Copy as Plain Text", systemImage: "doc.plaintext")
                }

                Divider()

                if meeting.transcriptRaw != nil {
                    Button {
                        if let url = ShareService.exportTranscript(meeting: meeting) {
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                    } label: {
                        Label("Export Transcript", systemImage: "square.and.arrow.up")
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12))
                    Text(copiedToClipboard ? "Copied!" : "Share")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
                .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Theme.border, lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // Link
            Button {
                let link = "meetwise://meeting/\(meeting.id.uuidString)"
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(link, forType: .string)
                showCopiedFeedback()
            } label: {
                Image(systemName: "link")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(6)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .hoverScale(1.05)

            // Chat sidebar toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showChatSidebar.toggle() }
            } label: {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 13))
                    .foregroundStyle(showChatSidebar ? Theme.accent : Theme.textSecondary)
                    .padding(6)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(
                        showChatSidebar ? Theme.accent.opacity(0.3) : Theme.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .hoverScale(1.05)

            // More menu
            Menu {
                Menu("Choose Template...") {
                    ForEach(NoteTemplateChoice.allCases) { template in
                        Button {
                            selectedTemplate = template
                            meeting.templateID = template.rawValue
                        } label: {
                            HStack {
                                Image(systemName: template.icon)
                                Text(template.rawValue)
                                if selectedTemplate == template {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }

                Divider()

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("Delete Meeting", systemImage: "trash")
                }

                Divider()

                Button {
                    ShareService.copyAsMarkdown(meeting: meeting)
                    showCopiedFeedback()
                } label: {
                    Label("Export as PDF", systemImage: "doc.fill")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(6)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusSM).stroke(Theme.border, lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
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

    // MARK: - Metadata + Attendees
    private var metadataAndAttendees: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Date pill
            HStack(spacing: 8) {
                metadataPill(icon: "calendar", text: formatDateFull(meeting.startedAt))

                if let platform = meeting.platform {
                    metadataPill(icon: "video", text: platform)
                }

                if let dur = meeting.durationSeconds, dur > 0 {
                    metadataPill(icon: "clock", text: meeting.formattedDuration)
                }
            }

            // Attendee pills
            HStack(spacing: 6) {
                let participants = meeting.participants ?? []
                ForEach(Array(participants.enumerated()), id: \.element.id) { index, participant in
                    AttendeePill(
                        name: participant.name,
                        color: Theme.attendeeColors[index % Theme.attendeeColors.count],
                        onRemove: {
                            modelContext.delete(participant)
                            try? modelContext.save()
                        }
                    )
                }

                if participants.isEmpty {
                    AttendeePill(name: "Me", color: Theme.textMuted)
                }

                // Add attendee button
                if showAddAttendee {
                    HStack(spacing: 4) {
                        TextField("Name", text: $newAttendee)
                            .textFieldStyle(.plain)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textPrimary)
                            .frame(width: 100)
                            .onSubmit { addAttendee() }
                            .onExitCommand {
                                showAddAttendee = false
                                newAttendee = ""
                            }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusPill)
                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusPill).stroke(Theme.border, lineWidth: 1))
                } else {
                    Button {
                        showAddAttendee = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                                .font(.system(size: 10))
                            Text("Add attendee")
                                .font(.system(size: 11))
                        }
                        .foregroundStyle(Theme.textMuted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Theme.bgCard)
                        .cornerRadius(Theme.radiusPill)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.radiusPill)
                                .stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    }
                    .buttonStyle(.plain)
                    .hoverScale(1.05)
                }
            }
        }
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

    // MARK: - Notes Tab
    private var notesTabContent: some View {
        Group {
            if let enhanced = meeting.enhancedNotes, !enhanced.isEmpty {
                enhancedContent(enhanced)
            } else {
                noteEditor
            }
        }
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

    // MARK: - Transcript Tab
    private var transcriptTabContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if sessionManager.liveTranscriptSegments.isEmpty && (meeting.transcriptRaw ?? "").isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "waveform")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.textMuted)
                    Text("No transcript yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Start recording to see real-time transcription")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else if isActiveRecording {
                ForEach(sessionManager.liveTranscriptSegments) { segment in
                    transcriptBubble(segment: segment)
                }

                if !sessionManager.interimText.isEmpty {
                    HStack {
                        Text(sessionManager.interimText)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textMuted)
                            .italic()
                            .padding(10)
                            .background(Theme.bgCard.opacity(0.3))
                            .cornerRadius(Theme.radiusMD)
                        Spacer()
                    }
                }
            } else {
                let lines = parseTranscriptLines(meeting.transcriptRaw ?? "")
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    savedTranscriptBubble(speaker: line.speaker, text: line.text, isUser: line.isUser)
                }
            }
        }
        .padding(.bottom, 16)
    }

    private func transcriptBubble(segment: MeetingSessionManager.TranscriptSegmentData) -> some View {
        let isUser = segment.isUser
        return HStack(alignment: .top, spacing: 8) {
            if !isUser { Spacer(minLength: 40) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(segment.speaker)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Theme.textMuted)
                    Text(formatTime(segment.timestamp))
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.textMuted)
                }

                Text(segment.text)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(10)
                    .background(isUser ? Theme.bgCard : Theme.bgCard.opacity(0.5))
                    .cornerRadius(Theme.radiusMD)
                    .textSelection(.enabled)
            }

            if isUser { Spacer(minLength: 40) }
        }
    }

    private func savedTranscriptBubble(speaker: String, text: String, isUser: Bool) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if isUser { Spacer(minLength: 40) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(speaker)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textMuted)

                Text(text)
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(10)
                    .background(isUser ? Theme.bgCard : Theme.bgCard.opacity(0.5))
                    .cornerRadius(Theme.radiusMD)
                    .textSelection(.enabled)
            }

            if !isUser { Spacer(minLength: 40) }
        }
    }

    // MARK: - Summary Tab (Collapsible Sections)
    private var summaryTabContent: some View {
        Group {
            if let summaryData = meeting.summaryJSON,
               let summary = try? JSONDecoder().decode(EnhancementService.MeetingSummary.self, from: summaryData) {
                VStack(alignment: .leading, spacing: 12) {
                    // Meeting Purpose
                    if !summary.overview.isEmpty {
                        CollapsibleSection(title: "Meeting Purpose", icon: "doc.text") {
                            Text(summary.overview)
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.textSecondary)
                                .lineSpacing(4)
                        }
                    }

                    // Key Takeaways
                    if !summary.keyPoints.isEmpty {
                        CollapsibleSection(title: "Key Takeaways", icon: "lightbulb") {
                            ForEach(summary.keyPoints, id: \.self) { point in
                                HStack(alignment: .top, spacing: 8) {
                                    Circle()
                                        .fill(Theme.textMuted)
                                        .frame(width: 5, height: 5)
                                        .padding(.top, 7)
                                    Text(point)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.bgPrimary.opacity(0.5))
                                .cornerRadius(Theme.radiusSM)
                            }
                        }
                    }

                    // Topics
                    if !summary.topics.isEmpty {
                        CollapsibleSection(title: "Topics", icon: "tag") {
                            FlowLayout(spacing: 6) {
                                ForEach(summary.topics, id: \.self) { topic in
                                    TagPill(text: topic)
                                }
                            }
                        }
                    }

                    // Action Items (Table-like)
                    if !summary.actionItems.isEmpty {
                        CollapsibleSection(title: "Action Items", icon: "checkmark.circle") {
                            VStack(spacing: 2) {
                                // Header row
                                HStack(spacing: 0) {
                                    Text("Task")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    Text("Assignee")
                                        .frame(width: 120, alignment: .leading)
                                    Text("Deadline")
                                        .frame(width: 100, alignment: .leading)
                                }
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Theme.textMuted)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)

                                Rectangle().fill(Theme.border).frame(height: 1)

                                ForEach(summary.actionItems, id: \.task) { item in
                                    ActionItemRow(
                                        task: item.task,
                                        assignee: item.assignee,
                                        deadline: item.deadline
                                    )
                                }
                            }
                        }
                    }

                    // Decisions Made
                    if !summary.decisions.isEmpty {
                        CollapsibleSection(title: "Decisions Made", icon: "checkmark.seal") {
                            ForEach(summary.decisions, id: \.self) { decision in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(Theme.textMuted)
                                        .padding(.top, 3)
                                    Text(decision)
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.textPrimary)
                                }
                            }
                        }
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.textMuted)
                    Text("No summary available")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Enhance your notes to generate a summary")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            }
        }
    }

    // MARK: - Enhanced Content (Markdown-like rendering)
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
        } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
            bulletLine(String(trimmed.dropFirst(2)), isAI: line.contains("[AI]"), indent: 0)
        } else if trimmed.hasPrefix("  - ") || trimmed.hasPrefix("  * ") {
            bulletLine(String(trimmed.dropFirst(4)), isAI: line.contains("[AI]"), indent: 1)
        } else if trimmed.hasPrefix("    - ") || trimmed.hasPrefix("    * ") {
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
            Text(indent == 0 ? "*" : "-")
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
                // Enhance button
                if !isActiveRecording && meeting.enhancedNotes == nil {
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
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white)
                        .cornerRadius(Theme.radiusPill)
                    }
                    .buttonStyle(.plain)
                    .disabled(isEnhancing)
                    .hoverScale(1.03)
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

                // Ask anything input
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

                // Recipe pill
                Button {
                    chatInput = "Write follow up email"
                    withAnimation { showChatSidebar = true }
                    sendChatMessage()
                } label: {
                    HStack(spacing: 4) {
                        Text("/").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.accent)
                        Text("Write follow up email").font(.system(size: 12)).foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusPill)
                }
                .buttonStyle(.plain)
                .hoverScale(1.03)

                if let error = sessionManager.error {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.accentRed)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.bgPrimary)
        }
    }

    // MARK: - Chat Sidebar
    private var chatSidebar: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                // Bot avatar
                Circle()
                    .fill(Color(hex: "#333333"))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Text("MW")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    )

                Text("Ask about this meeting")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("J")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Theme.bgCard)
                    .cornerRadius(4)
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
                        sidebarChatBubble(role: msg.role, content: msg.content)
                    }

                    if chatService.isLoading {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: "#333333"))
                                .frame(width: 22, height: 22)
                                .overlay(
                                    Text("MW")
                                        .font(.system(size: 7, weight: .bold))
                                        .foregroundStyle(Theme.textPrimary)
                                )
                            TypingIndicator()
                        }
                        .padding(10)
                    }
                }
                .padding(12)
            }

            // Suggested actions
            if chatMessages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(["List action items", "Show pending tasks", "When is the next meeting?"], id: \.self) { prompt in
                            Button {
                                chatInput = prompt
                                sendChatMessage()
                            } label: {
                                Text(prompt)
                                    .font(.system(size: 11))
                                    .foregroundStyle(Theme.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Theme.bgCard)
                                    .cornerRadius(Theme.radiusPill)
                                    .overlay(RoundedRectangle(cornerRadius: Theme.radiusPill).stroke(Theme.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .hoverScale(1.03)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 8)
                }
            }

            Divider().background(Theme.divider)

            // Input
            HStack(spacing: 8) {
                TextField("Ask me anything...", text: $chatInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { sendChatMessage() }

                Button { sendChatMessage() } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(chatInput.isEmpty ? Theme.textMuted : Theme.accent)
                }
                .buttonStyle(.plain)
                .disabled(chatInput.isEmpty)
            }
            .padding(12)
        }
        .background(Theme.bgPrimary)
    }

    private func sidebarChatBubble(role: String, content: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            if role == "assistant" {
                Circle()
                    .fill(Color(hex: "#333333"))
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text("MW")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                    )
            }

            Text(content)
                .font(.system(size: 13))
                .foregroundStyle(role == "user" ? Theme.textPrimary : Theme.textSecondary)
                .padding(10)
                .background(role == "user" ? Theme.bgCard : Color(hex: "#1a1a1a"))
                .cornerRadius(Theme.radiusMD)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: role == "user" ? .trailing : .leading)

            if role == "user" {
                Circle()
                    .fill(Theme.textMuted)
                    .frame(width: 22, height: 22)
                    .overlay(
                        Text(appState.currentUser?.initials ?? "U")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(Theme.bgPrimary)
                    )
            }
        }
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

    private func addAttendee() {
        let trimmed = newAttendee.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            showAddAttendee = false
            return
        }
        let participant = MeetingParticipant(name: trimmed)
        participant.meeting = meeting
        modelContext.insert(participant)
        try? modelContext.save()
        newAttendee = ""
        showAddAttendee = false
    }

    private func showCopiedFeedback() {
        copiedToClipboard = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copiedToClipboard = false }
    }

    private func formatDateFull(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mm a"
        return f.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm:ss a"
        return f.string(from: date)
    }

    // MARK: - Transcript Parsing
    private struct TranscriptLine {
        let speaker: String
        let text: String
        let isUser: Bool
    }

    private func parseTranscriptLines(_ raw: String) -> [TranscriptLine] {
        let lines = raw.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return lines.compactMap { line in
            if let colonRange = line.range(of: ": ") {
                let speaker = String(line[line.startIndex..<colonRange.lowerBound])
                let text = String(line[colonRange.upperBound...])
                let isUser = speaker.lowercased().contains("you") || speaker == "Speaker 0"
                return TranscriptLine(speaker: speaker, text: text, isUser: isUser)
            }
            return TranscriptLine(speaker: "Speaker", text: line, isUser: false)
        }
    }
}
