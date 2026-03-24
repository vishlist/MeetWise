import EventKit
import Foundation

@MainActor @Observable
final class CalendarService {
    var isAuthorized = false
    var upcomingEvents: [CalendarEvent] = []
    var todayEvents: [CalendarEvent] = []

    private let eventStore = EKEventStore()

    struct CalendarEvent: Identifiable {
        let id: String
        let title: String
        let startDate: Date
        let endDate: Date
        let attendees: [Attendee]
        let meetingURL: String?
        let isAllDay: Bool
        let calendarColor: String

        struct Attendee {
            let name: String
            let email: String?
            let isOrganizer: Bool
        }

        var formattedTime: String {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return f.string(from: startDate)
        }

        var formattedTimeRange: String {
            let f = DateFormatter()
            f.dateFormat = "h:mm a"
            return "\(f.string(from: startDate)) - \(f.string(from: endDate))"
        }

        var durationMinutes: Int {
            Int(endDate.timeIntervalSince(startDate) / 60)
        }
    }

    func requestAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            isAuthorized = granted
            if granted {
                await fetchEvents()
            }
        } catch {
            print("[Calendar] Access request failed: \(error)")
            isAuthorized = false
        }
    }

    func fetchEvents() async {
        guard isAuthorized else { return }

        let calendar = Calendar.current
        let now = Date()
        let startOfToday = calendar.startOfDay(for: now)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: now)!

        // Today's events
        let todayPredicate = eventStore.predicateForEvents(
            withStart: startOfToday, end: endOfToday, calendars: nil
        )
        let todayEKEvents = eventStore.events(matching: todayPredicate)
        todayEvents = todayEKEvents.compactMap(mapEvent)
            .sorted { $0.startDate < $1.startDate }

        // Upcoming 7 days
        let upcomingPredicate = eventStore.predicateForEvents(
            withStart: now, end: endOfWeek, calendars: nil
        )
        let upcomingEKEvents = eventStore.events(matching: upcomingPredicate)
        upcomingEvents = upcomingEKEvents.compactMap(mapEvent)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
    }

    private func mapEvent(_ event: EKEvent) -> CalendarEvent? {
        // Extract meeting URL from notes, URL, or location
        var meetingURL: String?
        let allText = [event.url?.absoluteString, event.notes, event.location]
            .compactMap { $0 }.joined(separator: " ")

        if let range = allText.range(of: "https://meet.google.com/[a-z-]+", options: .regularExpression) {
            meetingURL = String(allText[range])
        } else if let range = allText.range(of: "https://[a-z]+\\.zoom\\.us/j/[0-9]+", options: .regularExpression) {
            meetingURL = String(allText[range])
        } else if let range = allText.range(of: "https://teams\\.microsoft\\.com/[^\\s]+", options: .regularExpression) {
            meetingURL = String(allText[range])
        }

        let attendees = (event.attendees ?? []).map { participant in
            CalendarEvent.Attendee(
                name: participant.name ?? participant.url.absoluteString,
                email: participant.url.absoluteString.replacingOccurrences(of: "mailto:", with: ""),
                isOrganizer: participant.isCurrentUser
            )
        }

        return CalendarEvent(
            id: event.eventIdentifier ?? UUID().uuidString,
            title: event.title ?? "Untitled",
            startDate: event.startDate,
            endDate: event.endDate,
            attendees: attendees,
            meetingURL: meetingURL,
            isAllDay: event.isAllDay,
            calendarColor: "#6366f1"
        )
    }

    /// Find the current or next meeting for auto-detection
    func currentOrNextMeeting() -> CalendarEvent? {
        let now = Date()
        // Check if we're in a meeting right now
        if let current = todayEvents.first(where: { $0.startDate <= now && $0.endDate >= now && !$0.isAllDay }) {
            return current
        }
        // Return next upcoming meeting within 5 minutes
        let fiveMinutes = now.addingTimeInterval(5 * 60)
        return todayEvents.first(where: { $0.startDate > now && $0.startDate <= fiveMinutes && !$0.isAllDay })
    }
}
