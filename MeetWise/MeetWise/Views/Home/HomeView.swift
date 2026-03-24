import SwiftUI
import SwiftData

struct HomeView: View {
    var sessionManager: MeetingSessionManager
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meeting.startedAt, order: .reverse) private var recentMeetings: [Meeting]
    @State private var calendarService = CalendarService()
    @State private var homeChat = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Coming up section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Coming up")
                            .font(.heading(28))
                            .foregroundStyle(Theme.textHeading)

                        calendarCard
                    }

                    // Notes section grouped by day
                    if !recentMeetings.isEmpty {
                        notesSection
                    } else {
                        emptyNotesState
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 48)
                .padding(.top, 40)
            }

            // Bottom chat bar
            homeBottomBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
        .task {
            await calendarService.requestAccess()
        }
    }

    // MARK: - Calendar Card
    private var calendarCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
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
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: Theme.radiusLG, topTrailingRadius: Theme.radiusLG))

            // Events or empty state
            if calendarService.todayEvents.isEmpty {
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
                    Button("Calendar settings") {
                        appState.selectedNavItem = .settings
                    }
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
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .overlay(
                    UnevenRoundedRectangle(bottomLeadingRadius: Theme.radiusLG, bottomTrailingRadius: Theme.radiusLG)
                        .stroke(Theme.bgCardBorder, style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
            } else {
                // Show real calendar events
                VStack(spacing: 0) {
                    ForEach(calendarService.todayEvents) { event in
                        HStack(spacing: 12) {
                            Rectangle()
                                .fill(Theme.accentGreen)
                                .frame(width: 3)
                                .cornerRadius(2)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Theme.textPrimary)
                                Text(event.formattedTimeRange)
                                    .font(.system(size: 12))
                                    .foregroundStyle(Theme.textSecondary)
                            }

                            Spacer()

                            if event.meetingURL != nil {
                                Button {
                                    // Start recording for this meeting
                                    Task {
                                        await sessionManager.startRecording(modelContext: modelContext)
                                        if let meeting = sessionManager.currentMeeting {
                                            meeting.title = event.title
                                            meeting.calendarEventID = event.id
                                            try? modelContext.save()
                                            appState.selectedMeeting = meeting
                                        }
                                    }
                                } label: {
                                    Text("Join & Note")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Theme.accentGreen)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(Theme.accentGreen.opacity(0.15))
                                        .cornerRadius(Theme.radiusSM)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)

                        if event.id != calendarService.todayEvents.last?.id {
                            Divider().background(Theme.divider).padding(.horizontal, 16)
                        }
                    }
                }
                .background(Theme.bgCard.opacity(0.3))
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: Theme.radiusLG, bottomTrailingRadius: Theme.radiusLG))
                .overlay(
                    UnevenRoundedRectangle(bottomLeadingRadius: Theme.radiusLG, bottomTrailingRadius: Theme.radiusLG)
                        .stroke(Theme.bgCardBorder, lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            let grouped = Dictionary(grouping: recentMeetings) { meeting in
                Calendar.current.startOfDay(for: meeting.startedAt)
            }
            let sortedDays = grouped.keys.sorted(by: >)

            ForEach(sortedDays, id: \.self) { day in
                let meetings = grouped[day] ?? []

                Text(dayLabel(day))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textSecondary)
                    .padding(.top, 8)

                ForEach(meetings) { meeting in
                    noteRow(meeting)
                }
            }
        }
    }

    private func noteRow(_ meeting: Meeting) -> some View {
        Button {
            appState.selectedMeeting = meeting
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "doc.text")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.textMuted)
                    .frame(width: 32, height: 32)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)

                VStack(alignment: .leading, spacing: 2) {
                    Text(meeting.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(meeting.participants?.map(\.name).joined(separator: ", ") ?? "Me")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                Image(systemName: "lock")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)

                Text(meeting.formattedTime)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State
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
                Text("Quick Note")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusSM)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.radiusSM)
                            .stroke(Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Bottom Bar
    private var homeBottomBar: some View {
        VStack(spacing: 0) {
            Divider().background(Theme.divider)
            HStack(spacing: 12) {
                HStack {
                    TextField("What did we talk about yesterday?", text: $homeChat)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.bgCard)
                .cornerRadius(Theme.radiusPill)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.radiusPill)
                        .stroke(Theme.border, lineWidth: 1)
                )

                Button { } label: {
                    HStack(spacing: 4) {
                        Text("/")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.accentGreen)
                        Text("List recent todos")
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textPrimary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusPill)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Theme.bgPrimary)
        }
    }

    // MARK: - Helpers
    private var dayOfWeek: String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: Date())
    }

    private var monthName: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM"
        return f.string(from: Date())
    }

    private func dayLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }
}
