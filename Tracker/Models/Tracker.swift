import UIKit

// MARK: - Tracker

struct Tracker {
    let id: UUID
    let title: String
    let color: UIColor
    let emoji: String
    // если расписание пустое, это нерегулярное событие
    let schedule: [WeekDay]
    let isPinned: Bool

    init(id: UUID, title: String, color: UIColor, emoji: String, schedule: [WeekDay], isPinned: Bool = false) {
        self.id = id
        self.title = title
        self.color = color
        self.emoji = emoji
        self.schedule = schedule
        self.isPinned = isPinned
    }

    var isIrregular: Bool {
        schedule.isEmpty
    }
}
