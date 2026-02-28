import Foundation
import AVFoundation

enum ConvState: Equatable {
    case idle, connecting, listening, speaking, error(String)
}

@MainActor
final class ElevenLabsClient: ObservableObject {

    @Published var convState: ConvState = .idle
    @Published var userTranscript:  String = ""
    @Published var agentTranscript: String = ""

    var apiKey:  String = UserDefaults.standard.string(forKey: "el_api_key")  ?? ""
    var agentID: String = UserDefaults.standard.string(forKey: "el_agent_id") ?? ""

    private var socket:       URLSessionWebSocketTask?
    private var urlSession:   URLSession?
    private let engine        = AVAudioEngine()
    private let playerNode    = AVAudioPlayerNode()
    private var playFmt:      AVAudioFormat?
    private var engineRunning = false

    func start() async {
        guard !apiKey.isEmpty, !agentID.isEmpty else {
            convState = .error("API key or Agent ID missing"); return
        }
        let granted = await requestMicPermission()
        guard granted else {
            convState = .error("Microphone access denied — check System Settings → Privacy")
            return
        }
        convState = .connecting
        guard setupAudio() else { return }
        await connectSocket()
    }

    func stop() {
        socket?.cancel(with: .normalClosure, reason: nil)
        socket = nil
        teardownAudio()
        convState = .idle
        userTranscript  = ""
        agentTranscript = ""
    }

    // MARK: - Mic Permission

    private func requestMicPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:    return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .audio)
        default:             return false
        }
    }

    // MARK: - Audio

    private func setupAudio() -> Bool {
        guard let fmt = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1) else {
            convState = .error("Audio format error"); return false
        }
        playFmt = fmt
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: fmt)
        installMicTap()
        do {
            try engine.start()
            engineRunning = true
            playerNode.play()
            return true
        } catch {
            convState = .error("Audio engine: \(error.localizedDescription)")
            return false
        }
    }

    private func installMicTap() {
        let inputNode = engine.inputNode
        let srcFmt    = inputNode.outputFormat(forBus: 0)
        guard let dstFmt = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                         sampleRate: 16_000, channels: 1, interleaved: true),
              let conv = AVAudioConverter(from: srcFmt, to: dstFmt) else {
            installFloat32Tap(); return
        }
        let ratio = dstFmt.sampleRate / srcFmt.sampleRate
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: srcFmt) { [weak self] buf, _ in
            let cap = AVAudioFrameCount(Double(buf.frameLength) * ratio) + 10
            guard let out = AVAudioPCMBuffer(pcmFormat: dstFmt, frameCapacity: cap) else { return }
            var used = false; var err: NSError?
            conv.convert(to: out, error: &err) { _, status in
                if used { status.pointee = .noDataNow; return nil }
                used = true; status.pointee = .haveData; return buf
            }
            guard err == nil, out.frameLength > 0, let ptr = out.int16ChannelData else { return }
            let bytes = Data(bytes: ptr[0], count: Int(out.frameLength) * 2)
            self?.sendAudio(bytes)
        }
    }

    private func installFloat32Tap() {
        let inputNode = engine.inputNode
        let srcFmt    = inputNode.outputFormat(forBus: 0)
        let step      = Int(srcFmt.sampleRate / 16_000)
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: srcFmt) { [weak self] buf, _ in
            guard let ch = buf.floatChannelData?[0] else { return }
            var out = [Int16](); var i = 0
            while i < Int(buf.frameLength) {
                out.append(Int16(max(-1, min(1, ch[i])) * 32_767)); i += step
            }
            self?.sendAudio(out.withUnsafeBytes { Data($0) })
        }
    }

    private func sendAudio(_ data: Data) {
        guard convState == .listening else { return }
        socket?.send(.string("{\"user_audio_chunk\":\"\(data.base64EncodedString())\"}")) { _ in }
    }

    private func teardownAudio() {
        guard engineRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        engineRunning = false
    }

    // MARK: - WebSocket

    private func connectSocket() async {
        guard let url = URL(string:
            "wss://api.elevenlabs.io/v1/convai/conversation?agent_id=\(agentID)&xi-api-key=\(apiKey)") else {
            convState = .error("Invalid agent ID"); return
        }
        urlSession = URLSession(configuration: .default)
        socket = urlSession?.webSocketTask(with: url)
        socket?.resume()
        await sendInitConfig()
        convState = .listening
        await receiveLoop()
    }

    private func sendInitConfig() async {
        let cfg: [String: Any] = [
            "type": "conversation_initiation_client_data",
            "conversation_config_override": [
                "agent": [
                    "prompt": ["prompt": "You are StudyBuddy, a concise and encouraging academic assistant."],
                    "first_message": "Hi! I'm StudyBuddy. What are you studying today?"
                ],
                "tts": ["agent_output_audio_format": "pcm_16000"]
            ]
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: cfg),
              let str  = String(data: data, encoding: .utf8) else { return }
        try? await socket?.send(.string(str))
    }

    private func receiveLoop() async {
        while socket != nil {
            do {
                guard let sock = socket else { break }
                switch try await sock.receive() {
                case .string(let s):  handle(s)
                case .data(let d):    if let s = String(data: d, encoding: .utf8) { handle(s) }
                @unknown default:     break
                }
            } catch {
                if convState != .idle {
                    let msg = error.localizedDescription
                    convState = msg.contains("cancelled") ? .idle : .error(msg)
                }
                break
            }
        }
    }

    private func handle(_ str: String) {
        guard let data = str.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        switch type {
        case "audio":
            guard let evt = json["audio_event"] as? [String: Any],
                  let b64 = evt["audio_base_64"] as? String,
                  let pcm = Data(base64Encoded: b64) else { return }
            convState = .speaking; playPCM(pcm)
        case "user_transcript":
            if let evt = json["user_transcription_event"] as? [String: Any],
               let t   = evt["user_transcript"] as? String { userTranscript = t }
        case "agent_response":
            if let evt = json["agent_response_event"] as? [String: Any],
               let t   = evt["agent_response"] as? String { agentTranscript = t }
        case "interruption":
            playerNode.stop(); playerNode.play(); convState = .listening
        case "ping":
            if let evt = json["ping_event"] as? [String: Any],
               let id  = evt["event_id"] as? Int {
                socket?.send(.string("{\"type\":\"pong\",\"event_id\":\(id)}")) { _ in }
            }
        case "conversation_initiation_metadata":
            convState = .listening
        default: break
        }
    }

    private func playPCM(_ data: Data) {
        guard let fmt = playFmt else { return }
        let n = data.count / 2
        guard n > 0, let buf = AVAudioPCMBuffer(pcmFormat: fmt, frameCapacity: AVAudioFrameCount(n)) else { return }
        buf.frameLength = AVAudioFrameCount(n)
        data.withUnsafeBytes { raw in
            let src = raw.bindMemory(to: Int16.self)
            if let dst = buf.floatChannelData?[0] {
                for i in 0..<n { dst[i] = Float(src[i]) / 32_768.0 }
            }
        }
        playerNode.scheduleBuffer(buf) {
            Task { @MainActor [weak self] in
                if self?.convState == .speaking { self?.convState = .listening }
            }
        }
    }
}
