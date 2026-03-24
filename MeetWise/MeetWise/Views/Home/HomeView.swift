import SwiftUI
import SwiftData

struct HomeView: View {
    var sessionManager: MeetingSessionManager
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meeting.startedAt, order: .reverse) private var recentMeetings: [Meeting]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Coming up section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Coming up")
                        .font(.heading(28))
                        .foregroundStyle(Theme.textHeading)

                    // Today's date + meetings
                    calendarCard
                }

                // Notes section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Notes")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .textCase(.uppercase)

                    if recentMeetings.isEmpty {
                        emptyNotesState
                    } else {
                        ForEach(recentMeetings.prefix(5)) { meeting in
                            recentNoteRow(meeting)
                        }
                    }
                }
            }
            .padding(.horizontal, 48)
            .padding(.top, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
    }

    // MARK: - Calendar Card
    private var calendarCard: some View {
        VStack(spacing: 0) {
            // Date header with demo meeting
            HStack(alignment: .top, spacing: 16) {
                // Date
                VStack(spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: Date()))")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(Theme.textPrimary)
                    Text(dayOfWeek)
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(width: 50)

                Text(monthName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)

                Spacer()
            }
            .padding(16)
            .background(Theme.bgCard)
            .cornerRadius(Theme.radiusLG, corners: [.topLeft, .topRight])

            // No upcoming events
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.textMuted)
                Text("No upcoming events")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.textSecondary)
                Text("Check your visible calendars")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textMuted)
                Button("Calendar settings") { }
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusSM)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Theme.bgPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radiusLG)
                    .stroke(Theme.bgCardBorder, style: StrokeStyle(lineWidth: 1, dash: [6]))
            )
        }
        .cornerRadius(Theme.radiusLG)
    }

    // MARK: - Empty Notes State
    private var emptyNotesState: some View {
        VStack(spacing: 12) {
            Text("Take your first note")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.textPrimary)
            Text("Your meeting notes will appear here")
                .font(.system(size: 13))
                .foregroundStyle(Theme.textSecondary)
            Button {
                Task {
                    await sessionManager.startRecording(modelContext: modelContext)
                    if let meeting = sessionManager.currentMeeting {
                        appState.selectedMeeting = meeting
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: sessionManager.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 12))
                    Text(sessionManager.isRecording ? "Recording..." : "Quick Note")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(sessionManager.isRecording ? .white : Theme.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(sessionManager.isRecording ? Color.red : Theme.bgCard)
                .cornerRadius(Theme.radiusSM)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusSM)
                        .stroke(sessionManager.isRecording ? Color.red : Theme.border, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Recent Note Row
    private func recentNoteRow(_ meeting: Meeting) -> some View {
        Button {
            appState.selectedMeeting = meeting
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(meeting.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(meeting.formattedDate)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if let duration = meeting.durationSeconds {
                    Text("\(duration / 60) min")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)
                }
            }
            .padding(12)
            .background(Theme.bgCard.opacity(0.5))
            .cornerRadius(Theme.radiusMD)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: Date())
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: Date())
    }
}

// UnevenRoundedRectangle is available in macOS 13.0+
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: corners.contains(.topLeft) ? radius : 0,
                bottomLeadingRadius: corners.contains(.bottomLeft) ? radius : 0,
                bottomTrailingRadius: corners.contains(.bottomRight) ? radius : 0,
                topTrailingRadius: corners.contains(.topRight) ? radius : 0
            )
        )
    }
}

struct RectCorner: OptionSet {
    let rawValue: Int
    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}
