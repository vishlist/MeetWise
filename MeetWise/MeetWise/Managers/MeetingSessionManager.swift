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
    }

    func startRecording(modelContext: ModelContext) async {
        guard !isRecording else { return }

        error = nil
        liveTranscriptText = ""
        liveTranscriptSegments = []
        interimText = ""

        // Create meeting
        let meeting = Meeting(title: "New Meeting", startedAt: Date())
        modelContext.insert(meeting)
        try? modelContext.save()
        currentMeeting = meeting

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

        // Wire audio data → Deepgram
        audio.onAudioData = { [weak transcription] data in
            transcription?.sendAudioData(data)
        }

        // Handle final transcript
        transcription.onFinalTranscript = { [weak self] segment in
            Task { @MainActor in
                guard let self else { return }
                let speaker = segment.speaker ?? "Speaker"
                let line = "\(speaker): \(segment.text)\n"
                self.liveTranscriptText += line
                self.liveTranscriptSegments.append(TranscriptSegmentData(speaker: speaker, text: segment.text))
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
    func enhanceNotes(meeting: Meeting, modelContext: ModelContext) async {
        guard let transcript = meeting.transcriptRaw, !transcript.isEmpty else {
            error = "No transcript available to enhance notes"
            return
        }

        do {
            let result = try await enhancementService.enhanceNotes(
                userNotes: meeting.userNotes,
                transcript: transcript,
                attendees: meeting.participants?.map { $0.name } ?? [],
                meetingTitle: meeting.title
            )

            meeting.enhancedNotes = result.content
            meeting.summaryJSON = try? JSONEncoder().encode(result.summary)
            meeting.title = result.summary.title
            try? modelContext.save()
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
