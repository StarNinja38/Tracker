import UIKit

// MARK: - Tracker

struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    // если расписание пустое, это нерегулярное событие
    let schedule: [WeekDay]

    var isIrregular: Bool {
        schedule.isEmpty
    }
}
