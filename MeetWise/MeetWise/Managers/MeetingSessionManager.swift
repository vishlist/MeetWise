import SwiftUI
import SwiftData
import Foundation

@MainActor @Observable
final class MeetingSessionManager {
    // Public state
    var isRecording = false
    var recordingDuration: TimeInterval = 0
    var currentMeeting: Meeting?
    var liveTranscriptText = ""
    var liveTranscriptSegments: [TranscriptSegmentData] = []
    var interimText = ""
    var audioLevel: Float = 0.0
    var error: String?

    // Issue 4: Speaker name mapping for current session
    var speakerNames: [String: String] = [:]

    // Services (private)
    private var audioService: AudioCaptureService?
    private var transcriptionService: TranscriptionService?
    private let enhancementService = EnhancementService()
    private var timer: Timer?
    private var recordingStartTime: Date?

    struct TranscriptSegmentData: Identifiable {
        let id = UUID()
        let speaker: String
        let text: String
        let timestamp: Date
        let isUser: Bool

        init(speaker: String, text: String, timestamp: Date = Date(), isUser: Bool = false) {
            self.speaker = speaker
            self.text = text
            self.timestamp = timestamp
            self.isUser = isUser
        }
    }

    // MARK: - Meeting Detection Integration

    /// Called when MeetingDetectionService detects a meeting window.
    /// Auto-creates a Meeting and optionally starts recording.
    func handleMeetingDetected(
        _ detected: MeetingDetectionService.DetectedMeeting,
        autoRecord: Bool,
        modelContext: ModelContext
    ) async {
        // Don't create a new meeting if we're already recording
        guard !isRecording else { return }

        if autoRecord {
            await startRecording(modelContext: modelContext, title: detected.windowTitle, platform: detected.platform.rawValue)
        }
    }

    /// Called when MeetingDetectionService detects that the meeting has ended.
    func handleMeetingEnded(modelContext: ModelContext) async {
        guard isRecording else { return }
        await stopRecording(modelContext: modelContext)
    }

    // MARK: - Quick Note (no recording) — Issue 9 & 10

    /// Creates a meeting without starting audio recording — just a notepad.
    /// Pass a folder to create the meeting inside that folder.
    func startQuickNote(modelContext: ModelContext, in folder: Folder? = nil) -> Meeting {
        let meeting = Meeting(title: "Quick Note", startedAt: Date())
        meeting.status = "completed"
        meeting.isDraft = true  // Issue 9: Mark as draft until content is added
        meeting.folder = folder // Issue 10: Assign to folder if provided
        modelContext.insert(meeting)
        // Ensure bidirectional relationship is established
        if let folder = folder {
            if folder.meetings == nil {
                folder.meetings = [meeting]
            } else {
                folder.meetings?.append(meeting)
            }
        }
        try? modelContext.save()
        return meeting
    }

    /// Issue 9: Clean up empty meetings (drafts with no content)
    func cleanupEmptyMeeting(_ meeting: Meeting, modelContext: ModelContext) {
        if !meeting.hasContent && meeting.isDraft {
            modelContext.delete(meeting)
            try? modelContext.save()
        }
    }

    // MARK: - Recording

