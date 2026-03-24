import UserNotifications
import Foundation

final class NotificationService {
    static let shared = NotificationService()

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            print("[Notifications] Permission \(granted ? "granted" : "denied")")
        } catch {
            print("[Notifications] Error: \(error)")
        }
    }

    /// Schedule a "meeting starting soon" notification
    func scheduleMeetingReminder(title: String, meetingURL: String?, startDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Meeting starting"
        content.body = title
        content.sound = .default
        if let url = meetingURL {
            content.userInfo = ["meetingURL": url]
        }

        // 1 minute before
        let triggerDate = startDate.addingTimeInterval(-60)
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "meeting-\(title.hashValue)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Notify that meeting processing is complete
    func notifyMeetingProcessed(title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Notes ready"
        content.body = "\(title) — Your meeting notes are ready to enhance"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "processed-\(title.hashValue)",
            content: content,
            trigger: nil // immediate
        )

        UNUserNotificationCenter.current().add(request)
    }
}
