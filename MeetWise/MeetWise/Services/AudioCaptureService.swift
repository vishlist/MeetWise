import ScreenCaptureKit
import AVFoundation
import Combine
import Foundation

@Observable
final class AudioCaptureService {
    var isCapturing = false
    var audioLevel: Float = 0.0
    var captureMode: CaptureMode = .systemAndMic

    enum CaptureMode {
        case systemAndMic   // Full: system audio + microphone
        case micOnly        // Fallback: microphone only
    }

    private var screenCaptureStream: SCStream?
    private var audioEngine: AVAudioEngine?
    private var audioStreamOutput: AudioStreamOutput?

    var onAudioData: ((Data) -> Void)?

    private var rawAudioData = Data()
    private let audioQueue = DispatchQueue(label: "com.meetwise.audio")

    func startCapture() async throws {
        // Try system audio first, fall back to mic-only
        do {
            try await startSystemAudioCapture()
            captureMode = .systemAndMic
        } catch {
            print("[AudioCapture] System audio failed: \(error.localizedDescription)")
            print("[AudioCapture] Falling back to microphone-only mode")
            captureMode = .micOnly
        }

        // Always start microphone capture
        do {
            try startMicrophoneCapture()
        } catch {
            // If even mic fails, throw
            if captureMode == .micOnly {
                throw AudioCaptureError.captureFailure("Microphone capture failed: \(error.localizedDescription)")
            }
            print("[AudioCapture] Mic capture failed (system audio still active): \(error)")
        }

        await MainActor.run {
            isCapturing = true
        }
    }

    // MARK: - System Audio (ScreenCaptureKit)
    private func startSystemAudioCapture() async throws {
        // Request access and get shareable content
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
        } catch {
            throw AudioCaptureError.permissionDenied
        }

        guard let display = content.displays.first else {
            throw AudioCaptureError.noDisplayFound
        }

        // Configure for audio-only capture
        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.excludesCurrentProcessAudio = false
        config.sampleRate = 16000
        config.channelCount = 1

        // Minimal video (ScreenCaptureKit requires a display filter)
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1)
        config.width = 2
        config.height = 2

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let stream = SCStream(filter: filter, configuration: config, delegate: nil)

        let output = AudioStreamOutput { [weak self] sampleBuffer in
            self?.handleSystemAudioBuffer(sampleBuffer)
        }
        self.audioStreamOutput = output

        try stream.addStreamOutput(output, type: .audio, sampleHandlerQueue: audioQueue)
        try await stream.startCapture()
        self.screenCaptureStream = stream
    }

    private func handleSystemAudioBuffer(_ sampleBuffer: CMSampleBuffer) {
        // Extract audio data from CMSampleBuffer and convert to Linear16
        guard let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else { return }

        var length = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        let status = CMBlockBufferGetDataPointer(
            blockBuffer, atOffset: 0, lengthAtOffsetOut: nil,
            totalLengthOut: &length, dataPointerOut: &dataPointer
        )
        guard status == noErr, let pointer = dataPointer, length > 0 else { return }

        // The audio from ScreenCaptureKit is usually Float32 PCM
        // Convert to Int16 for Deepgram
        let floatCount = length / MemoryLayout<Float>.size
        let floatPointer = UnsafeRawPointer(pointer).bindMemory(to: Float.self, capacity: floatCount)

        var int16Data = Data(count: floatCount * 2)
        int16Data.withUnsafeMutableBytes { rawBuffer in
            guard let ptr = rawBuffer.bindMemory(to: Int16.self).baseAddress else { return }
            for i in 0..<floatCount {
                let sample = floatPointer[i]
                let clamped = max(-1.0, min(1.0, sample))
                ptr[i] = Int16(clamped * Float(Int16.max))
            }
        }

        onAudioData?(int16Data)
        rawAudioData.append(int16Data)
        updateAudioLevel(from: int16Data)
    }

    // MARK: - Microphone (AVAudioEngine)
    private func startMicrophoneCapture() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        guard nativeFormat.sampleRate > 0 else {
            throw AudioCaptureError.captureFailure("No microphone available")
        }

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nativeFormat) { [weak self] buffer, _ in
            guard let data = self?.convertBufferToLinear16(buffer) else { return }
            self?.audioQueue.async {
                self?.onAudioData?(data)
                if self?.captureMode == .micOnly {
                    self?.rawAudioData.append(data)
                    self?.updateAudioLevel(from: data)
                }
            }
        }

        try engine.start()
        self.audioEngine = engine
    }

    // MARK: - Stop
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

    // MARK: - Utilities
    private func convertBufferToLinear16(_ buffer: AVAudioPCMBuffer) -> Data? {
        guard let floatData = buffer.floatChannelData else { return nil }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return nil }

        // Resample from native rate to 16kHz if needed
        let nativeRate = buffer.format.sampleRate
        let targetRate: Double = 16000

        if abs(nativeRate - targetRate) < 1 {
            // Already at 16kHz, direct conversion
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
        } else {
            // Simple downsampling (skip samples)
            let ratio = nativeRate / targetRate
            let outputCount = Int(Double(frameCount) / ratio)
            guard outputCount > 0 else { return nil }

            var int16Data = Data(count: outputCount * 2)
            int16Data.withUnsafeMutableBytes { rawBuffer in
                guard let ptr = rawBuffer.bindMemory(to: Int16.self).baseAddress else { return }
                for i in 0..<outputCount {
                    let sourceIndex = min(Int(Double(i) * ratio), frameCount - 1)
                    let sample = floatData[0][sourceIndex]
                    let clamped = max(-1.0, min(1.0, sample))
                    ptr[i] = Int16(clamped * Float(Int16.max))
                }
            }
            return int16Data
        }
    }

    private func updateAudioLevel(from data: Data) {
        guard data.count >= 2 else { return }
        let samples = data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Int16.self))
        }
        guard !samples.isEmpty else { return }
        let rms = sqrt(samples.map { Float($0) * Float($0) }.reduce(0, +) / Float(samples.count))
        let normalized = min(1.0, rms / Float(Int16.max) * 4.0)
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = normalized
        }
    }
}

// MARK: - SCStreamOutput handler
class AudioStreamOutput: NSObject, SCStreamOutput {
    let onSampleBuffer: (CMSampleBuffer) -> Void

    init(onSampleBuffer: @escaping (CMSampleBuffer) -> Void) {
        self.onSampleBuffer = onSampleBuffer
    }

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        onSampleBuffer(sampleBuffer)
    }
}

// MARK: - Errors
enum AudioCaptureError: Error, LocalizedError {
    case noDisplayFound
    case permissionDenied
    case captureFailure(String)

    var errorDescription: String? {
        switch self {
        case .noDisplayFound: return "No display found for audio capture"
        case .permissionDenied: return "Screen Recording permission required. Go to System Settings → Privacy & Security → Screen & System Audio Recording → enable MeetWise"
        case .captureFailure(let msg): return msg
        }
    }
}
