import Foundation

// MARK: - TrackerFilter

enum TrackerFilter: CaseIterable {
    case all
    case today
    case completed
    case uncompleted

    var title: String {
        switch self {
        case .all: NSLocalizedString("filters.all", comment: "")
        case .today: NSLocalizedString("filters.today", comment: "")
        case .completed: NSLocalizedString("filters.completed", comment: "")
        case .uncompleted: NSLocalizedString("filters.uncompleted", comment: "")
        }
    }

    // все трекеры и трекеры на сегодня это сброс, а не фильтр
    var isActive: Bool {
        self == .completed || self == .uncompleted
    }
}
