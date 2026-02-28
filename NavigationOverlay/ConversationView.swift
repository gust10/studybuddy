import SwiftUI

struct ConversationView: View {
    @StateObject private var client = ElevenLabsClient()
    @State private var showConfig   = false

    private var isActive: Bool {
        client.convState == .listening || client.convState == .speaking
    }

    var body: some View {
        VStack(spacing: 0) {
            if isActive && (!client.userTranscript.isEmpty || !client.agentTranscript.isEmpty) {
                transcriptStrip
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            mainPill
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
        .sheet(isPresented: $showConfig) { ConfigSheet(client: client) }
    }

    // MARK: - Pill

    private var mainPill: some View {
        HStack(spacing: 14) {
            Button {
                Task {
                    if isActive || client.convState == .connecting { client.stop() }
                    else { await client.start() }
                }
            } label: {
                micButtonLabel
                    .frame(width: 40, height: 40)
                    .background(micButtonBackground)
            }
            .buttonStyle(.plain)

            if client.convState == .connecting {
                ProgressView().scaleEffect(0.7)
                Text("Connecting…").font(.system(size: 13)).foregroundStyle(.secondary)
            } else if isActive {
                WaveformView(isSpeaking: client.convState == .speaking).frame(height: 24)
            } else {
                Text("Talk to StudyBuddy")
                    .font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if !isActive {
                Button { showConfig = true } label: {
                    Image(systemName: "gearshape").font(.system(size: 13)).foregroundStyle(.secondary)
                }.buttonStyle(.plain)
            }

            if case .error(let msg) = client.convState, !msg.isEmpty {
                Text(msg).font(.system(size: 11)).foregroundStyle(.red).lineLimit(2)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(pillBackground)
    }

    @ViewBuilder private var micButtonLabel: some View {
        if isActive {
            Image(systemName: "stop.fill")
                .font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
        } else {
            Image(systemName: "mic.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(client.convState == .connecting ? .gray : .white)
        }
    }

    @ViewBuilder private var micButtonBackground: some View {
        if isActive { Circle().fill(Color.red) }
        else        { Circle().fill(Color.accentColor) }
    }

    private var transcriptStrip: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !client.userTranscript.isEmpty {
                Label(client.userTranscript, systemImage: "person.fill")
                    .font(.system(size: 11)).foregroundStyle(.secondary).lineLimit(2)
            }
            if !client.agentTranscript.isEmpty {
                Label(client.agentTranscript, systemImage: "sparkles")
                    .font(.system(size: 11, weight: .medium)).lineLimit(3)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VisualEffectView().clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)))
    }

    private var pillBackground: some View {
        ZStack {
            VisualEffectView()
            if isActive {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(client.convState == .speaking
                            ? Color.green.opacity(0.5) : Color.accentColor.opacity(0.4),
                            lineWidth: 1.5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, y: -4)
    }
}

// MARK: - Waveform

struct WaveformView: View {
    let isSpeaking: Bool
    @State private var heights: [CGFloat] = [8, 14, 10, 18, 8, 13, 9]
    private let timer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<heights.count, id: \.self) { i in
                Capsule()
                    .fill(isSpeaking ? Color.green : Color.accentColor)
                    .frame(width: 3, height: heights[i])
                    .animation(.easeInOut(duration: 0.11), value: heights[i])
            }
        }
        .onReceive(timer) { _ in heights = heights.map { _ in .random(in: 4...22) } }
    }
}

// MARK: - Config Sheet

struct ConfigSheet: View {
    @ObservedObject var client: ElevenLabsClient
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey:  String = UserDefaults.standard.string(forKey: "el_api_key")  ?? ""
    @State private var agentID: String = UserDefaults.standard.string(forKey: "el_agent_id") ?? ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ElevenLabs Configuration").font(.headline)
            LabeledContent("API Key") {
                SecureField("xi-…", text: $apiKey).textFieldStyle(.roundedBorder).frame(width: 260)
            }
            LabeledContent("Agent ID") {
                TextField("agent_…", text: $agentID).textFieldStyle(.roundedBorder).frame(width: 260)
            }
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Save") {
                    UserDefaults.standard.set(apiKey,  forKey: "el_api_key")
                    UserDefaults.standard.set(agentID, forKey: "el_agent_id")
                    client.apiKey = apiKey; client.agentID = agentID
                    dismiss()
                }.buttonStyle(.borderedProminent)
            }
        }
        .padding(24).frame(minWidth: 400)
    }
}
