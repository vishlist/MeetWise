import Foundation

@Observable
final class TranscriptionService {
    var isConnected = false
    var currentTranscript: [TranscriptSegment] = []

    private var webSocket: URLSessionWebSocketTask?

    // Callbacks
    var onTranscriptUpdate: ((TranscriptSegment) -> Void)?
    var onFinalTranscript: ((TranscriptSegment) -> Void)?

    struct TranscriptSegment: Codable, Identifiable {
        let id: UUID
        var text: String
        var speaker: String?
        var startTime: Double
        var endTime: Double
        var isFinal: Bool

        init(text: String, speaker: String? = nil, startTime: Double, endTime: Double, isFinal: Bool) {
            self.id = UUID()
            self.text = text
            self.speaker = speaker
            self.startTime = startTime
            self.endTime = endTime
            self.isFinal = isFinal
        }
    }

    func connect(apiKey: String) {
        let params = [
            "model=nova-2",
            "language=en",
            "smart_format=true",
            "punctuate=true",
            "diarize=true",
            "utterances=true",
            "interim_results=true",
            "endpointing=300",
            "encoding=linear16",
            "sample_rate=16000",
            "channels=1"
        ].joined(separator: "&")

        guard let url = URL(string: "wss://api.deepgram.com/v1/listen?\(params)") else { return }

        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: request)
        task.resume()

        self.webSocket = task
        self.isConnected = true

        receiveMessages()
    }

    func sendAudioData(_ data: Data) {
        guard let webSocket = webSocket, isConnected else { return }
        webSocket.send(.data(data)) { error in
            if let error = error {
                print("[Deepgram] Send error: \(error)")
            }
        }
    }

    private func receiveMessages() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    self?.handleTranscriptMessage(text)
                default:
                    break
                }
                self?.receiveMessages()

            case .failure(let error):
                print("[Deepgram] Receive error: \(error)")
                DispatchQueue.main.async {
                    self?.isConnected = false
                }
            }
        }
    }

    private func handleTranscriptMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }

        do {
            let response = try JSONDecoder().decode(DeepgramResponse.self, from: data)
            guard response.type == "Results",
                  let alternative = response.channel?.alternatives?.first,
                  !alternative.transcript.trimmingCharacters(in: .whitespaces).isEmpty
            else { return }

            let segment = TranscriptSegment(
                text: alternative.transcript,
                speaker: alternative.words?.first.map { "Speaker \($0.speaker ?? 0)" },
                startTime: alternative.words?.first?.start ?? 0,
                endTime: alternative.words?.last?.end ?? 0,
                isFinal: response.isFinal ?? false
            )

            DispatchQueue.main.async { [weak self] in
                if segment.isFinal {
                    self?.currentTranscript.append(segment)
                    self?.onFinalTranscript?(segment)
                } else {
                    self?.onTranscriptUpdate?(segment)
                }
            }
        } catch {
            print("[Deepgram] Parse error: \(error)")
        }
    }

    func disconnect() {
        let closeMessage = "{\"type\": \"CloseStream\"}"
        webSocket?.send(.string(closeMessage)) { _ in }
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
        isConnected = false
    }

    /// Get full transcript as plain text
    var fullTranscriptText: String {
        currentTranscript.map { segment in
            let speaker = segment.speaker ?? "Speaker"
            return "\(speaker): \(segment.text)"
        }.joined(separator: "\n")
    }

    func reset() {
        currentTranscript = []
    }
}

// MARK: - Deepgram Response Models
struct DeepgramResponse: Codable {
    let type: String?
    let channel: DeepgramChannel?
    let isFinal: Bool?

    enum CodingKeys: String, CodingKey {
        case type, channel
        case isFinal = "is_final"
    }
}

struct DeepgramChannel: Codable {
    let alternatives: [DeepgramAlternative]?
}

struct DeepgramAlternative: Codable {
    let transcript: String
    let words: [DeepgramWord]?
}

struct DeepgramWord: Codable {
    let word: String
    let start: Double
    let end: Double
    let speaker: Int?
    let confidence: Double
}
