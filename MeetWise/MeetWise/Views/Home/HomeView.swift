import SwiftUI
import SwiftData

struct HomeView: View {
    var sessionManager: MeetingSessionManager
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Meeting.startedAt, order: .reverse) private var recentMeetings: [Meeting]
    @State private var homeChat = ""
    @State private var appeared = false
    @State private var homeChatMessages: [(role: String, content: String)] = []
    @State private var calendarAuthorized = false

    private var calendarService: CalendarService {
        appState.calendarService
    }

    // MARK: - Computed Stats
    private var activeNotesCount: Int {
        recentMeetings.filter { $0.status != "failed" }.count
    }

    private var completedCount: Int {
        recentMeetings.filter { $0.status == "completed" }.count
    }

    private var thisWeekMeetings: [Meeting] {
        let cal = Calendar.current
        let startOfWeek = cal.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        return recentMeetings.filter { $0.startedAt >= startOfWeek }
    }

    private var actionItemsCount: Int {
        var count = 0
        for meeting in recentMeetings {
            if let data = meeting.summaryJSON,
               let summary = try? JSONDecoder().decode(EnhancementService.MeetingSummary.self, from: data) {
                count += summary.actionItems.count
            }
        }
        return count
    }

    private var todayActionItems: [(task: String, assignee: String?, meetingTitle: String)] {
        var items: [(task: String, assignee: String?, meetingTitle: String)] = []
        let todayMeetings = recentMeetings.filter { Calendar.current.isDateInToday($0.startedAt) }
        for meeting in todayMeetings {
            if let data = meeting.summaryJSON,
               let summary = try? JSONDecoder().decode(EnhancementService.MeetingSummary.self, from: data) {
                for item in summary.actionItems {
                    items.append((task: item.task, assignee: item.assignee, meetingTitle: meeting.title))
                }
            }
        }
        return items
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Greeting
                    greetingSection
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appeared)

                    // Stats cards
                    statsCardsRow
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.05), value: appeared)

                    // Main content: calendar + tasks side by side
                    HStack(alignment: .top, spacing: 24) {
                        VStack(alignment: .leading, spacing: 24) {
                            // Calendar
                            calendarCard
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 12)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: appeared)

                            // Recent notes
                            if !recentMeetings.isEmpty {
                                notesSection
                                    .opacity(appeared ? 1 : 0)
                                    .offset(y: appeared ? 0 : 12)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15), value: appeared)
                            } else {
                                emptyNotesState
                                    .opacity(appeared ? 1 : 0)
                                    .animation(.easeOut(duration: 0.4).delay(0.15), value: appeared)
                            }
                        }

                        // Today's tasks column
                        if !todayActionItems.isEmpty {
                            todayTasksColumn
                                .frame(width: 280)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared ? 0 : 12)
                                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appeared)
                        }
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
            calendarAuthorized = calendarService.isAuthorized
            withAnimation { appeared = true }
        }
    }

    // MARK: - Greeting
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hello, \(appState.currentUser?.fullName ?? "there")")
                .font(.heading(28))
                .foregroundStyle(Theme.textHeading)
            Text("You have \(thisWeekMeetings.count) meeting\(thisWeekMeetings.count == 1 ? "" : "s") this week")
                .font(.system(size: 14))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Stats Cards Row
    private var statsCardsRow: some View {
        HStack(spacing: 12) {
            StatsCard(
                title: "Active Notes",
                value: "\(activeNotesCount)",
                subtitle: "Total meetings",
                icon: "doc.text.fill"
            )
            StatsCard(
                title: "Completed",
                value: "\(completedCount)/\(recentMeetings.count)",
                subtitle: completedCount == recentMeetings.count ? "All done" : "\(recentMeetings.count - completedCount) remaining",
                icon: "checkmark.circle.fill"
            )
            StatsCard(
                title: "This Week",
                value: "\(thisWeekMeetings.count)",
                subtitle: "Meetings",
                icon: "calendar"
            )
            StatsCard(
                title: "Action Items",
                value: "\(actionItemsCount)",
                subtitle: "Pending tasks",
                icon: "checklist"
            )
        }
    }

    // MARK: - Calendar Card
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

            if !calendarAuthorized {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.textMuted)
                    Text("Calendar not connected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Theme.textSecondary)
                    Text("Connect your calendar to see upcoming meetings")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textMuted)

                    HStack(spacing: 12) {
                        Button("Connect Calendar") {
                            Task {
                                await calendarService.requestAccess()
                                calendarAuthorized = calendarService.isAuthorized
                            }
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.white)
                        .cornerRadius(Theme.radiusSM)
                        .buttonStyle(.plain)
                        .hoverScale(1.05)

                        Button("Calendar Settings") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.datetime")!)
                        }
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Theme.accent.opacity(0.1))
                        .cornerRadius(Theme.radiusSM)
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .overlay(
                    UnevenRoundedRectangle(bottomLeadingRadius: Theme.radiusLG, bottomTrailingRadius: Theme.radiusLG)
                        .stroke(Theme.border, style: StrokeStyle(lineWidth: 1, dash: [6]))
                )
            } else if calendarService.todayEvents.isEmpty {
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

                    Button("Calendar Settings") {
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.datetime")!)
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
                        calendarEventRow(event)
                    }
                }
                .glassCard(cornerRadius: Theme.radiusLG)
            }
        }
    }

    private func calendarEventRow(_ event: CalendarService.CalendarEvent) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Theme.accent)
                .frame(width: 3, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Theme.textPrimary)

                HStack(spacing: 6) {
                    Text(event.formattedTimeRange)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.textSecondary)

                    if !event.attendees.isEmpty {
                        Text("*")
                            .foregroundStyle(Theme.textMuted)
                        Text(event.attendees.prefix(3).map(\.name).joined(separator: ", "))
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.textMuted)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()

            if event.meetingURL != nil {
                Image(systemName: "video.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.textMuted)
            }

            if event.meetingURL != nil {
                Button {
                    Task {
                        await sessionManager.startRecording(
                            modelContext: modelContext,
                            title: event.title
                        )
                        if let meeting = sessionManager.currentMeeting {
                            for attendee in event.attendees {
                                let participant = MeetingParticipant(name: attendee.name, email: attendee.email)
                                participant.meeting = meeting
                                modelContext.insert(participant)
                            }
                            meeting.calendarEventID = event.id
                            if let url = event.meetingURL {
                                meeting.meetingURL = url
                            }
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
        .hoverHighlight()
    }

    // MARK: - Notes Section (Recent Notes)
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Notes")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)

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
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: Theme.radiusSM)
                            .fill(Theme.bgCard)
                            .frame(width: 36, height: 36)

                        if sessionManager.isRecording && sessionManager.currentMeeting?.id == meeting.id {
                            Circle().fill(Theme.accentRed).frame(width: 8, height: 8)
                        } else {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(Theme.accent.opacity(0.6))
                        }
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

                    if meeting.platform != nil {
                        Image(systemName: "video.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.textMuted)
                    }

                    Text(meeting.formattedTime)
                        .font(.mono(12))
                        .foregroundStyle(Theme.textMuted)
                }

                // Tags row: extract topics from summary
                if let data = meeting.summaryJSON,
                   let summary = try? JSONDecoder().decode(EnhancementService.MeetingSummary.self, from: data),
                   !summary.topics.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(summary.topics.prefix(4), id: \.self) { topic in
                            TagPill(text: topic)
                        }
                    }
                    .padding(.leading, 48)
                }
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

    // MARK: - Today's Tasks Column
    private var todayTasksColumn: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checklist")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.textMuted)
                Text("Today's Tasks")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(todayActionItems.count)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textMuted)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Theme.bgCard)
                    .cornerRadius(Theme.radiusPill)
            }

            ForEach(Array(todayActionItems.prefix(8).enumerated()), id: \.offset) { _, item in
                ActionItemRow(
                    task: item.task,
                    assignee: item.assignee,
                    deadline: nil
                )
            }
        }
        .padding(16)
        .background(Theme.bgCard)
        .cornerRadius(Theme.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.radiusMD)
                .stroke(Theme.border, lineWidth: 1)
        )
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
                let meeting = sessionManager.startQuickNote(modelContext: modelContext)
                appState.selectedMeeting = meeting
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 12))
                    Text("Quick Note").font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(Color.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white)
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
                        .onSubmit { sendHomeChatMessage() }
                    Spacer()

                    if appState.chatService.isLoading {
                        ProgressView().controlSize(.small)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .glassCard(cornerRadius: Theme.radiusPill)

                Button {
                    homeChat = "List recent todos"
                    sendHomeChatMessage()
                } label: {
                    HStack(spacing: 4) {
                        Text("/")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.accent)
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

    // MARK: - Actions
    private func sendHomeChatMessage() {
        guard !homeChat.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let question = homeChat
        homeChat = ""

        appState.selectedNavItem = .chat
        appState.selectedMeeting = nil

        Task {
            let _ = await appState.chatService.askAcrossMeetings(question, meetings: recentMeetings)
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
