import SwiftUI
import SwiftData

struct NotepadView: View {
    let meeting: Meeting
    @Environment(\.modelContext) private var modelContext
    @State private var sessionManager: MeetingSessionManager
    @State private var userNotes: String
    @State private var showTranscript = false

    init(meeting: Meeting, sessionManager: MeetingSessionManager) {
        self.meeting = meeting
        self._sessionManager = State(initialValue: sessionManager)
        self._userNotes = State(initialValue: meeting.userNotes)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            noteHeader

            Divider().background(Theme.divider)

            // Main content
            HStack(spacing: 0) {
                // Notes editor (left)
                notesEditor
                    .frame(maxWidth: .infinity)

                if showTranscript {
                    Divider().background(Theme.divider)

                    // Transcript panel (right)
                    transcriptPanel
                        .frame(width: 350)
                }
            }

            Divider().background(Theme.divider)

            // Bottom toolbar
            bottomToolbar
        }
        .background(Theme.bgPrimary)
        .onChange(of: userNotes) { _, newValue in
            meeting.userNotes = newValue
            try? modelContext.save()
        }
    }

    // MARK: - Header
    private var noteHeader: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(meeting.title)
                    .font(.heading(22))
                    .foregroundStyle(Theme.textHeading)
                HStack(spacing: 8) {
                    Text(meeting.formattedDate)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                    if let duration = meeting.durationSeconds {
                        Text("• \(duration / 60) min")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    statusBadge
                }
            }

            Spacer()

            // Recording indicator
            if sessionManager.isRecording && sessionManager.currentMeeting?.id == meeting.id {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text(sessionManager.formattedDuration)
                        .font(.system(size: 14).monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)

                    // Audio level indicator
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Float(i) / 5.0 < sessionManager.audioLevel ? Theme.accentGreen : Theme.bgCard)
                                .frame(width: 3, height: CGFloat(8 + i * 3))
                        }
                    }
                }
            }

            // Transcript toggle
            Button {
                withAnimation { showTranscript.toggle() }
            } label: {
                Image(systemName: "text.magnifyingglass")
                    .font(.system(size: 14))
                    .foregroundStyle(showTranscript ? Theme.accentGreen : Theme.textSecondary)
                    .padding(8)
                    .background(showTranscript ? Theme.bgCard : Color.clear)
                    .cornerRadius(Theme.radiusSM)
            }
            .buttonStyle(.plain)
            .help("Toggle transcript")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    private var statusBadge: some View {
        Text(meeting.status)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(statusColor.opacity(0.15))
            .cornerRadius(Theme.radiusPill)
    }

    private var statusColor: Color {
        switch meeting.meetingStatus {
        case .recording: return .red
        case .processing: return Theme.accentOrange
        case .completed: return Theme.accentGreen
        case .failed: return .red
        }
    }

    // MARK: - Notes Editor
    private var notesEditor: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let enhanced = meeting.enhancedNotes, !enhanced.isEmpty {
                // Show enhanced notes
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enhanced Notes")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Theme.accentGreen)

                        enhancedNotesContent(enhanced)
                    }
                    .padding(24)
                }
            } else {
                // User notes editor
                TextEditor(text: $userNotes)
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(24)
                    .overlay(alignment: .topLeading) {
                        if userNotes.isEmpty {
                            Text("Start taking notes... Type during the meeting and AI will enhance them afterward.")
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.textMuted)
                                .padding(24)
                                .allowsHitTesting(false)
                        }
                    }
            }
        }
    }

    private func enhancedNotesContent(_ content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Parse [USER] and [AI] markers
            let lines = content.components(separatedBy: "\n")
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                if line.contains("[AI]") {
                    let cleaned = line
                        .replacingOccurrences(of: "[AI]", with: "")
                        .replacingOccurrences(of: "[/AI]", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    Text(cleaned)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary) // AI text is gray
                } else if line.contains("[USER]") {
                    let cleaned = line
                        .replacingOccurrences(of: "[USER]", with: "")
                        .replacingOccurrences(of: "[/USER]", with: "")
                        .trimmingCharacters(in: .whitespaces)
                    Text(cleaned)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textPrimary) // User text is white/bright
                } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    Text(line)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
    }

    // MARK: - Transcript Panel
    private var transcriptPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transcript")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    // Live transcript
                    if sessionManager.isRecording {
                        ForEach(sessionManager.liveTranscriptSegments) { segment in
                            transcriptLine(speaker: segment.speaker, text: segment.text)
                        }
                        if !sessionManager.interimText.isEmpty {
                            transcriptLine(speaker: "...", text: sessionManager.interimText)
                                .opacity(0.6)
                        }
                    }
                    // Saved transcript
                    else if let raw = meeting.transcriptRaw, !raw.isEmpty {
                        Text(raw)
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                            .textSelection(.enabled)
                    } else {
                        Text("No transcript yet. Start recording to see live transcription.")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textMuted)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .background(Theme.bgCard.opacity(0.3))
    }

    private func transcriptLine(speaker: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(speaker)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Theme.accentGreen)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Bottom Toolbar
    private var bottomToolbar: some View {
        HStack(spacing: 16) {
            if sessionManager.isRecording && sessionManager.currentMeeting?.id == meeting.id {
                Button {
                    Task {
                        await sessionManager.stopRecording(modelContext: modelContext)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 10))
                        Text("Stop Recording")
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.red)
                    .cornerRadius(Theme.radiusPill)
                }
                .buttonStyle(.plain)
            } else if meeting.meetingStatus == .completed && meeting.enhancedNotes == nil {
                Button {
                    Task {
                        await sessionManager.enhanceNotes(meeting: meeting, modelContext: modelContext)
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("Enhance Notes")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.accentGreen)
                    .cornerRadius(Theme.radiusPill)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            if let error = sessionManager.error {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}
