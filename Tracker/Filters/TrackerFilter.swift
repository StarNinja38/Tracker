import Foundation

// MARK: - TrackerFilter

enum TrackerFilter: CaseIterable {
    case all
    case today
    case completed
    case uncompleted

    var title: String {
        switch self {
        case .all: "Все трекеры"
        case .today: "Трекеры на сегодня"
        case .completed: "Завершённые"
        case .uncompleted: "Незавершённые"
        }
    }

    // все трекеры и трекеры на сегодня это сброс, а не фильтр
    var isActive: Bool {
        self == .completed || self == .uncompleted
    }
}
