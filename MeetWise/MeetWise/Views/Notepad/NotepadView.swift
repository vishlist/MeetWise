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

    init(meeting: Meeting, sessionManager: MeetingSessionManager) {
        self.meeting = meeting
        self.sessionManager = sessionManager
        self._userNotes = State(initialValue: meeting.userNotes)
    }

    private var isActiveRecording: Bool {
        sessionManager.isRecording && sessionManager.currentMeeting?.id == meeting.id
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top navigation bar
            topBar

            Divider().background(Theme.divider)

            // Main content area
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Meeting title
                        meetingHeader
                            .padding(.horizontal, 48)
                            .padding(.top, 32)

                        // Metadata pills
                        metadataPills
                            .padding(.horizontal, 48)
                            .padding(.top, 12)

                        // Content: either enhanced notes or user notepad
                        if let enhanced = meeting.enhancedNotes, !enhanced.isEmpty {
                            enhancedContent(enhanced)
                                .padding(.horizontal, 48)
                                .padding(.top, 24)
                        } else {
                            // Blank notepad — user types here during AND after meeting
                            // Granola: transcript is INVISIBLE during meeting
                            noteEditor
                                .padding(.horizontal, 44)
                                .padding(.top, 16)
                        }

                        Spacer(minLength: 80)
                    }
                }

                // Bottom bar with Enhance + Ask anything + recipe
                bottomBar
            }
        }
        .background(Theme.bgPrimary)
        .onChange(of: userNotes) { _, newValue in
            meeting.userNotes = newValue
            try? modelContext.save()
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
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

            Spacer()

            // Recording indicator (subtle, top bar only)
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

            // Share button
            Button { } label: {
                HStack(spacing: 4) {
                    Image(systemName: "lock")
                        .font(.system(size: 11))
                    Text("Share")
                        .font(.system(size: 13))
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusSM)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Link button
            Button { } label: {
                Image(systemName: "link")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(6)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
            }
            .buttonStyle(.plain)

            // More menu
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

            Button { } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 10))
                    Text("Add to folder")
                        .font(.system(size: 12))
                }
                .foregroundStyle(Theme.textSecondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusPill)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusPill)
                        .stroke(Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private func metadataPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
            Text(text)
                .font(.system(size: 12))
        }
        .foregroundStyle(Theme.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusPill)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusPill)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    // MARK: - Note Editor (blank notepad — Granola style)
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

    // MARK: - Enhanced Content (black = user, gray = AI)
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
            // Section heading
            HStack(spacing: 6) {
                Text("#")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textMuted)
                Text(String(trimmed.dropFirst(2)))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
            }
            .padding(.top, 12)
        } else if trimmed.hasPrefix("## ") {
            HStack(spacing: 6) {
                Text("#")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textMuted)
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
            // Plain text — check for AI/USER markers
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

    // MARK: - Bottom Bar (Enhance + Ask + Recipe)
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(Theme.divider)

            HStack(spacing: 12) {
                // Enhance Notes button (show when meeting is done and not yet enhanced)
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
                                ProgressView()
                                    .controlSize(.small)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 12))
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

                // Stop recording button (during recording)
                if isActiveRecording {
                    Button {
                        Task {
                            await sessionManager.stopRecording(modelContext: modelContext)
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle().fill(.red).frame(width: 8, height: 8)
                            Text("Stop recording")
                                .font(.system(size: 13, weight: .medium))
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
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusPill)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusPill)
                        .stroke(Theme.border, lineWidth: 1)
                )

                // Recipe pill
                Button { } label: {
                    HStack(spacing: 4) {
                        Text("/")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.accentGreen)
                        Text("Write follow up email")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusPill)
                }
                .buttonStyle(.plain)

                // Error message
                if let error = sessionManager.error {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Theme.bgPrimary)
        }
    }

    // MARK: - Helpers
    private func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
}