    func startRecording(modelContext: ModelContext, title: String? = nil, platform: String? = nil, appState: AppState? = nil) async {
        guard !isRecording else { return }

        // Issue 3: Check meeting limit
        if let appState = appState, !appState.checkMeetingLimit() {
            let used = appState.currentUser?.meetingsThisMonth ?? 0
            appState.showUpgrade("You've used \(used)/\(UserProfile.freeMeetingLimit) free meetings this month. Upgrade to Pro for unlimited.")
            return
        }

        error = nil
        liveTranscriptText = ""
        liveTranscriptSegments = []
        interimText = ""
        speakerNames = [:]

        // Create meeting
        let meeting = Meeting(title: title ?? "New Meeting", startedAt: Date())
        meeting.platform = platform
        modelContext.insert(meeting)
        try? modelContext.save()
        currentMeeting = meeting

        // Issue 3: Increment meeting count
        appState?.incrementMeetingCount()

        // Validate API key
        let apiKey = Constants.deepgramAPIKey
        guard !apiKey.isEmpty else {
            error = "Deepgram API key not configured. Set it in Settings."
            return
        }

        // Create services fresh each time
        let audio = AudioCaptureService()
        let transcription = TranscriptionService()
        self.audioService = audio
        self.transcriptionService = transcription

        // Wire audio data -> Deepgram
        audio.onAudioData = { [weak transcription] data in
            transcription?.sendAudioData(data)
        }

        // Handle final transcript — Issue 4: Map speaker names
        transcription.onFinalTranscript = { [weak self] segment in
            Task { @MainActor in
                guard let self else { return }
                let rawSpeaker = segment.speaker ?? "Speaker"
                // Issue 4: Use mapped name if available, otherwise fallback to letter-based names
                let displaySpeaker = self.speakerNames[rawSpeaker] ?? self.letterBasedSpeaker(rawSpeaker)
                let line = "\(rawSpeaker): \(segment.text)\n"
                self.liveTranscriptText += line
                self.liveTranscriptSegments.append(
                    TranscriptSegmentData(
                        speaker: displaySpeaker,
                        text: segment.text,
                        isUser: rawSpeaker.lowercased().contains("you") || rawSpeaker == "Speaker 0"
                    )
                )
                self.interimText = ""
            }
        }

        // Handle interim transcript
        transcription.onTranscriptUpdate = { [weak self] segment in
            Task { @MainActor in
                self?.interimText = segment.text
            }
        }

        // Connect Deepgram
        transcription.connect(apiKey: apiKey)

        // Start audio capture
        do {
            try await audio.startCapture()
            // Show capture mode info
            if audio.captureMode == .micOnly {
                self.error = "Mic-only mode (system audio unavailable). Grant Screen Recording permission for full capture."
            }
        } catch {
            self.error = "Audio capture failed: \(error.localizedDescription)"
            transcription.disconnect()
            self.audioService = nil
            self.transcriptionService = nil
            return
        }

        // Start timer
        recordingStartTime = Date()
        isRecording = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.recordingStartTime else { return }
                self.recordingDuration = Date().timeIntervalSince(start)
                self.audioLevel = self.audioService?.audioLevel ?? 0
            }
        }
    }

    /// Issue 4: Convert "Speaker 0" to "Speaker A", "Speaker 1" to "Speaker B" etc.
    private func letterBasedSpeaker(_ raw: String) -> String {
        if raw.hasPrefix("Speaker "), let numStr = raw.split(separator: " ").last, let num = Int(numStr) {
            let letter = String(UnicodeScalar(65 + (num % 26))!)
            return "Speaker \(letter)"
        }
        return raw
    }

    /// Issue 4: Set speaker names from calendar attendees
    func setSpeakerNamesFromAttendees(_ attendees: [String]) {
        for (index, name) in attendees.enumerated() {
            speakerNames["Speaker \(index)"] = name
        }
        // Store in meeting
        currentMeeting?.speakerNameMap = speakerNames
    }

    func stopRecording(modelContext: ModelContext) async {
        guard isRecording else { return }

        // Stop timer
        timer?.invalidate()
        timer = nil
        isRecording = false

        // Stop audio capture
        if let audio = audioService {
            let _ = await audio.stopCapture()
        }

        // Disconnect Deepgram
        transcriptionService?.disconnect()

        // Capture transcript before clearing services
        let transcriptText = liveTranscriptText

        // Clean up services
        audioService = nil
        transcriptionService = nil

        // Update meeting with transcript
        guard let meeting = currentMeeting else { return }
        let duration = Int(Date().timeIntervalSince(meeting.startedAt))

        meeting.status = "processing"
        meeting.endedAt = Date()
        meeting.durationSeconds = duration
        meeting.transcriptRaw = transcriptText
        meeting.speakerNameMap = speakerNames
        try? modelContext.save()

        // Generate AI summary if we have transcript
        if !transcriptText.isEmpty {
            do {
                let summary = try await enhancementService.generateSummary(
                    transcript: transcriptText,
                    meetingTitle: meeting.title
                )
                meeting.title = summary.title
                meeting.summaryJSON = try? JSONEncoder().encode(summary)
                meeting.status = "completed"
                try? modelContext.save()
            } catch {
                meeting.status = "completed"
                try? modelContext.save()
                print("[MeetWise] Summary generation failed: \(error)")
            }
        } else {
            meeting.title = "Meeting - \(meeting.formattedDate)"
            meeting.status = "completed"
            try? modelContext.save()
        }

        currentMeeting = nil
    }

    /// Enhance user notes with transcript
    func enhanceNotes(meeting: Meeting, modelContext: ModelContext, appState: AppState? = nil) async {
        let transcript = meeting.transcriptRaw ?? ""
        let notes = meeting.userNotes

        // Need at least notes or transcript to enhance
        if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            error = "Type some notes or record a meeting first, then enhance."
            return
        }

        // Issue 3: Check enhancement limit
        if let appState = appState, !appState.checkEnhancementLimit() {
            let used = appState.currentUser?.enhancementsThisMonth ?? 0
            appState.showUpgrade("You've used \(used)/\(UserProfile.freeEnhancementLimit) free AI enhancements this month. Upgrade to Pro for unlimited.")
            return
        }

        do {
            let result = try await enhancementService.enhanceNotes(
                userNotes: notes,
                transcript: transcript,
                attendees: meeting.participants?.map { $0.name } ?? [],
                meetingTitle: meeting.title
            )

            meeting.enhancedNotes = result.content
            meeting.summaryJSON = try? JSONEncoder().encode(result.summary)
            if !result.summary.title.isEmpty {
                meeting.title = result.summary.title
            }
            try? modelContext.save()

            // Issue 3: Increment enhancement count
            appState?.incrementEnhancementCount()
        } catch {
            self.error = "Enhancement failed: \(error.localizedDescription)"
        }
    }

    var formattedDuration: String {
        let m = Int(recordingDuration) / 60
        let s = Int(recordingDuration) % 60
        return String(format: "%d:%02d", m, s)
    }
}
