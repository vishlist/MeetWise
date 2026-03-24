import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 8) {
            if appState.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("Recording...")
                        .font(.system(size: 13))
                    Spacer()
                    Text(formatDuration(appState.recordingDuration))
                        .font(.system(size: 13).monospacedDigit())
                }

                Button("Stop Recording") {
                    appState.isRecording = false
                }
            } else {
                Text("MeetWise")
                    .font(.system(size: 13, weight: .medium))

                Button("Quick Note") {
                    // Start recording
                    appState.isRecording = true
                }

                Divider()

                Button("Open MeetWise") {
                    NSApp.activate(ignoringOtherApps: true)
                }
            }

            Divider()

            Button("Settings...") {
                appState.selectedNavItem = .settings
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Quit MeetWise") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(8)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let m = Int(duration) / 60
        let s = Int(duration) % 60
        return String(format: "%d:%02d", m, s)
    }
}
