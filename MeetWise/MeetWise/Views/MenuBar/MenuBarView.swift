import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accentGreen)
                Text("MeetWise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Divider()

            if appState.isRecording {
                // Recording state
                HStack(spacing: 8) {
                    Circle().fill(.red).frame(width: 8, height: 8)
                    Text("Recording")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(formatDuration(appState.recordingDuration))
                        .font(.system(size: 13).monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

                // Audio level indicator
                HStack(spacing: 2) {
                    ForEach(0..<20, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Float(i) / 20.0 < appState.audioLevel ? Theme.accentGreen : Theme.bgCard)
                            .frame(width: 8, height: 12)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)

                Button {
                    appState.isRecording = false
                } label: {
                    HStack {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 10))
                        Text("Stop Recording")
                            .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.15))
                    .foregroundStyle(.red)
                    .cornerRadius(Theme.radiusSM)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
            } else {
                // Quick Note button
                Button {
                    appState.isRecording = true
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                        Text("Quick Note")
                            .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Theme.accentGreen.opacity(0.15))
                    .foregroundStyle(Theme.accentGreen)
                    .cornerRadius(Theme.radiusSM)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)

                // Recent meetings
                if let recent = appState.recentMeetingTitle {
                    Divider()
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textMuted)
                        Text(recent)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }

            Divider()

            Button {
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                HStack {
                    Text("Open MeetWise")
                        .font(.system(size: 13))
                    Spacer()
                    Text("⌘O")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            Button {
                appState.selectedNavItem = .settings
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Text("Settings...")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack {
                    Text("Quit MeetWise")
                        .font(.system(size: 13))
                    Spacer()
                    Text("⌘Q")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textMuted)
                }
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q")

            Spacer().frame(height: 4)
        }
        .frame(width: 250)
        .background(Theme.bgPrimary)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}
