import Foundation
import UserNotifications

// MARK: - ReminderScheduler (local notifications only)
//
// An ongoing daily practice needs a gentle door back. One soft daily reminder at an
// hour the user chooses — never marketing, never streak pressure. The content
// of notifications is generic; nothing user-written ever leaves the device,
// and scheduling is entirely opt-in.

@MainActor
struct ReminderScheduler {

    static let shared = ReminderScheduler()

    nonisolated static let dailyIdentifier = "com.kenatst.ember.daily"

    /// Requests permission and schedules the daily reminder.
    func enable(atHour hour: Int, minute: Int) async -> Bool {
        do {
            let granted = try await requestAuthorization()
            guard granted else { return false }

            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [Self.dailyIdentifier])

            var components = DateComponents()
            components.hour = hour
            components.minute = minute

            let content = UNMutableNotificationContent()
            content.title = String.ember("reminder.title")
            content.body = String.ember("reminder.body")
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: Self.dailyIdentifier,
                content: content,
                trigger: trigger
            )
            try await center.add(request)
            return true
        } catch {
            EmberLog.app.fault("Reminder authorization failed")
            return false
        }
    }

    func disable() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [Self.dailyIdentifier])
    }

    private func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .sound])
    }
}
