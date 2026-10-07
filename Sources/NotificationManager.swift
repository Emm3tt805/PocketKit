import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    func requestPermission() {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    /// Fire a notification after a number of seconds.
    func schedule(id: String = UUID().uuidString, title: String, body: String, after seconds: TimeInterval) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        add(id: id, title: title, body: body, trigger: trigger)
    }

    /// Fire a notification at a specific date (optionally every day at that time).
    func schedule(id: String = UUID().uuidString, title: String, body: String, at date: Date, repeatsDaily: Bool) {
        let parts: Set<Calendar.Component> = repeatsDaily ? [.hour, .minute] : [.year, .month, .day, .hour, .minute]
        let comps = Calendar.current.dateComponents(parts, from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: repeatsDaily)
        add(id: id, title: title, body: body, trigger: trigger)
    }

    func cancel(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func pending() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    private func add(id: String, title: String, body: String, trigger: UNNotificationTrigger) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
