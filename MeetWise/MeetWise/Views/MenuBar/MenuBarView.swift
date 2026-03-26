import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @Query(sort: \Meeting.startedAt, order: .reverse) private var recentMeetings: [Meeting]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Header
            HStack {
                Image(systemName: "waveform.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.accent)
                Text("MeetWise")
                    .font(.custom("InstrumentSerif-Regular", size: 13))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()

                // Meeting detection status
                if appState.meetingDetectionService.isMonitoring {
                    Circle()
                        .fill(Theme.accent.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            Divider().background(Theme.divider)

            if appState.isRecording {
                // Recording state
                HStack(spacing: 8) {
                    Circle()
                        .fill(Theme.accentRed)
                        .frame(width: 8, height: 8)
                        .shadow(color: Theme.accentRed.opacity(0.4), radius: 3)
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
                            .fill(Float(i) / 20.0 < appState.audioLevel ? Theme.accent : Theme.accentSoft)
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
                            .font(.system(size: 13, weight: .light))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Theme.accentRed.opacity(0.08))
                    .foregroundStyle(Theme.accentRed)
                    .cornerRadius(Theme.radiusSM)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
            } else {
                // Detected meeting info
                if let detected = appState.meetingDetectionService.detectedMeeting {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Theme.accent)
                            .frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(detected.platform.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Theme.textPrimary)
                            Text(detected.windowTitle)
                                .font(.system(size: 11, weight: .light))
                                .foregroundStyle(Theme.textMuted)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)

                    Divider().background(Theme.divider)
                }

                // Quick Note button
                Button {
                    appState.isRecording = true
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 12))
                        Text("Quick Note")
                            .font(.system(size: 13, weight: .light))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Theme.accentSoft)
                    .foregroundStyle(Theme.accent)
                    .cornerRadius(Theme.radiusSM)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)

                // Recent meetings
                if !recentMeetings.isEmpty {
                    Divider().background(Theme.divider)

                    Text("Recent")
                        .font(.custom("InstrumentSerif-Regular", size: 10))
                        .foregroundStyle(Theme.textMuted)
                        .tracking(0.5)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)

                    ForEach(recentMeetings.prefix(5)) { meeting in
                        Button {
                            appState.selectedMeeting = meeting
                            NSApp.activate(ignoringOtherApps: true)
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.text")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textMuted)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(meeting.title)
                                        .font(.system(size: 12, weight: .light))
                                        .foregroundStyle(Theme.textPrimary)
                                        .lineLimit(1)
                                    Text(meeting.formattedDate)
                                        .font(.system(size: 10, weight: .light))
                                        .foregroundStyle(Theme.textMuted)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 3)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().background(Theme.divider)

            Button {
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                HStack {
                    Text("Open MeetWise")
                        .font(.system(size: 13, weight: .light))
                    Spacer()
                    Text("O")
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
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain)

            Divider().background(Theme.divider)

            Button {
                NSApp.terminate(nil)
            } label: {
                HStack {
                    Text("Quit MeetWise")
                        .font(.system(size: 13, weight: .light))
                    Spacer()
                    Text("Q")
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
        .frame(width: 260)
        .background(Theme.bgPrimary)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}
