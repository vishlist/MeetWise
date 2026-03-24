import ScreenCaptureKit
import AVFoundation
import Combine
import Foundation

@Observable
final class AudioCaptureService {
    var isCapturing = false
    var audioLevel: Float = 0.0

    private var screenCaptureStream: SCStream?
    private var audioEngine: AVAudioEngine?
    private var audioStreamOutput: AudioStreamOutput?

    // Callback to send audio data to TranscriptionService
    var onAudioData: ((Data) -> Void)?

    // Also collect raw audio for saving to file
    private var rawAudioData = Data()
    private let audioQueue = DispatchQueue(label: "com.meetwise.audio")

    func startCapture() async throws {
        // 1. Request Screen Recording permission
        let content = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: false
        )

        // 2. Configure audio-only capture
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = false
        config.sampleRate = 16000       // Deepgram expects 16kHz
        config.channelCount = 1         // mono

        // Minimal video (required by ScreenCaptureKit even for audio-only)
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        config.width = 2
        config.height = 2

        // 3. Create filter for all audio from primary display
        guard let display = content.displays.first else {
            throw AudioCaptureError.noDisplayFound
        }
        let filter = SCContentFilter(display: display, excludingWindows: [])

        // 4. Create and start the stream
        let stream = SCStream(filter: filter, configuration: config, delegate: nil)

        let output = AudioStreamOutput { [weak self] data in
            self?.audioQueue.async {
                self?.onAudioData?(data)
                self?.rawAudioData.append(data)
                self?.updateAudioLevel(from: data)
            }
        }
        self.audioStreamOutput = output

        try stream.addStreamOutput(
            output,
            type: .audio,
            sampleHandlerQueue: audioQueue
        )

        try await stream.startCapture()
        self.screenCaptureStream = stream

        // 5. Also start microphone capture
        try startMicrophoneCapture()

        await MainActor.run {
            isCapturing = true
        }
    }

    private func startMicrophoneCapture() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode

        // Get the native format first, then convert
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { [weak self] buffer, _ in
            // Convert to 16kHz mono Int16 for Deepgram
            guard let data = self?.convertBufferToLinear16(buffer) else { return }
            self?.audioQueue.async {
                self?.onAudioData?(data)
            }
        }

        try engine.start()
        self.audioEngine = engine
    }

    func stopCapture() async -> Data {
        if let stream = screenCaptureStream {
            try? await stream.stopCapture()
        }
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)

        screenCaptureStream = nil
        audioEngine = nil
        audioStreamOutput = nil

        await MainActor.run {
            isCapturing = false
        }

        let data = rawAudioData
        rawAudioData = Data()
        return data
    }

    private func convertBufferToLinear16(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let floatData = buffer.floatChannelData else { return nil }
        let frameCount = Int(buffer.frameLength)

        var int16Data = Data(count: frameCount * 2)
        int16Data.withUnsafeMutableBytes { rawBuffer in
            guard let ptr = rawBuffer.bindMemory(to: Int16.self).baseAddress else { return }
            for i in 0..<frameCount {
                let sample = floatData[0][i]
                let clamped = max(-1.0, min(1.0, sample))
                ptr[i] = Int16(clamped * Float(Int16.max))
            }
        }
        return int16Data
    }

    private func updateAudioLevel(from data: Data) {
        // Calculate RMS for waveform visualization
        guard data.count >= 2 else { return }
        let samples = data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Int16.self))
        }
        let rms = sqrt(samples.map { Float($0) * Float($0) }.reduce(0, +) / Float(samples.count))
        let normalized = min(1.0, rms / Float(Int16.max) * 4.0) // amplify for visibility
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = normalized
        }
    }
}

// SCStreamOutput handler for system audio
class AudioStreamOutput: NSObject, SCStreamOutput {
    let onAudioData: (Data) -> Void

    init(onAudioData: @escaping (Data) -> Void) {
        self.onAudioData = onAudioData
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }

        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }
        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        CMBlockBufferGetDataPointer(blockBuffer, atOffset: 0, lengthAtOffsetOut: nil, totalLengthOut: &length, dataPointerOut: &dataPointer)

        guard let pointer = dataPointer, length > 0 else { return }
        let data = Data(bytes: pointer, count: length)
        onAudioData(data)
    }
}

enum AudioCaptureError: Error, LocalizedError {
    case noDisplayFound
    case permissionDenied
    case captureFailure(String)

    var errorDescription: String? {
        switch self {
        case .noDisplayFound: return "No display found for audio capture"
        case .permissionDenied: return "Screen Recording permission denied"
        case .captureFailure(let msg): return "Capture failed: \(msg)"
        }
    }
}
