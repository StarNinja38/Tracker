import UIKit

// MARK: - Tracker

/// Привычка или нерегулярное событие.
/// Все поля `let` — структура иммутабельна, менять её нельзя, только создавать заново.
struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    /// Пустое расписание = нерегулярное событие (задача со звёздочкой).
    let schedule: [WeekDay]

    var isIrregular: Bool {
        schedule.isEmpty
    }
}
