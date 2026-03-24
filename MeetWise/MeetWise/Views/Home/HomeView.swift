import SwiftUI
import SwiftData

struct HomeView: View {
    var sessionManager: MeetingSessionManager
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meeting.startedAt, order: .reverse) private var recentMeetings: [Meeting]
    @State private var calendarService = CalendarService()
    @State private var homeChat = ""
    @State private var appeared = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Coming up
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Coming up")
                            .font(.heading(28))
                            .foregroundStyle(Theme.textHeading)

                        calendarCard
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)
                    }

                    // Notes
                    if !recentMeetings.isEmpty {
                        notesSection
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 12)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
                    } else {
                        emptyNotesState
                            .opacity(appeared ? 1 : 0)
                            .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                    }

                    Spacer(minLength: 80)
                }
                .padding(.horizontal, 48)
                .padding(.top, 40)
            }

            homeBottomBar
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bgPrimary)
        .task {
            await calendarService.requestAccess()
            withAnimation { appeared = true }
        }
    }

    // MARK: - Calendar Card (Glass)
    private var calendarCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: Date()))")
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundStyle(Theme.textPrimary)
                    Text(dayOfWeek)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(width: 50)

                Text(monthName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.accent)

                Spacer()
            }
            .padding(16)
            .background(Theme.bgCard)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: Theme.radiusLG, topTrailingRadius: Theme.radiusLG))

            if calendarService.todayEvents.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.textMuted)
                    Text("No upcoming events")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Check your visible calendars")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)

                    Button("Calendar settings") {
                        appState.selectedNavItem = .settings
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Theme.accent.opacity(0.1))
                    .cornerRadius(Theme.radiusSM)
                    .padding(.top, 4)
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .overlay(
                    UnevenRoundedRectangle(bottomLeadingRadius: Theme.radiusLG, bottomTrailingRadius: Theme.radiusLG)
                        .stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(calendarService.todayEvents) { event in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.accent)
                                .frame(width: 3, height: 32)

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
                                    Task {
                                        await sessionManager.startRecording(modelContext: modelContext)
                                        if let meeting = sessionManager.currentMeeting {
                                            meeting.title = event.title
                                            try? modelContext.save()
                                            appState.selectedMeeting = meeting
                                        }
                                    }
                                } label: {
                                    Text("Join & Note")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(Theme.accent)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 5)
                                        .background(Theme.accent.opacity(0.12))
                                        .cornerRadius(Theme.radiusPill)
                                }
                                .buttonStyle(.plain)
                                .hoverScale(1.05)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    }
                }
                .glassCard(cornerRadius: Theme.radiusLG)
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
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                    .tracking(0.5)
                    .padding(.top, 8)

                ForEach(meetings) { meeting in
                    noteRow(meeting)
                }
            }
        }
    }

    private func noteRow(_ meeting: Meeting) -> some View {
        Button { appState.selectedMeeting = meeting } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: Theme.radiusSM)
                        .fill(Theme.bgCard)
                        .frame(width: 36, height: 36)
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.accent.opacity(0.6))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(meeting.title)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textPrimary)
                    Text(meeting.participants?.map(\.name).joined(separator: ", ") ?? "Me")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                if meeting.enhancedNotes != nil {
                    PillTag("Enhanced", icon: "sparkles", color: Theme.accent)
                }

                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.textMuted)

                Text(meeting.formattedTime)
                    .font(.mono(12))
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: Theme.radiusMD)
                    .fill(Theme.bgCard.opacity(0.5))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(HoverButtonStyle(cornerRadius: Theme.radiusMD))
    }

    // MARK: - Empty State
    private var emptyNotesState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 40))
                .foregroundStyle(Theme.accent.opacity(0.4))

            Text("Take your first note")
                .font(.subheading(16))
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
                    Image(systemName: "plus").font(.system(size: 12))
                    Text("Quick Note").font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.gradientAccent)
                .cornerRadius(Theme.radiusPill)
                .glow(Theme.accent)
            }
            .buttonStyle(.plain)
            .hoverScale(1.05)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    // MARK: - Bottom Bar
    private var homeBottomBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.divider).frame(height: 1)
            HStack(spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.accent)
                    TextField("What did we talk about yesterday?", text: $homeChat)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: Theme.radiusPill)

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
                    .glassCard(cornerRadius: Theme.radiusPill)
                }
                .buttonStyle(.plain)
                .hoverScale(1.03)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Theme.bgPrimary)
        }
    }

    // MARK: - Helpers
    private var dayOfWeek: String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: Date())
    }
    private var monthName: String {
        let f = DateFormatter(); f.dateFormat = "MMMM"; return f.string(from: Date())
    }
    private func dayLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"; return f.string(from: date)
    }
}
