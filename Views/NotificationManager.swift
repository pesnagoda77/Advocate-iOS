import SwiftUI
import UserNotifications

// MARK: - Менеджер уведомлений

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification authorization error: \(error)")
            }
        }
    }
    
    func scheduleEventReminder(event: Event) {
        let content = UNMutableNotificationContent()
        content.title = "Advocate — Напоминание"
        content.body = "\(event.title) — \(event.date.formatted(date: .abbreviated, time: .shortened))"
        content.sound = .default
        
        // Напоминание за 15 минут
        let triggerDate = Calendar.current.date(byAdding: .minute, value: -15, to: event.date) ?? event.date
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "event_\(event.id)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func cancelEventReminder(eventId: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["event_\(eventId)"])
    }
    
    func scheduleDailySummary(cases: [Case], events: [Event]) {
        let content = UNMutableNotificationContent()
        content.title = "Advocate — Дела на сегодня"
        
        let activeCases = cases.filter { $0.status == .active }.count
        let todayEvents = events.filter { Calendar.current.isDate($0.date, inSameDayAs: Date()) }.count
        
        content.body = "Активных дел: \(activeCases), событий сегодня: \(todayEvents)"
        content.sound = .default
        
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "daily_summary",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule daily summary: \(error)")
            }
        }
    }
}
