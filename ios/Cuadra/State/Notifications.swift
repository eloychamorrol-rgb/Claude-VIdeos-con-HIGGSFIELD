import Foundation
import UserNotifications
import CuadraCore

/// Notificaciones locales: presupuestos al 80 % / 100 % y recordatorio de cobros recurrentes.
enum NotificationScheduler {
    private static let enabledKey = "notificationsEnabled"
    private static let sentKey = "sentBudgetAlerts"

    static var isEnabled: Bool { UserDefaults.standard.bool(forKey: enabledKey) }

    static func setEnabled(_ enabled: Bool) async -> Bool {
        guard enabled else {
            UserDefaults.standard.set(false, forKey: enabledKey)
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            return false
        }
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        UserDefaults.standard.set(granted, forKey: enabledKey)
        return granted
    }

    static func update(statuses: [BudgetStatus], upcoming: [RecurringCharge], categories: [String: String],
                       calendar: FinanceCalendar, now: Date = Date()) {
        guard isEnabled else { return }
        let center = UNUserNotificationCenter.current()
        let monthKey = "\(calendar.calendar.component(.year, from: now))-\(calendar.calendar.component(.month, from: now))"
        var sent = Set(UserDefaults.standard.stringArray(forKey: sentKey) ?? [])
        // Solo se conservan las alertas del mes en curso.
        sent = sent.filter { $0.hasSuffix(monthKey) }

        for status in statuses {
            let name = categories[status.budget.categoryId] ?? "una categoría"
            let level = status.progress >= 1 ? 100 : (status.progress >= 0.8 ? 80 : 0)
            guard level > 0 else { continue }
            let key = "\(status.budget.categoryId)-\(level)-\(monthKey)"
            guard !sent.contains(key) else { continue }
            sent.insert(key)
            let content = UNMutableNotificationContent()
            content.title = level == 100 ? "Superaste tu presupuesto" : "Vas en el 80 % de tu presupuesto"
            content.body = "\(name): \(MoneyFormat.clp(status.spent)) de \(MoneyFormat.clp(status.budget.monthlyLimit))."
            content.sound = .default
            center.add(UNNotificationRequest(identifier: "budget-\(key)", content: content, trigger: nil))
        }
        UserDefaults.standard.set(Array(sent), forKey: sentKey)

        // Recordatorio el día anterior a cada cobro esperado, a las 10:00.
        let billIds = upcoming.map { "bill-\($0.merchantKey)" }
        center.getPendingNotificationRequests { requests in
            let stale = requests.map(\.identifier).filter { $0.hasPrefix("bill-") && !billIds.contains($0) }
            center.removePendingNotificationRequests(withIdentifiers: stale)
        }
        for charge in upcoming {
            let reminderDay = calendar.adding(days: -1, to: charge.nextDate)
            var components = calendar.calendar.dateComponents([.year, .month, .day], from: reminderDay)
            components.hour = 10
            guard let fireDate = calendar.calendar.date(from: components), fireDate > now else { continue }
            let content = UNMutableNotificationContent()
            content.title = "Mañana se cobra \(charge.merchant)"
            content.body = "Cerca de \(MoneyFormat.clp(charge.typicalAmount)) (\(charge.cadence.title.lowercased()))."
            content.sound = .default
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            center.add(UNNotificationRequest(identifier: "bill-\(charge.merchantKey)", content: content, trigger: trigger))
        }
    }
}
