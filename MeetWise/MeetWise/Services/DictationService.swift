import Foundation
import AVFoundation

/// Microphone dictation service — streams mic audio to Deepgram for real-time
/// voice-to-text. This is separate from meeting recording (AudioCaptureService);
/// it only captures the mic for note dictation.
@MainActor @Observable
final class DictationService {
    // MARK: - Public state
    var isDictating = false
    var currentText = ""       // interim (not-yet-final) text
    var audioLevel: Float = 0.0
    var error: String?

    /// Called on the main actor every time a final transcript arrives.
    var onFinalTranscript: ((String) -> Void)?

    // MARK: - Private
    private var audioEngine: AVAudioEngine?
    private var webSocket: URLSessionWebSocketTask?
    private let audioQueue = DispatchQueue(label: "com.meetwise.dictation.audio")

    // MARK: - Start / Stop

    func startDictation() {
        guard !isDictating else { return }
        error = nil
        currentText = ""

        let apiKey = Constants.deepgramAPIKey
        guard !apiKey.isEmpty else {
            error = "Deepgram API key not configured."
            return
        }

        // 1. Connect WebSocket
        connectWebSocket(apiKey: apiKey)

        // 2. Start mic capture
        do {
            try startMicCapture()
        } catch {
            self.error = "Mic capture failed: \(error.localizedDescription)"
            disconnectWebSocket()
            return
        }

        isDictating = true
    }

    func stopDictation() {
        guard isDictating else { return }
        isDictating = false

        // Stop mic
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil

        // Close WebSocket gracefully
        disconnectWebSocket()

        currentText = ""
        audioLevel = 0
    }

    // MARK: - WebSocket

    private func connectWebSocket(apiKey: String) {
        let params = [
            "model=nova-2",
            "language=en",
            "smart_format=true",
            "punctuate=true",
            "interim_results=true",
            "endpointing=300",
            "encoding=linear16",
            "sample_rate=16000",
            "channels=1"
        ].joined(separator: "&")

        guard let url = URL(string: "\(Constants.deepgramWSURL)?\(params)") else { return }

        var request = URLRequest(url: url)
        request.setValue("Token \(apiKey)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        let task = session.webSocketTask(with: request)
        task.resume()
        self.webSocket = task

        receiveMessages()
    }

    private func disconnectWebSocket() {
        let close = "{\"type\": \"CloseStream\"}"
        webSocket?.send(.string(close)) { _ in }
        webSocket?.cancel(with: .normalClosure, reason: nil)
        webSocket = nil
    }

    private func receiveMessages() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    self?.handleMessage(text)
                }
                self?.receiveMessages()
            case .failure(let err):
                print("[Dictation] WS receive error: \(err)")
            }
        }
    }

    private func handleMessage(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else { return }
        do {
            let response = try JSONDecoder().decode(DeepgramResponse.self, from: data)
            guard response.type == "Results",
                  let alt = response.channel?.alternatives?.first,
                  !alt.transcript.trimmingCharacters(in: .whitespaces).isEmpty
            else { return }

            let isFinal = response.isFinal ?? false
            let text = alt.transcript

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if isFinal {
                    self.currentText = ""
                    self.onFinalTranscript?(text)
                } else {
                    self.currentText = text
                }
            }
        } catch {
            print("[Dictation] Parse error: \(error)")
        }
    }

    // MARK: - Mic capture (AVAudioEngine -> Linear16 PCM @ 16 kHz)

    private func startMicCapture() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        guard nativeFormat.sampleRate > 0 else {
            throw DictationError.noMicrophone
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { [weak self] buffer, _ in
            guard let self, let data = self.convertToLinear16(buffer) else { return }
            self.audioQueue.async {
                self.webSocket?.send(.data(data)) { err in
                    if let err { print("[Dictation] Send error: \(err)") }
                }
                self.updateAudioLevel(from: data)
            }
        }

        try engine.start()
        self.audioEngine = engine
    }

    private func convertToLinear16(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let floatData = buffer.floatChannelData else { return nil }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return nil }

        let nativeRate = buffer.format.sampleRate
        let targetRate: Double = 16000

        if abs(nativeRate - targetRate) < 1 {
            var out = Data(count: frameCount * 2)
            out.withUnsafeMutableBytes { raw in
                guard let ptr = raw.bindMemory(to: Int16.self).baseAddress else { return }
                for i in 0..<frameCount {
                    let s = max(-1.0, min(1.0, floatData[0][i]))
                    ptr[i] = Int16(s * Float(Int16.max))
                }
            }
            return out
        } else {
            let ratio = nativeRate / targetRate
            let outputCount = Int(Double(frameCount) / ratio)
            guard outputCount > 0 else { return nil }
            var out = Data(count: outputCount * 2)
            out.withUnsafeMutableBytes { raw in
                guard let ptr = raw.bindMemory(to: Int16.self).baseAddress else { return }
                for i in 0..<outputCount {
                    let src = min(Int(Double(i) * ratio), frameCount - 1)
                    let s = max(-1.0, min(1.0, floatData[0][src]))
                    ptr[i] = Int16(s * Float(Int16.max))
                }
            }
            return out
        }
    }

    private func updateAudioLevel(from data: Data) {
        guard data.count >= 2 else { return }
        let samples = data.withUnsafeBytes { Array($0.bindMemory(to: Int16.self)) }
        guard !samples.isEmpty else { return }
        let rms = sqrt(samples.map { Float($0) * Float($0) }.reduce(0, +) / Float(samples.count))
        let normalized = min(1.0, rms / Float(Int16.max) * 4.0)
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = normalized
        }
    }
}

// MARK: - Errors
enum DictationError: Error, LocalizedError {
    case noMicrophone

    var errorDescription: String? {
        switch self {
        case .noMicrophone: return "No microphone available"
        }
    }
}
